## Tests for the roller shutter in the hotel (slice.md, "The roller shutter"
## and "The shutter (E2, E3)"): its button before and after the power, the
## noise that brings E2 and E3, the corridor opening for the player and
## enemies, and loading it up.

extends "res://tests/levels/hotel_level_test.gd"

## Either side of the shutter, in the basement corridor and the staff corridor.
const CORRIDOR := Vector3(15, BASEMENT_Y, 0)
const STAFF_CORRIDOR := Vector3(24, BASEMENT_Y, 0)

## Where the player stands to press the button, facing it.
const AT_THE_BUTTON := Vector3(17.4, BASEMENT_Y + 0.1, 0.3)

var _shutter: RollerShutter
var _button: ShutterButton


func before_each() -> void:
	SaveSystem.reset()
	await super.before_each()
	_shutter = _level.get_node("Mechanisms/ShutterStaff") as RollerShutter
	_button = _level.get_node("Mechanisms/ShutterButton") as ShutterButton


func after_each() -> void:
	super.after_each()
	SaveSystem.reset()


func _player() -> Player:
	return _level.get_node("Player") as Player


func _enemy(enemy_name: String) -> Enemy:
	return _level.get_node("Enemies/" + enemy_name) as Enemy


## The player at the button, with the interaction focused on what is in front.
func _interaction_at_the_button() -> PlayerInteraction:
	var player: Player = _player()
	player.global_position = AT_THE_BUTTON
	player.rotation.y = PI
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	return interaction


## Whether a ray across the corridor at chest height hits the shutter.
func _is_corridor_blocked() -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(16.5, BASEMENT_Y + 1.2, 0), Vector3(19.5, BASEMENT_Y + 1.2, 0), CombatLayers.WORLD
	)
	return not _level.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _raise_and_wait() -> void:
	_shutter.raise_time = 0.3
	_shutter.raise()
	await wait_for_signal(_shutter.opened, 3.0)
	await get_tree().physics_frame
	await NavigationSync.wait_for_map_update(get_tree(), _map())


func test_the_shutter_and_its_button_are_wired() -> void:
	assert_not_null(_shutter)
	assert_not_null(_button)
	assert_eq(_shutter.get_persistent_id(), &"shutter_staff")
	assert_eq(_button.shutter, _shutter)
	assert_eq(_button.power_flag.flag_id, &"power_restored")
	assert_almost_eq(_shutter.raise_time, 3.0, 0.5, "about 3 s")
	assert_eq(_shutter.noise_radius, 12.0)
	assert_null(_level.get_node_or_null("Props/Basement/ShutterStaff"), "the shutter moved")
	var prop := _level.get_node("Props/Basement/ShutterButton") as Node3D
	assert_lt(_button.global_position.distance_to(prop.global_position), 0.5)


func test_the_shutter_starts_down_across_the_corridor() -> void:
	assert_false(_shutter.is_up)
	assert_true(_is_corridor_blocked())
	assert_gt(_path_length(CORRIDOR, CORRIDOR + Vector3(2, 0, 0)), 0.0, "corridor side")
	assert_eq(_path_length(CORRIDOR, STAFF_CORRIDOR), -1.0, "staff side")


func test_before_the_power_the_button_does_nothing_and_keeps_its_prompt() -> void:
	var interaction: PlayerInteraction = _interaction_at_the_button()
	assert_eq(interaction.focus, _button)
	assert_eq(_button.interact(_player()), "Nothing happens.")
	assert_false(_shutter.is_up)
	interaction.update_focus()
	assert_eq(interaction.focus, _button, "the prompt stays")
	assert_false(_enemy("EnemyStaffCorridor").is_chasing(), "no noise")
	assert_false(_enemy("EnemyStaffRoom").is_chasing(), "no noise")


func test_after_the_power_the_button_raises_the_shutter() -> void:
	(_level.get_node("LevelFlags/PowerRestored") as LevelFlag).set_flag()
	var interaction: PlayerInteraction = _interaction_at_the_button()
	assert_eq(interaction.focus, _button)
	interaction.interact()
	assert_true(_shutter.is_up)
	assert_eq(SaveSystem.world.get_state(&"shutter_staff"), {"is_up": true})
	interaction.update_focus()
	assert_ne(interaction.focus, _button, "no prompt once it's up")


func test_raising_it_brings_e2_and_e3() -> void:
	(_level.get_node("LevelFlags/PowerRestored") as LevelFlag).set_flag()
	_button.interact(_player())
	for enemy_name: String in ["EnemyStaffCorridor", "EnemyStaffRoom"]:
		var enemy: Enemy = _enemy(enemy_name)
		assert_true(enemy.is_chasing(), "%s heard it" % enemy_name)
		var heard_at: Vector3 = enemy.perception.last_known_position
		assert_lt(heard_at.distance_to(_shutter.global_position), 0.1, enemy_name)


func test_once_up_the_corridor_is_open_to_the_player_and_enemies() -> void:
	await _raise_and_wait()
	assert_false(_is_corridor_blocked(), "collision")
	assert_gt(_path_length(CORRIDOR, STAFF_CORRIDOR), 0.0, "navmesh")
	assert_gt(_path_length(STAFF_CORRIDOR, CORRIDOR), 0.0, "both ways")


func test_a_loaded_save_has_it_up_with_no_noise() -> void:
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.record(&"shutter_staff", {"is_up": true})
	SaveSystem.world.apply(_level)
	assert_true(_shutter.is_open, "up at once")
	assert_false(_button.is_in_group(Interactable.GROUP))
	assert_false(_enemy("EnemyStaffCorridor").is_chasing(), "no noise")
	assert_false(_enemy("EnemyStaffRoom").is_chasing(), "no noise")
	await get_tree().physics_frame
	await NavigationSync.wait_for_map_update(get_tree(), _map())
	assert_false(_is_corridor_blocked())
	assert_gt(_path_length(CORRIDOR, STAFF_CORRIDOR), 0.0)


func test_a_loaded_save_without_it_leaves_it_down() -> void:
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.apply(_level)
	assert_false(_shutter.is_up)
	assert_true(_button.is_in_group(Interactable.GROUP))
	assert_true(_is_corridor_blocked())
