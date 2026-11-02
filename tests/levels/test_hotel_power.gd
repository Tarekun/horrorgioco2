## Tests for the power in the hotel (slice.md, "The power"): the boiler room's
## switchboard, the `power_restored` flag, the boiler room lights and E1, live
## and loaded from a save.

extends "res://tests/levels/hotel_level_test.gd"

var _switchboard: Switchboard
var _lights: Node3D
var _enemy: Enemy


func before_each() -> void:
	SaveSystem.reset()
	await super.before_each()
	_switchboard = _level.get_node("Mechanisms/SwitchboardBasement") as Switchboard
	_lights = _level.get_node("Lights/Basement/BoilerRoom") as Node3D
	_enemy = _level.get_node("Enemies/EnemyBoilerRoom") as Enemy


func after_each() -> void:
	super.after_each()
	SaveSystem.reset()


func _player() -> Player:
	return _level.get_node("Player") as Player


func test_the_switchboard_is_wired_to_the_power() -> void:
	assert_not_null(_switchboard)
	assert_eq(_switchboard.power_flag.flag_id, &"power_restored")
	assert_eq(_switchboard.lights, _lights)
	assert_eq(_switchboard.enemy.enemy_id, &"enemy_boiler_room")
	assert_not_null(_switchboard.machinery_sound)
	var prop := _level.get_node("Props/Basement/SwitchboardBasement") as Node3D
	assert_lt(_switchboard.global_position.distance_to(prop.global_position), 1.0)


func test_the_power_starts_off() -> void:
	assert_false(_switchboard.is_thrown())
	assert_false(_lights.visible)
	assert_true(_enemy.is_dormant)


func test_the_player_throws_it_standing_at_the_switchboard() -> void:
	var player: Player = _player()
	player.global_position = Vector3(14.5, BASEMENT_Y + 0.1, -5.9)
	player.rotation.y = 0.0
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, _switchboard)
	assert_eq(interaction.focus.get_prompt(), "Throw the main switch.")
	interaction.interact()
	assert_true(_switchboard.is_thrown())
	assert_eq(SaveSystem.world.get_state(&"power_restored"), {"is_set": true})


func test_throwing_it_lights_the_boiler_room_and_wakes_e1() -> void:
	var player: Player = _player()
	player.global_position = Vector3(14.5, BASEMENT_Y + 0.1, -5.9)
	_switchboard.interact(player)
	await wait_for_signal(_switchboard.lights_settled, _switchboard.get_stutter_duration() + 2.0)
	assert_true(_lights.visible)
	assert_false(_enemy.is_dormant)
	assert_true(_enemy.is_chasing(), "already alerted to Luca")
	var distance: float = _enemy.global_position.distance_to(player.global_position)
	assert_almost_eq(distance, 4.0, 1.0, "about 4 m away")


func test_a_loaded_power_has_the_lights_on_and_e1_awake_where_placed() -> void:
	var placed: Vector3 = _enemy.global_position
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.apply(_level)
	assert_true(_switchboard.is_thrown())
	assert_false(_switchboard.is_in_group(Interactable.GROUP))
	assert_true(_lights.visible)
	assert_false(_enemy.is_dormant)
	assert_false(_enemy.is_chasing())
	assert_eq(_enemy.global_position, placed)


func test_a_loaded_power_leaves_a_dead_e1_a_corpse() -> void:
	var corpse := Vector3(16.5, BASEMENT_Y, -2.0)
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.record(
		&"enemy_boiler_room",
		{"is_dead": true, "position": WorldState.encode_vector(corpse), "rotation": [0, 0, 0]}
	)
	SaveSystem.world.apply(_level)
	await get_tree().physics_frame
	assert_true(_enemy.is_dead())
	assert_false(_enemy.is_chasing())
	assert_almost_eq(_enemy.global_position.x, corpse.x, 0.1)
