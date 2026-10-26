## The in-game pause menu: Resume, Settings and Quit to title.
##
## The `pause` action opens it while playing and closes it again. Opening
## pauses the tree and releases the mouse; closing captures the mouse again.
## It never opens over another screen that pauses the game (the inventory, the
## game over screen): any of them leaves the tree paused, which is what it
## checks. Any change of GameFlow state, such as leaving for the title, closes
## it.

class_name PauseMenu
extends CanvasLayer

## Emitted when Settings is pressed; the settings screen (#86) listens.
signal settings_requested

## The container shown and hidden with the menu.
@export var panel: Control

@export var resume_button: Button
@export var settings_button: Button
@export var quit_button: Button

var is_open: bool = false


func _ready() -> void:
	# Keep running while the tree is paused, so the menu can close itself.
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(settings_requested.emit)
	quit_button.pressed.connect(GameFlow.go_to_title)
	GameFlow.state_changed.connect(_on_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		return
	if is_open:
		close()
	elif event.is_action_pressed(&"pause") and can_open():
		open()
	else:
		return
	get_viewport().set_input_as_handled()


## Whether the menu may open now: during play, and not over a screen that
## already paused the game.
func can_open() -> bool:
	return GameFlow.state == GameFlow.State.PLAYING and not get_tree().paused


## Pauses the game and shows the menu. Does nothing if it can't open.
func open() -> void:
	if is_open or not can_open():
		return
	is_open = true
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.grab_focus()


## Hides the menu, resumes the game and captures the mouse again.
func close() -> void:
	if not is_open:
		return
	_hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# The camera only turns with the mouse once it knows it is captured.
	get_tree().call_group(CameraController.MOUSE_LOOK_GROUP, &"capture_mouse")


func _hide() -> void:
	is_open = false
	panel.visible = false


func _on_state_changed(_new_state: int) -> void:
	_hide()
