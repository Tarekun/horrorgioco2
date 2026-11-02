## The combination lock screen: a row of wheels, one per digit of a
## CombinationLockPuzzle's code.
##
## Up and down change the selected wheel's digit (0-9, wrapping); left and
## right move the selection between wheels. The lock opens the moment the
## wheels read the code, with no penalty for wrong tries. `pause` or
## `ui_cancel` closes the screen.
##
## A puzzle broadcasts to GROUP to open it, so it never needs a direct
## reference to the player's screens.

class_name CombinationLockScreen
extends CanvasLayer

## Emitted after the screen opens.
signal opened
## Emitted after the screen closes.
signal closed

## Group a puzzle broadcasts to in order to open the screen.
const GROUP: StringName = &"combination_lock_screen"

## Whose inventory the reward (if any) is added to.
@export var player: Player

## The container shown and hidden with the screen.
@export var panel: Control

## One label per wheel, in order. Only the first `wheel_count()` are shown.
@export var wheel_label_0: Label
@export var wheel_label_1: Label
@export var wheel_label_2: Label
@export var wheel_label_3: Label

## A short reply once the lock opens, or why it's already open.
@export var message_label: Label

var is_open: bool = false

var _puzzle: CombinationLockPuzzle
var _digits: Array[int] = []
var _selected: int = 0
var _wheel_labels: Array[Label] = []


func _ready() -> void:
	# Keep running while the tree is paused, so the screen works.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	panel.visible = false
	_wheel_labels = [wheel_label_0, wheel_label_1, wheel_label_2, wheel_label_3]


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"ui_left"):
		_select(_selected - 1)
	elif event.is_action_pressed(&"ui_right"):
		_select(_selected + 1)
	elif event.is_action_pressed(&"ui_up"):
		_turn_wheel(1)
	elif event.is_action_pressed(&"ui_down"):
		_turn_wheel(-1)
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


## Whether the screen may open now: the player is alive and no other screen
## has paused the game.
func can_open() -> bool:
	return not get_tree().paused and player and not player.health_component.is_dead


## Opens the screen on `puzzle`, its wheels reset to all zeroes. Does nothing
## if the screen can't open.
func open(puzzle: CombinationLockPuzzle) -> void:
	if puzzle == null:
		return
	if not is_open and not can_open():
		return
	is_open = true
	_puzzle = puzzle
	_digits.clear()
	for _wheel: int in puzzle.wheel_count():
		_digits.append(0)
	_selected = 0
	message_label.text = _puzzle.already_solved_message if puzzle.is_solved else ""
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()
	opened.emit()


## Hides the screen, resumes the game and captures the mouse again.
func close() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# The camera only turns with the mouse once it knows it is captured.
	get_tree().call_group(CameraController.MOUSE_LOOK_GROUP, &"capture_mouse")
	closed.emit()


func _select(index: int) -> void:
	if _digits.is_empty():
		return
	_selected = wrapi(index, 0, _digits.size())
	_refresh()


func _turn_wheel(step: int) -> void:
	if _puzzle == null or _puzzle.is_solved or _digits.is_empty():
		return
	_digits[_selected] = wrapi(_digits[_selected] + step, 0, 10)
	_refresh()
	_check_solution()


func _check_solution() -> void:
	if _puzzle == null or _puzzle.is_solved or not _puzzle.matches(_digits):
		return
	message_label.text = _puzzle.solve(player)
	_refresh()


func _refresh() -> void:
	for index: int in _wheel_labels.size():
		var label: Label = _wheel_labels[index]
		label.visible = index < _digits.size()
		if not label.visible:
			continue
		label.text = str(_digits[index])
		label.modulate = Color.WHITE if index == _selected else Color(0.6, 0.6, 0.6)
