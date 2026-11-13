## The player's firearm: holds the currently equipped Firearm, its magazine
## and the steadiness behind the hit rolls, and fires while aiming.
##
## A shot rolls the HitChance of the held firearm against the locked target
## of the LockOnAim. A hit damages the target; a miss strikes the
## environment near the target (a spark) and never the target itself. With
## no locked target the shot strikes whatever the camera-forward ray meets.
## Every shot makes the firearm's noise event.
##
## The magazine and the reserve (the ammo item in the inventory) are tracked
## separately. Reloading is the fixed reload_time of the firearm: press
## `reload`, or try to fire with an empty magazine while reserve remains.
## While aiming, the magazine count is shown on the AmmoCounter; nothing is
## shown when not aiming.
##
## The hit rolls use `rng`, left to randomise in _ready or set (seeded) by a
## caller for deterministic tests. Time-sensitive parts run in tick(), so
## tests drive them directly.

class_name PlayerFirearm
extends Node

## Emitted after a shot, with whether it hit.
signal shot_fired(hit: bool)
## Emitted when a reload finishes, with the rounds loaded.
signal reload_finished(rounds_loaded: int)

## A missed shot strikes the target plus a random horizontal offset of at
## most this (metres): near the target, never on it.
const MISS_OFFSET: float = 0.5

## How far a shot with no locked target travels before it is deemed to hit
## nothing (metres).
const MAX_TRAVEL: float = 10.0

## The player that carries the reserve ammo and is the shot's attacker.
@export var player: Player
## The lock-on the shots aim with.
@export var aim: LockOnAim
## The magazine count shown while aiming.
@export var ammo_counter: AmmoCounter
## The generator of the hit rolls; unset gets a randomised one in _ready.
## Not exported: RandomNumberGenerator is not a resource. Tests set it
## (seeded) or replace it through set_rng().
var rng: RandomNumberGenerator

## The firearm held, or null.
var current: Firearm = null
## Rounds left in the magazine; writing keeps the per-item memory in sync.
var magazine: int = 0:
	get:
		return _magazine
	set(value):
		_magazine = value
		if _current_item_id != &"":
			_magazines[_current_item_id] = value

## True while a reload runs.
var is_reloading: bool = false

var hit_chance: HitChance
var _cooldown: float = 0.0
var _reload_left: float = 0.0
## Magazine contents per weapon item id, so re-equipping keeps the rounds.
var _magazines: Dictionary[StringName, int] = {}
var _current_item_id: StringName = &""
var _magazine: int = 0


func _ready() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	hit_chance = HitChance.new(rng)
	if aim:
		aim.aim_started.connect(_on_aim_started)
		aim.aim_ended.connect(_on_aim_ended)
		aim.target_changed.connect(_on_target_changed)


## Replaces the hit-roll generator and rebuilds the HitChance around it
## (the tests use it to seed deterministic rolls).
func set_rng(rng: RandomNumberGenerator) -> void:
	self.rng = rng
	hit_chance = HitChance.new(rng)


func _physics_process(delta: float) -> void:
	tick(delta)
	if Input.is_action_just_pressed(&"attack"):
		try_fire()
	if Input.is_action_just_pressed(&"reload"):
		start_reload()


## Advances the steadiness while aiming, the fire cooldown and the reload;
## finishes the reload in time.
func tick(delta: float) -> void:
	if aim != null and aim.is_aiming:
		hit_chance.update(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
	if is_reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()


## Holds the firearm of `item` from now on (called when the item is
## equipped). An item without a firearm, or re-equipping the same one,
## leaves the held firearm untouched in the second case; a different item
## or none clears it.
func set_item(item: ItemData) -> void:
	if item == null or item.firearm == null:
		_clear()
		return
	if current == item.firearm and _current_item_id == item.id:
		return
	_cancel_reload()
	current = item.firearm
	_current_item_id = item.id
	var stored: int = _magazines.get(item.id, -1)
	magazine = current.magazine_size if stored < 0 else stored
	current.apply_to(hit_chance)
	_update_counter()


## The reserve rounds of the held firearm in the inventory.
func reserve() -> int:
	if current == null or current.ammo_item == null or player == null:
		return 0
	return player.inventory.count(current.ammo_item)


## Fires one shot when it can. With an empty magazine and reserve left,
## starts the reload instead (the spec's firing-empty trigger); with no
## reserve, nothing happens.
func try_fire() -> void:
	if current == null or aim == null or not aim.is_aiming or is_reloading:
		return
	if _cooldown > 0.0 or magazine <= 0:
		if magazine <= 0 and reserve() > 0:
			start_reload()
		return
	magazine -= 1
	_cooldown = current.shot_interval
	_fire_shot()
	_update_counter()


## Starts a reload: only with a held firearm, a short magazine and reserve
## left. The pistol's reload is a fixed time; it can be cut short only by
## putting the firearm away.
func start_reload() -> void:
	if current == null or is_reloading:
		return
	if magazine >= current.magazine_size or reserve() <= 0:
		return
	is_reloading = true
	_reload_left = current.reload_time


## The item id of the firearm held, or empty when none is held.
func held_item_id() -> StringName:
	return _current_item_id


## The magazine this session has stored for the weapon item `item_id`, or
## -1 when it has never been held.
func magazine_for(item_id: StringName) -> int:
	return _magazines.get(item_id, -1)


## Restores a saved magazine for the weapon item `item_id`; -1 leaves it.
func restore_magazine(item_id: StringName, count: int) -> void:
	if count >= 0:
		_magazines[item_id] = count


## Where a missed shot strikes: the target plus a random horizontal offset
## of at most MISS_OFFSET metres, so the spark reads as near the target,
## never on it.
static func miss_impact_point(target_position: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var angle: float = rng.randf() * TAU
	var radius: float = rng.randf() * MISS_OFFSET
	return target_position + Vector3(cos(angle), 0.0, sin(angle)) * radius


## Fires one loaded round: rolls the held firearm's chance at the locked
## target, or strikes the environment along the camera forward with none,
## and makes the shot's noise event.
func _fire_shot() -> void:
	var hit: bool = false
	var target: Node3D = aim.locked_target
	if target != null:
		var distance: float = _camera_position().distance_to(target.global_position)
		hit = hit_chance.fire(
			distance,
			_player_is_moving(),
			_target_is_moving(target),
			_target_is_impaired(target),
			_player_in_danger(),
			_player_is_exhausted()
		)
		if hit:
			_damage_target(target)
		else:
			_spawn_impact(miss_impact_point(target.global_position, rng))
	else:
		_spawn_impact(_first_world_hit(_camera_position(), aim.get_aim_direction()))
	NoiseEvent.emit_noise(get_tree(), _player_position(), current.noise_radius)
	shot_fired.emit(hit)


## Loads reserve rounds into the magazine and reports them.
func _finish_reload() -> void:
	is_reloading = false
	var take: int = mini(current.magazine_size - magazine, reserve())
	magazine += take
	if take > 0:
		player.inventory.remove(current.ammo_item, take)
	_update_counter()
	reload_finished.emit(take)


## Damages the target's health, found among its children.
func _damage_target(target: Node3D) -> void:
	var health := _find_health(target)
	if health != null and player != null:
		health.take_damage(current.damage, player)


func _find_health(target: Node3D) -> HealthComponent:
	for child: Node in target.get_children():
		var health := child as HealthComponent
		if health != null:
			return health
	return null


## Spawns the one-shot spark at `point` and lets it free itself when done.
func _spawn_impact(point: Vector3) -> void:
	var spark := CPUParticles3D.new()
	spark.emitting = false
	spark.one_shot = true
	spark.explosiveness = 1.0
	spark.amount = 12
	spark.lifetime = 0.3
	spark.spread = 90.0
	spark.initial_velocity_min = 1.0
	spark.initial_velocity_max = 2.5
	spark.gravity = Vector3(0, -4, 0)
	spark.scale_amount_min = 0.05
	spark.scale_amount_max = 0.05
	spark.color = Color(1.0, 0.75, 0.3)
	spark.finished.connect(spark.queue_free)
	get_tree().root.add_child(spark)
	spark.global_position = point
	spark.emitting = true


## The first point the ray from `origin` along `direction` meets on the
## world layers, or `MAX_TRAVEL` out when it meets nothing.
func _first_world_hit(origin: Vector3, direction: Vector3) -> Vector3:
	if aim == null or aim.camera == null or direction.is_zero_approx():
		return origin
	var end: Vector3 = origin + direction.normalized() * MAX_TRAVEL
	var query := PhysicsRayQueryParameters3D.create(origin, end, CombatLayers.WORLD)
	var result: Dictionary = aim.camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("position"):
		return result.position
	return end


func _player_is_moving() -> bool:
	if player == null:
		return false
	return Vector2(player.velocity.x, player.velocity.z).length() > 0.05


func _target_is_moving(target: Node3D) -> bool:
	var velocity: Variant = target.get("velocity")
	if velocity is Vector3:
		return Vector2((velocity as Vector3).x, (velocity as Vector3).z).length() > 0.05
	return false


func _target_is_impaired(target: Node3D) -> bool:
	var is_downed: bool = false
	if target.has_method(&"is_downed"):
		is_downed = bool(target.call(&"is_downed"))
	return is_downed or target.get("is_staggered") == true


func _player_in_danger() -> bool:
	if player == null or player.health_component == null:
		return false
	return (
		HealthState.from_health(player.health_component.current_health) == HealthState.State.DANGER
	)


func _player_is_exhausted() -> bool:
	return (
		player != null
		and player.stamina_component != null
		and player.stamina_component.is_exhausted
	)


func _camera_position() -> Vector3:
	if aim == null or aim.camera == null:
		return Vector3.ZERO
	return aim.camera.global_position


func _player_position() -> Vector3:
	return player.global_position if player != null else Vector3.ZERO


func _cancel_reload() -> void:
	is_reloading = false
	_reload_left = 0.0


func _clear() -> void:
	_cancel_reload()
	current = null
	_current_item_id = &""
	magazine = 0
	_update_counter()


## Shows the magazine count while aiming, hides it otherwise.
func _update_counter() -> void:
	if ammo_counter == null:
		return
	if aim != null and aim.is_aiming and current != null:
		ammo_counter.show_count(magazine, reserve())
	else:
		ammo_counter.hide_count()


func _on_aim_started() -> void:
	_update_counter()


func _on_aim_ended() -> void:
	_update_counter()


func _on_target_changed(target: Node3D) -> void:
	if target != null:
		hit_chance.acquire_target()
