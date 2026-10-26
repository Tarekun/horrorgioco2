## The title screen: New game, Load game, Settings and Quit.
##
## Everything works with keyboard, mouse and gamepad through the engine's UI
## focus navigation (arrows and d-pad move, accept and click press). Load game
## and Settings only announce the request; the save slot screen (#91) and the
## settings screen (#86) listen for it.

class_name MainMenu
extends Control

## Emitted when Load game is pressed.
signal load_game_requested
## Emitted when Settings is pressed.
signal settings_requested

## Whether there is a save slot screen to open. Load game stays disabled until
## the save slot screen (#91) turns this on.
@export var is_load_available: bool = false:
	set(value):
		is_load_available = value
		_update_load_button()

@export var new_game_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(load_game_requested.emit)
	settings_button.pressed.connect(settings_requested.emit)
	quit_button.pressed.connect(_on_quit_pressed)
	_update_load_button()
	new_game_button.grab_focus()


func _update_load_button() -> void:
	if load_button:
		load_button.disabled = not is_load_available


func _on_new_game_pressed() -> void:
	GameFlow.start_new_game()


func _on_quit_pressed() -> void:
	GameFlow.quit_game()
