## Integration tests on the graybox level: save, change the world, load, and
## compare. Loading also works from the main menu and the save spot's screen.

extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GRAYBOX_SCENE: PackedScene = preload("res://scenes/levels/graybox_level.tscn")
const PIPE: ItemData = preload("res://assets/data/items/steel_pipe.tres")
const DIRECTORY: String = "user://test_save_and_load"

var _main: Node
var _previous_slots: SaveSlots


func before_each() -> void:
	_previous_slots = SaveSystem.slots
	SaveSystem.slots = SaveSlots.new(DIRECTORY)
	_clear()
	# These run on the graybox level, which has a save spot and enemies.
	GameFlow.start_level_scene = GRAYBOX_SCENE
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	GameFlow.start_new_game()


func after_each() -> void:
	GameFlow.start_level_scene = load(GameFlow.START_LEVEL_PATH)
	_clear()
	DirAccess.remove_absolute(DIRECTORY)
	SaveSystem.slots = _previous_slots
	SaveSystem.reset()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _clear() -> void:
	for slot: int in SaveSlots.SLOT_COUNT:
		SaveSystem.slots.delete(slot)


func _level() -> Node:
	return _main.get_node("ScreenHost").get_child(0)


func _player() -> Player:
	return _level().get_node("Player") as Player


func _spot() -> SaveSpot:
	return _level().get_node("SaveSpots/SaveSpotLobby") as SaveSpot


func _pickup(node_name: String) -> Pickup:
	return _level().get_node("Pickups/" + node_name) as Pickup


func _door(node_name: String) -> Door:
	return _level().get_node("Doors/" + node_name) as Door


func _enemy(node_name: String) -> Enemy:
	return _level().get_node("Enemies/" + node_name) as Enemy


## Knocks `enemy` down at `position` and stomps it.
func _kill(enemy: Enemy, position: Vector3) -> void:
	enemy.global_position = position
	enemy.brain.knock_down(10.0)
	enemy.stomp()


## Changes the world and the player, then saves to slot 0.
func _play_and_save() -> SaveData:
	var player: Player = _player()
	_pickup("PistolAmmoRoomA").interact(player)
	_door("DoorRoomB").unlock()
	_kill(_enemy("EnemyYard"), Vector3(-18.0, 0.0, -3.0))
	player.health_component.take_damage(40.0)
	player.inventory.add(PIPE)
	player.items.equip(PIPE)
	player.flashlight.set_on(false)
	SaveSystem.play_time = 300.0
	var save: SaveData = SaveSystem.capture(player, _spot())
	assert_eq(SaveSystem.write_slot(0, save), OK)
	return save


## Changes everything again after the save.
func _play_on() -> void:
	var player: Player = _player()
	_pickup("PistolAmmoOffice").interact(player)
	_door("DoorStorageEast").unlock()
	_kill(_enemy("EnemyOffice"), Vector3(1.0, 0.0, -6.0))
	player.health_component.take_damage(30.0)
	player.inventory.add(PIPE, 2)
	player.flashlight.set_on(true)
	player.global_position = Vector3(0.0, 0.1, 20.0)
	SaveSystem.play_time = 500.0


func test_loading_brings_back_the_player_as_saved() -> void:
	var save: SaveData = _play_and_save()
	_play_on()
	var old_level: Node = _level()
	GameFlow.load_game(SaveSystem.slots.read(0))
	assert_ne(_level(), old_level)
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	var player: Player = _player()
	assert_eq(player.health_component.current_health, 60.0)
	assert_eq(player.inventory.to_dict(), save.inventory)
	assert_eq(player.inventory.count(PIPE), 1)
	assert_eq(player.items.equipped_weapon, PIPE)
	assert_false(player.is_lit())
	assert_eq(SaveSystem.play_time, 300.0)


func test_the_player_appears_at_the_save_spot() -> void:
	_play_and_save()
	_play_on()
	GameFlow.load_game(SaveSystem.slots.read(0))
	var player: Player = _player()
	var spawn: Node3D = _spot().spawn_point
	assert_almost_eq(player.global_position, spawn.global_position, Vector3.ONE * 0.01)
	assert_almost_eq(player.rotation.y, spawn.global_rotation.y, 0.01)
	assert_almost_eq(
		player.camera_controller.global_position, player.global_position, Vector3.ONE * 0.01
	)


func test_loading_brings_back_pickups_and_doors_as_saved() -> void:
	_play_and_save()
	_play_on()
	GameFlow.load_game(SaveSystem.slots.read(0))
	assert_true(_pickup("PistolAmmoRoomA").is_collected)
	assert_false(_pickup("PistolAmmoOffice").is_collected)
	assert_false(_door("DoorRoomB").is_locked)
	assert_true(_door("DoorStorageEast").is_locked)
	await get_tree().process_frame
	assert_null(_level().get_node_or_null("Pickups/PistolAmmoRoomA"))


func test_dead_enemies_are_corpses_where_they_fell() -> void:
	_play_and_save()
	_play_on()
	GameFlow.load_game(SaveSystem.slots.read(0))
	var corpse: Enemy = _enemy("EnemyYard")
	assert_true(corpse.is_dead())
	assert_almost_eq(corpse.global_position, Vector3(-18.0, 0.0, -3.0), Vector3.ONE * 0.01)
	assert_almost_eq(corpse.rotation_degrees.x, -90.0, 0.01)
	assert_false(corpse.is_in_group(Enemy.ENEMY_GROUP))
	await get_tree().physics_frame
	assert_true(corpse.is_dead())


func test_living_enemies_are_back_where_placed_with_full_health() -> void:
	# Nothing has moved yet in the fresh level.
	var placed: Vector3 = _enemy("EnemyOffice").global_position
	_play_and_save()
	_play_on()
	GameFlow.load_game(SaveSystem.slots.read(0))
	var enemy: Enemy = _enemy("EnemyOffice")
	assert_false(enemy.is_dead())
	assert_almost_eq(enemy.global_position, placed, Vector3.ONE * 0.01)
	assert_eq(enemy.health_component.current_health, enemy.health_component.max_health)


func test_the_world_after_loading_is_the_saves() -> void:
	var save: SaveData = _play_and_save()
	_play_on()
	GameFlow.load_game(SaveSystem.slots.read(0))
	assert_eq(SaveSystem.world.to_dict(), save.world.to_dict())


func test_a_save_can_be_loaded_again_after_playing_on() -> void:
	_play_and_save()
	var save: SaveData = SaveSystem.slots.read(0)
	GameFlow.load_game(save)
	_play_on()
	GameFlow.load_game(save)
	assert_false(_pickup("PistolAmmoOffice").is_collected)
	assert_true(_door("DoorStorageEast").is_locked)
	assert_false(_enemy("EnemyOffice").is_dead())
	assert_eq(_player().health_component.current_health, 60.0)


func test_loading_from_the_main_menu() -> void:
	_play_and_save()
	GameFlow.go_to_title()
	var menu := _level() as MainMenu
	menu.load_button.pressed.emit()
	menu.save_screen.get_slot_button(0).pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	assert_eq(_player().health_component.current_health, 60.0)
	assert_true(_pickup("PistolAmmoRoomA").is_collected)


func test_loading_from_the_save_spot_screen() -> void:
	_play_and_save()
	_play_on()
	var player: Player = _player()
	_spot().interact(player)
	assert_true(get_tree().paused)
	player.save_screen.switch_mode()
	player.save_screen.get_slot_button(0).pressed.emit()
	assert_false(get_tree().paused)
	assert_eq(_player().health_component.current_health, 60.0)
	assert_false(_pickup("PistolAmmoOffice").is_collected)


func test_a_save_with_a_missing_level_loads_nothing() -> void:
	var level: Node = _level()
	var save := SaveData.new()
	save.level_path = "res://scenes/levels/no_such_level.tscn"
	GameFlow.load_game(save)
	assert_eq(_level(), level)
