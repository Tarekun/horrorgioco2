## Small text at the bottom of the screen: a subtle prompt while something can
## be used, and short messages ("It's locked.") that fade after a moment. Longer
## messages, such as an examined object's description, stay long enough to read.

class_name InteractionHint
extends CanvasLayer

## Seconds a message stays before it disappears, at the least.
@export var message_duration: float = 2.0

## Reading time per character, for messages too long to read in
## `message_duration`.
@export var seconds_per_character: float = 0.06

@export var prompt_label: Label
@export var message_label: Label

var _message_left: float = 0.0


func _ready() -> void:
	prompt_label.visible = false
	message_label.visible = false


func _process(delta: float) -> void:
	tick(delta)


## Advances the message timer by `delta` seconds.
func tick(delta: float) -> void:
	if _message_left <= 0.0:
		return
	_message_left -= delta
	if _message_left <= 0.0:
		message_label.visible = false


func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true


func hide_prompt() -> void:
	prompt_label.visible = false


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	_message_left = get_duration(text)


## Seconds `text` stays on screen.
func get_duration(text: String) -> float:
	return maxf(message_duration, text.length() * seconds_per_character)
