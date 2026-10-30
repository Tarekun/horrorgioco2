## The title screen: New game, Load game, Settings and Quit.
##
## Everything works with keyboard, mouse and gamepad through the engine's UI
## focus navigation (arrows and d-pad move, accept and click press). Settings
## opens its own settings screen, and Load game the save slot screen in load
## mode; the save chosen there is loaded.

class_name MainMenu
extends Control

@export var new_game_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var settings_screen: SettingsScreen
@export var save_screen: SaveScreen


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_button.pressed.connect(save_screen.open_to_load)
	save_screen.closed.connect(load_button.grab_focus)
	save_screen.load_requested.connect(GameFlow.load_game)
	settings_button.pressed.connect(settings_screen.open)
	settings_screen.closed.connect(settings_button.grab_focus)
	quit_button.pressed.connect(_on_quit_pressed)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	GameFlow.start_new_game()


func _on_quit_pressed() -> void:
	GameFlow.quit_game()
