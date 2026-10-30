extends GutTest

const MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

var _menu: MainMenu


func before_each() -> void:
	_menu = MENU_SCENE.instantiate() as MainMenu
	add_child_autofree(_menu)


func test_has_the_four_options() -> void:
	assert_eq(_menu.new_game_button.text, "New game")
	assert_eq(_menu.load_button.text, "Load game")
	assert_eq(_menu.settings_button.text, "Settings")
	assert_eq(_menu.quit_button.text, "Quit")


func test_new_game_starts_focused_for_keyboard_and_gamepad() -> void:
	assert_true(_menu.new_game_button.has_focus())


func test_buttons_are_reachable_with_focus_navigation() -> void:
	var buttons: Array[Button] = [
		_menu.new_game_button, _menu.load_button, _menu.settings_button, _menu.quit_button
	]
	for button: Button in buttons:
		assert_eq(button.focus_mode, Control.FOCUS_ALL, "%s can't take focus" % button.text)


func test_load_opens_the_save_slot_screen_in_load_mode() -> void:
	assert_false(_menu.load_button.disabled)
	_menu.load_button.pressed.emit()
	assert_true(_menu.save_screen.is_open)
	assert_eq(_menu.save_screen.mode, SaveScreen.Mode.LOAD)
	_menu.save_screen.close()
	assert_true(_menu.load_button.has_focus())


func test_settings_opens_the_settings_screen_and_closing_returns_focus() -> void:
	_menu.settings_button.pressed.emit()
	assert_true(_menu.settings_screen.is_open)
	_menu.settings_screen.close()
	assert_true(_menu.settings_button.has_focus())


func test_new_game_starts_the_game() -> void:
	var main: Node = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	var menu := main.get_node("ScreenHost").get_child(0) as MainMenu
	menu.new_game_button.pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
