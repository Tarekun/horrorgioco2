extends GutTest

const MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _menu: PauseMenu
var _main: Node
var _camera: CameraController


func before_each() -> void:
	# The real GameFlow with a stub level, so a game is "playing" cheaply.
	var level := Node.new()
	var scene := PackedScene.new()
	scene.pack(level)
	level.free()
	GameFlow.start_level_scene = scene
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_menu = _main.get_node("PauseMenu") as PauseMenu
	_camera = CameraController.new()
	_main.add_child(_camera)
	GameFlow.start_new_game()


func after_each() -> void:
	get_tree().paused = false
	GameFlow.start_level_scene = load(GameFlow.START_LEVEL_PATH)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_menu._unhandled_input(event)


func test_is_hidden_and_the_game_runs_at_first() -> void:
	assert_false(_menu.panel.visible)
	assert_false(get_tree().paused)


func test_pause_opens_it_pauses_and_releases_the_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_press(&"pause")
	assert_true(_menu.is_open)
	assert_true(_menu.panel.visible)
	assert_true(get_tree().paused)
	assert_true(_menu.resume_button.has_focus())


func test_pause_again_resumes_and_captures_the_mouse() -> void:
	_press(&"pause")
	# The camera also sees the pause press and lets go of the mouse.
	var pause := InputEventAction.new()
	pause.action = &"pause"
	pause.pressed = true
	_camera._unhandled_input(pause)
	assert_false(_camera.is_mouse_captured())
	_press(&"pause")
	assert_false(_menu.is_open)
	assert_false(_menu.panel.visible)
	assert_false(get_tree().paused)

	assert_true(_camera.is_mouse_captured())


func test_resume_button_resumes() -> void:
	_menu.open()
	_menu.resume_button.pressed.emit()
	assert_false(get_tree().paused)
	assert_true(_camera.is_mouse_captured())


func test_cancel_closes_it_but_does_not_open_it() -> void:
	_press(&"ui_cancel")
	assert_false(_menu.is_open)
	_menu.open()
	_press(&"ui_cancel")
	assert_false(_menu.is_open)


func test_cannot_open_over_another_pausing_screen() -> void:
	get_tree().paused = true  # the inventory, say
	_press(&"pause")
	assert_false(_menu.is_open)
	assert_false(_menu.panel.visible)


func test_cannot_open_over_game_over() -> void:
	GameFlow.enter_game_over()
	get_tree().paused = true
	_press(&"pause")
	assert_false(_menu.is_open)


func test_cannot_open_on_the_title_screen() -> void:
	GameFlow.go_to_title()
	_press(&"pause")
	assert_false(_menu.is_open)
	assert_false(get_tree().paused)


func test_settings_announces_the_request() -> void:
	watch_signals(_menu)
	_menu.open()
	_menu.settings_button.pressed.emit()
	assert_signal_emitted(_menu, "settings_requested")


func test_quit_to_title_unpauses_and_closes() -> void:
	_menu.open()
	_menu.quit_button.pressed.emit()
	assert_false(_menu.is_open)
	assert_false(_menu.panel.visible)
	assert_false(get_tree().paused)
	assert_eq(GameFlow.state, GameFlow.State.TITLE)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE)
