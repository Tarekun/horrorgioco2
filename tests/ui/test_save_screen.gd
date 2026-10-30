## Tests for the save slot screen in save and load mode.

extends GutTest

const SCREEN_SCENE: PackedScene = preload("res://scenes/ui/save_screen.tscn")
const DIRECTORY: String = "user://test_save_screen"

var _screen: SaveScreen
var _slots: SaveSlots
var _previous_slots: SaveSlots
var _previous_state: GameFlow.State


func before_each() -> void:
	_previous_slots = SaveSystem.slots
	_previous_state = GameFlow.state
	_slots = SaveSlots.new(DIRECTORY)
	_clear()
	SaveSystem.slots = _slots
	GameFlow.state = GameFlow.State.PLAYING
	_screen = SCREEN_SCENE.instantiate() as SaveScreen
	add_child_autofree(_screen)


func after_each() -> void:
	_clear()
	DirAccess.remove_absolute(DIRECTORY)
	SaveSystem.slots = _previous_slots
	GameFlow.state = _previous_state
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _clear() -> void:
	for slot: int in SaveSlots.SLOT_COUNT:
		_slots.delete(slot)


func _make_save(area_name: String) -> SaveData:
	var save := SaveData.new()
	save.level_path = "res://scenes/levels/graybox_level.tscn"
	save.area_name = area_name
	save.play_time = 125.0
	return save


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_screen._unhandled_input(event)


func test_is_hidden_at_first() -> void:
	assert_false(_screen.is_open)
	assert_false(_screen.panel.visible)
	assert_eq(_screen.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_lists_all_eight_slots() -> void:
	_screen.open_to_save(_make_save("Lobby"))
	assert_eq(_screen.slot_list.get_child_count(), 8)
	assert_eq(_screen.get_slot_button(0).text, "Slot 1   Empty")
	assert_eq(_screen.get_slot_button(7).text, "Slot 8   Empty")


func test_a_slot_shows_area_play_time_and_timestamp() -> void:
	var save: SaveData = _make_save("Office")
	save.timestamp = 1_793_000_000
	_slots.write(2, save)
	_screen.open_to_load()
	var text: String = _screen.get_slot_button(2).text
	assert_string_starts_with(text, "Slot 3   Office")
	assert_string_contains(text, "0:02:05")
	assert_string_contains(text, SaveSlotInfo.format_timestamp(1_793_000_000))


func test_opening_to_save_pauses_the_game_and_frees_the_mouse() -> void:
	_screen.open_to_save(_make_save("Lobby"))
	assert_true(_screen.is_open)
	assert_true(_screen.panel.visible)
	assert_eq(_screen.mode, SaveScreen.Mode.SAVE)
	assert_eq(_screen.title_label.text, "Save game")
	assert_true(get_tree().paused)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE)
	assert_true(_screen.get_slot_button(0).has_focus())


func test_closing_resumes_the_game() -> void:
	watch_signals(_screen)
	_screen.open_to_save(_make_save("Lobby"))
	_screen.close()
	assert_false(_screen.is_open)
	assert_false(get_tree().paused)
	assert_signal_emitted(_screen, "closed")


func test_saving_into_an_empty_slot_writes_it() -> void:
	watch_signals(_screen)
	_screen.open_to_save(_make_save("Lobby"))
	_screen.get_slot_button(1).pressed.emit()
	var save: SaveData = _slots.read(1)
	assert_not_null(save)
	assert_eq(save.area_name, "Lobby")
	assert_gt(save.timestamp, 0)
	assert_eq(_screen.message_label.text, SaveScreen.SAVED_MESSAGE)
	assert_string_starts_with(_screen.get_slot_button(1).text, "Slot 2   Lobby")
	assert_signal_emitted_with_parameters(_screen, "saved", [1])
	assert_false(_screen.is_confirming())


func test_saving_over_a_used_slot_asks_first() -> void:
	_slots.write(4, _make_save("Lobby"))
	_screen.open_to_save(_make_save("Office"))
	_screen.choose_slot(4)
	assert_true(_screen.is_confirming())
	assert_eq(_screen.confirm_label.text, "Save over slot 5?")
	assert_true(_screen.cancel_button.has_focus())
	assert_eq(_slots.read(4).area_name, "Lobby")
	_screen.confirm_button.pressed.emit()
	assert_false(_screen.is_confirming())
	assert_eq(_slots.read(4).area_name, "Office")


func test_saying_no_keeps_the_old_save() -> void:
	_slots.write(4, _make_save("Lobby"))
	_screen.open_to_save(_make_save("Office"))
	_screen.choose_slot(4)
	_screen.cancel_button.pressed.emit()
	assert_false(_screen.is_confirming())
	assert_true(_screen.is_open)
	assert_eq(_slots.read(4).area_name, "Lobby")
	assert_true(_screen.get_slot_button(4).has_focus())


func test_an_unreadable_slot_also_asks_before_being_saved_over() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file := FileAccess.open(_slots.get_slot_path(0), FileAccess.WRITE)
	file.store_string("garbage")
	file.close()
	_screen.open_to_save(_make_save("Lobby"))
	_screen.choose_slot(0)
	assert_true(_screen.is_confirming())


func test_cancel_steps_back_from_the_question_then_closes() -> void:
	_slots.write(0, _make_save("Lobby"))
	_screen.open_to_save(_make_save("Office"))
	_screen.choose_slot(0)
	_press(&"ui_cancel")
	assert_false(_screen.is_confirming())
	assert_true(_screen.is_open)
	_press(&"pause")
	assert_false(_screen.is_open)


func test_load_mode_only_offers_loadable_slots() -> void:
	_slots.write(3, _make_save("Lobby"))
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file := FileAccess.open(_slots.get_slot_path(5), FileAccess.WRITE)
	file.store_string("garbage")
	file.close()
	_screen.open_to_load()
	assert_eq(_screen.mode, SaveScreen.Mode.LOAD)
	assert_eq(_screen.title_label.text, "Load game")
	assert_true(_screen.get_slot_button(0).disabled)
	assert_false(_screen.get_slot_button(3).disabled)
	assert_true(_screen.get_slot_button(5).disabled)
	assert_eq(_screen.get_slot_button(5).text, "Slot 6   Unreadable save")
	assert_true(_screen.get_slot_button(3).has_focus())


func test_load_mode_with_no_saves_focuses_back() -> void:
	_screen.open_to_load()
	assert_true(_screen.back_button.has_focus())


func test_choosing_a_save_to_load_asks_for_it_and_closes() -> void:
	_slots.write(3, _make_save("Lobby"))
	watch_signals(_screen)
	_screen.open_to_load()
	_screen.get_slot_button(3).pressed.emit()
	assert_signal_emitted(_screen, "load_requested")
	var params: Array = get_signal_parameters(_screen, "load_requested")
	assert_eq((params[0] as SaveData).area_name, "Lobby")
	assert_false(_screen.is_open)


func test_an_empty_slot_cant_be_loaded() -> void:
	watch_signals(_screen)
	_screen.open_to_load()
	_screen.choose_slot(0)
	assert_signal_not_emitted(_screen, "load_requested")
	assert_true(_screen.is_open)


func test_over_a_paused_screen_the_pause_is_left_alone() -> void:
	# The game over screen has already paused the game.
	get_tree().paused = true
	_screen.open_to_load()
	_screen.close()
	assert_true(get_tree().paused)


func test_on_the_title_screen_the_game_isnt_paused() -> void:
	GameFlow.state = GameFlow.State.TITLE
	_screen.open_to_load()
	assert_false(get_tree().paused)
	_screen.close()
	assert_false(get_tree().paused)
