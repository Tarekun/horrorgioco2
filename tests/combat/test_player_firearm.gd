## Tests of the PlayerFirearm: firing the held firearm while aiming rolls
## the hit chance against the locked target (a hit damages, a miss strikes
## near the target), the magazine and reserve are tracked separately, the
## fire rate and reloads are timed, every shot makes its noise, and the
## magazine count shows only while aiming.
##
## Time is driven by tick(), never slept. The hit rolls use pinned seeds,
## so every outcome is deterministic.

extends GutTest

const TEST_GROUP: StringName = &"player_firearm_test_enemies"
const PISTOL_ITEM_PATH: String = "res://assets/data/items/pistol.tres"
const PLANK_ITEM_PATH: String = "res://assets/data/items/wooden_plank.tres"

## Seed whose first draw (0.1071, pinned in test_hit_chance.gd) is under the
## pistol's first-shot chance at 5 m (about 0.65), so the first rolls hit.
const SEED_HIT: int = 1234

## First four randf() draws of a RandomNumberGenerator seeded with
## SEED_MISS. The first is over the 0.95 clamp, so the first roll always
## misses. If the engine's sequence ever changes, the pin test below fails
## so the expected misses get re-checked.
const SEED_MISS: int = 99
const SEED_99: Array[float] = [
	0.99653178453445,
	0.46799251437187,
	0.40918126702309,
	0.31048908829689,
]


## A listener in the hearing group, recording the last noise radius.
class _Ear:
	extends Node
	var last_radius: float = -1.0

	func hear_noise(_position: Vector3, radius: float) -> void:
		last_radius = radius


var _camera: Camera3D
var _scanner: LockOnScanner
var _aim: LockOnAim
var _counter: AmmoCounter
var _player: Player
var _firearm: PlayerFirearm
var _ear: _Ear


func before_each() -> void:
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_scanner = LockOnScanner.new()
	_scanner.enemy_group = TEST_GROUP
	add_child_autofree(_scanner)
	_aim = LockOnAim.new()
	_aim.scanner = _scanner
	_aim.camera = _camera
	add_child_autofree(_aim)
	_counter = load("res://scenes/ui/ammo_counter.tscn").instantiate()
	add_child_autofree(_counter)
	_player = Player.new()
	var health := HealthComponent.new()
	_player.add_child(health)
	_player.health_component = health
	var stamina := StaminaComponent.new()
	_player.add_child(stamina)
	_player.stamina_component = stamina
	add_child_autofree(_player)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_HIT
	_firearm = PlayerFirearm.new()
	_firearm.player = _player
	_firearm.aim = _aim
	_firearm.ammo_counter = _counter
	_firearm.rng = rng
	add_child_autofree(_firearm)
	_ear = _Ear.new()
	add_child_autofree(_ear)
	_ear.add_to_group(&"hearing")
	_player.inventory = Inventory.new()
	watch_signals(_firearm)
	await _frames(2)


func after_each() -> void:
	Input.action_release(&"attack")
	Input.action_release(&"reload")
	Input.action_release(&"aim")


## Gives the player reserve pistol rounds and holds the pistol.
func _equip_pistol(reserve: int) -> void:
	var item := load(PISTOL_ITEM_PATH) as ItemData
	if reserve > 0:
		_player.inventory.add(item.firearm.ammo_item, reserve)
	_firearm.set_item(item)


## Spawns a plain Node3D enemy with a HealthComponent child, `angle_deg`
## degrees to the right of the camera forward, `distance` metres away.
func _add_enemy(angle_deg: float, distance: float) -> Node3D:
	var enemy := Node3D.new()
	var angle: float = deg_to_rad(angle_deg)
	enemy.position = Vector3(sin(angle), 0.0, -cos(angle)) * distance
	add_child_autofree(enemy)
	var health := HealthComponent.new()
	enemy.add_child(health)
	enemy.add_to_group(TEST_GROUP)
	return enemy


func _health_of(enemy: Node3D) -> HealthComponent:
	return enemy.get_child(0) as HealthComponent


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


# --- Firing ---


func test_a_hit_damages_the_target_spends_ammo_and_makes_noise() -> void:
	_equip_pistol(24)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	_firearm.try_fire()
	assert_eq(_health_of(enemy).current_health, 80.0, "a hit does the firearm's damage")
	assert_eq(_firearm.magazine, 9)
	assert_eq(_ear.last_radius, 25.0, "every shot makes the pistol's noise")
	_aim.stop_aiming()


func test_a_miss_deals_no_damage_but_spends_ammo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_MISS
	_firearm.set_rng(rng)
	_equip_pistol(24)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	_firearm.try_fire()
	assert_eq(_health_of(enemy).current_health, 100.0, "a miss never hits the target")
	assert_eq(_firearm.magazine, 9)
	assert_signal_emitted_with_parameters(_firearm, "shot_fired", [false])
	_aim.stop_aiming()


func test_the_fire_rate_limits_the_shots() -> void:
	_equip_pistol(24)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	_firearm.try_fire()
	_firearm.tick(0.2)
	_firearm.try_fire()
	assert_eq(_firearm.magazine, 9, "no second shot inside the shot interval")
	_firearm.tick(0.2)
	_firearm.try_fire()
	assert_eq(_firearm.magazine, 8, "the second shot goes off after the interval")
	_aim.stop_aiming()


func test_firing_without_a_lock_strikes_the_environment() -> void:
	_equip_pistol(24)
	_aim.start_aiming()
	await _frames(2)
	assert_null(_aim.locked_target)
	_firearm.try_fire()
	assert_eq(_firearm.magazine, 9)
	assert_signal_emitted_with_parameters(_firearm, "shot_fired", [false])
	_aim.stop_aiming()


# --- Reloading ---


func test_firing_empty_with_reserve_starts_the_reload() -> void:
	_equip_pistol(8)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	_firearm.magazine = 0
	_firearm.try_fire()
	assert_true(_firearm.is_reloading, "firing empty with reserve reloads")
	_firearm.tick(1.4)
	assert_false(_firearm.is_reloading)
	assert_eq(_firearm.magazine, 8, "the reserve rounds are loaded")
	assert_eq(_player.inventory.count(_firearm.current.ammo_item), 0, "the reserve pays")
	_aim.stop_aiming()


func test_a_partial_reload_loads_only_the_reserve() -> void:
	_equip_pistol(3)
	_firearm.magazine = 7
	_firearm.start_reload()
	assert_true(_firearm.is_reloading)
	_firearm.tick(1.4)
	assert_eq(_firearm.magazine, 10)
	assert_eq(_player.inventory.count(_firearm.current.ammo_item), 0)


func test_start_reload_respects_a_full_magazine_and_empty_reserve() -> void:
	_equip_pistol(24)
	_firearm.start_reload()
	assert_false(_firearm.is_reloading, "a full magazine does not reload")
	_firearm.magazine = 0
	_player.inventory.clear()
	_firearm.start_reload()
	assert_false(_firearm.is_reloading, "no reserve, no reload")


# --- The magazine across equips and steadiness ---


func test_re_equipping_keeps_the_magazine() -> void:
	_equip_pistol(24)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	_firearm.try_fire()
	_firearm.tick(0.35)
	_firearm.try_fire()
	assert_eq(_firearm.magazine, 8)
	var plank := load(PLANK_ITEM_PATH) as ItemData
	_firearm.set_item(plank)
	assert_null(_firearm.current, "the melee item puts the firearm away")
	_firearm.set_item(load(PISTOL_ITEM_PATH) as ItemData)
	assert_eq(_firearm.magazine, 8, "re-equipping keeps the spent magazine")
	_aim.stop_aiming()


func test_switching_targets_resets_the_steadiness() -> void:
	_equip_pistol(24)
	var left := _add_enemy(-30.0, 5.0)
	var right := _add_enemy(30.0, 6.0)
	await _frames(2)
	_aim.start_aiming()
	await _frames(2)
	assert_eq(_aim.locked_target, left)
	_firearm.tick(1.0)
	assert_eq(_firearm.hit_chance.steadiness, 1.0, "holding the aim steadies it")
	_aim.cycle_target()
	assert_eq(_aim.locked_target, right)
	assert_eq(_firearm.hit_chance.steadiness, 0.75, "the switch re-acquires")
	_aim.stop_aiming()


# --- The magazine count ---


func test_the_pinned_miss_seed_draws_match_the_engine() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_MISS
	var draws: Array[float] = []
	for i: int in SEED_99.size():
		draws.append(rng.randf())
	for i: int in SEED_99.size():
		assert_true(
			absf(draws[i] - SEED_99[i]) < 1e-9,
			"draw %d of seed %d changed: %s" % [i, SEED_MISS, str(draws[i])]
		)


func test_the_count_shows_only_while_aiming() -> void:
	_equip_pistol(24)
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	assert_false(_counter.shows_count, "nothing is shown when not aiming")
	_aim.start_aiming()
	await _frames(2)
	assert_true(_counter.shows_count)
	assert_eq(_counter._label.text, "10 / 24")
	_firearm.try_fire()
	assert_eq(_counter._label.text, "9 / 24")
	_aim.stop_aiming()
	assert_false(_counter.shows_count)
