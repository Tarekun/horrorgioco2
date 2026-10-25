## The title screen.

class_name MainMenu
extends Control

@export var new_game_button: Button


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	GameFlow.start_new_game()
