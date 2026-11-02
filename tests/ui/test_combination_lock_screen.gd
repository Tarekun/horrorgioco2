## Tests for the combination lock screen: wheels, turning, solving and pausing.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _screen: CombinationLockScreen
var _puzzle: CombinationLockPuzzle


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_screen = _player.get_node("CombinationLockScreen") as CombinationLockScreen
	_puzzle = CombinationLockPuzzle.new()
	_puzzle.code = "0447"
	add_child_autofree(_puzzle)
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _input_event(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_screen._unhandled_input(event)


func _labels() -> Array[String]:
	return [
		_screen.wheel_label_0.text,
		_screen.wheel_label_1.text,
		_screen.wheel_label_2.text,
		_screen.wheel_label_3.text,
	]


func test_opening_shows_the_wheels_at_zero_and_pauses() -> void:
	_screen.open(_puzzle)
	assert_true(_screen.is_open)
	assert_true(get_tree().paused)
	assert_eq(_labels(), ["0", "0", "0", "0"])


func test_up_and_down_turn_the_selected_wheel_wrapping() -> void:
	_screen.open(_puzzle)
	_input_event(&"ui_up")
	assert_eq(_labels()[0], "1")
	_input_event(&"ui_down")
	assert_eq(_labels()[0], "0")
	_input_event(&"ui_down")
	assert_eq(_labels()[0], "9")


func test_left_and_right_move_the_selection() -> void:
	_screen.open(_puzzle)
	_input_event(&"ui_right")
	_input_event(&"ui_up")
	assert_eq(_labels()[1], "1")
	assert_eq(_labels()[0], "0")
	_input_event(&"ui_left")
	_input_event(&"ui_up")
	assert_eq(_labels()[0], "1")


func test_matching_the_code_solves_it() -> void:
	_screen.open(_puzzle)
	_input_event(&"ui_right")
	for _i: int in 4:
		_input_event(&"ui_up")
	_input_event(&"ui_right")
	for _i: int in 4:
		_input_event(&"ui_up")
	_input_event(&"ui_right")
	for _i: int in 7:
		_input_event(&"ui_up")
	assert_true(_puzzle.is_solved)
	assert_eq(_screen.message_label.text, "The lock clicks open.")


func test_a_wrong_code_does_not_solve_it() -> void:
	_screen.open(_puzzle)
	_input_event(&"ui_up")
	assert_false(_puzzle.is_solved)
	assert_eq(_screen.message_label.text, "")


func test_turning_a_wheel_does_nothing_once_solved() -> void:
	_puzzle.solve(_player)
	_screen.open(_puzzle)
	_input_event(&"ui_up")
	assert_eq(_labels()[0], "0")


func test_opening_an_already_solved_puzzle_shows_the_message() -> void:
	_puzzle.already_solved_message = "The cabinet stands open."
	_puzzle.solve(_player)
	_screen.open(_puzzle)
	assert_eq(_screen.message_label.text, "The cabinet stands open.")


func test_pause_or_cancel_closes_it() -> void:
	_screen.open(_puzzle)
	_input_event(&"ui_cancel")
	assert_false(_screen.is_open)
	assert_false(get_tree().paused)


func test_close_resumes_and_recaptures_the_mouse() -> void:
	_screen.open(_puzzle)
	_screen.close()
	assert_false(_screen.is_open)
	assert_false(get_tree().paused)
	assert_true(_player.camera_controller.is_mouse_captured())


func test_cannot_open_while_another_screen_has_paused_the_game() -> void:
	get_tree().paused = true
	_screen.open(_puzzle)
	assert_false(_screen.is_open)


func test_the_puzzle_opens_the_screen_through_the_group() -> void:
	_puzzle.interact(_player)
	assert_true(_screen.is_open)
