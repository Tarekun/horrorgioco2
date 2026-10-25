## The game over screen: shown when the player dies, with a retry button.
##
## Showing it pauses the game; retry unpauses and reloads the current scene.
## The gameplay spec replaces "retry reloads the level" with loading the last
## save once saving exists; this is the interim behaviour.

class_name GameOverScreen
extends CanvasLayer

## Emitted when the player chooses to retry, before the scene reloads.
signal retry_requested

## Reload the current scene on retry. Tests turn it off.
@export var is_reload_on_retry: bool = true

## The container shown and hidden with the screen.
@export var panel: Control

@export var retry_button: Button

var is_showing: bool = false


func _ready() -> void:
	# Keep running while the tree is paused, so the button works.
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	retry_button.pressed.connect(retry)


## Shows the screen and pauses the game.
func show_screen() -> void:
	if is_showing:
		return
	is_showing = true
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	retry_button.grab_focus()


## Unpauses and restarts the level.
func retry() -> void:
	get_tree().paused = false
	is_showing = false
	panel.visible = false
	retry_requested.emit()
	if is_reload_on_retry:
		get_tree().reload_current_scene()
