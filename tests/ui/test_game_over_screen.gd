## Tests for the game over options on the graybox level: Load last save, Load
## game… and Quit to title.

extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GRAYBOX_SCENE: PackedScene = preload("res://scenes/levels/graybox_level.tscn")
const DIRECTORY: String = "user://test_game_over_screen"

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


func _screen() -> GameOverScreen:
	return _player().get_node("GameOverScreen") as GameOverScreen


## Saves at the lobby spot with `health` left, in `slot`.
func _save_with_health(health: float, slot: int) -> SaveData:
	var player: Player = _player()
	player.health_component.revive(health)
	var spot := _level().get_node("SaveSpots/SaveSpotLobby") as SaveSpot
	var save: SaveData = SaveSystem.capture(player, spot)
	SaveSystem.write_slot(slot, save)
	return save


## Kills the player and brings up the game over screen.
func _die() -> GameOverScreen:
	_player().health_component.take_damage(1000.0)
	var screen: GameOverScreen = _screen()
	screen.show_screen()
	return screen


func test_offers_the_three_options() -> void:
	var screen: GameOverScreen = _screen()
	assert_eq(screen.load_last_button.text, "Load last save")
	assert_eq(screen.load_game_button.text, "Load game…")
	assert_eq(screen.quit_button.text, "Quit to title")


func test_showing_pauses_and_focuses_load_last_save() -> void:
	var screen: GameOverScreen = _die()
	assert_true(screen.is_showing)
	assert_true(screen.panel.visible)
	assert_true(get_tree().paused)
	assert_eq(GameFlow.state, GameFlow.State.GAME_OVER)
	assert_true(screen.load_last_button.has_focus())


func test_load_last_save_without_a_save_starts_over() -> void:
	var old_level: Node = _level()
	SaveSystem.world.record(&"Pickups/PistolAmmoRoomA", {"is_collected": true})
	_die().load_last_button.pressed.emit()
	assert_ne(_level(), old_level)
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	assert_false(get_tree().paused)
	assert_eq(_player().health_component.current_health, _player().health_component.max_health)
	assert_true(SaveSystem.world.is_empty())


func test_load_last_save_loads_the_last_save_written() -> void:
	_save_with_health(80.0, 0)
	_save_with_health(55.0, 1)
	_die().load_last_button.pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	assert_false(get_tree().paused)
	assert_eq(_player().health_component.current_health, 55.0)


func test_a_save_loaded_since_counts_as_the_last() -> void:
	_save_with_health(80.0, 0)
	_save_with_health(55.0, 1)
	GameFlow.load_game(SaveSystem.slots.read(0))
	_die().load_last_button.pressed.emit()
	assert_eq(_player().health_component.current_health, 80.0)


func test_load_game_opens_the_slot_screen_over_it() -> void:
	_save_with_health(70.0, 3)
	var screen: GameOverScreen = _die()
	screen.load_game_button.pressed.emit()
	assert_true(screen.save_screen.is_open)
	assert_eq(screen.save_screen.mode, SaveScreen.Mode.LOAD)
	assert_true(screen.save_screen.get_slot_button(3).has_focus())
	assert_true(get_tree().paused)


func test_backing_out_of_the_slot_screen_returns_to_the_options() -> void:
	var screen: GameOverScreen = _die()
	screen.load_game_button.pressed.emit()
	screen.save_screen.close()
	assert_true(screen.is_showing)
	assert_true(get_tree().paused)
	assert_true(screen.load_game_button.has_focus())


func test_the_save_picked_is_loaded() -> void:
	_save_with_health(70.0, 3)
	_save_with_health(40.0, 4)
	var screen: GameOverScreen = _die()
	screen.load_game_button.pressed.emit()
	screen.save_screen.get_slot_button(3).pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	assert_false(get_tree().paused)
	assert_eq(_player().health_component.current_health, 70.0)


func test_quit_to_title_returns_to_the_main_menu() -> void:
	_die().quit_button.pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.TITLE)
	assert_true(_level() is MainMenu)
	assert_false(get_tree().paused)
