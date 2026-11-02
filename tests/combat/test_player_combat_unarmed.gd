## Scene-level tests of an unarmed player: `attack` does nothing (gameplay.md)
## until a weapon is equipped.

extends CombatSceneTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PIPE_ITEM: ItemData = preload("res://assets/data/items/steel_pipe.tres")


func _starting_weapon() -> ItemData:
	return null


func test_starts_without_a_weapon() -> void:
	assert_null(_combat.weapon)
	assert_false(_combat.has_weapon())
	assert_null(_player.items.equipped_weapon)


func test_a_tap_does_nothing() -> void:
	watch_signals(_combat)
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_signal_not_emitted(_combat, "swing_started")
	assert_false(_player.is_movement_locked)
	assert_eq(_stamina.current_stamina, _stamina.max_stamina)
	await _seconds(0.6)
	assert_eq(_dummy.health_component.current_health, _dummy.health_component.max_health)


func test_holding_does_not_charge() -> void:
	_combat.attack_pressed()
	await _seconds(1.2)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	_combat.attack_released()
	await _physics_frames(1)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_eq(_stamina.current_stamina, _stamina.max_stamina)


func test_no_stomp_either() -> void:
	_dummy.position = Vector3(20.0, 0.0, 0.0)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = Vector3(0.0, 0.0, -1.0)
	enemy.downed_variation = 0.0
	enemy.downed_duration = 30.0
	add_child_autofree(enemy)
	await _physics_frames(2)
	enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _physics_frames(2)
	assert_eq(_combat.find_stompable_enemy(), enemy, "the enemy is down and in range")
	_combat.attack_pressed()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)


func test_a_weapon_equipped_later_swings() -> void:
	_player.inventory.add(PLANK_ITEM)
	assert_true(_player.items.equip(PLANK_ITEM))
	assert_eq(_combat.weapon, PLANK_ITEM.weapon)
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.SWING_LIGHT)
	await _seconds(0.6)
	assert_eq(_dummy.health_component.current_health, 92.0)


func test_equipping_sets_the_weapons_reach() -> void:
	_player.inventory.add(PIPE_ITEM)
	_player.items.equip(PIPE_ITEM)
	var shape := _combat.hitbox.get_child(0) as CollisionShape3D
	assert_almost_eq((shape.shape as BoxShape3D).size.z, PIPE_ITEM.weapon.reach, 0.001)
