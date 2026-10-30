## The game over screen, shown when the player dies: Load last save, Load
## game… and Quit to title.
##
## Showing it pauses the game and tells GameFlow. Load last save loads the most
## recent save written or loaded this session (SaveSystem.last_save), or starts
## the game over when there is none. Load game… opens the save slot screen in
## load mode over it, and the save picked there is loaded. Quit to title goes
## back to the title screen. Each choice goes through GameFlow, which replaces
## the level this screen is in.

class_name GameOverScreen
extends CanvasLayer

## The container shown and hidden with the screen.
@export var panel: Control

@export var load_last_button: Button
@export var load_game_button: Button
@export var quit_button: Button

## The slot screen Load game… opens.
@export var save_screen: SaveScreen

var is_showing: bool = false


func _ready() -> void:
	# Keep running while the tree is paused, so the buttons work.
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	load_last_button.pressed.connect(load_last_save)
	load_game_button.pressed.connect(save_screen.open_to_load)
	quit_button.pressed.connect(quit_to_title)
	save_screen.load_requested.connect(_on_load_requested)
	save_screen.closed.connect(_on_save_screen_closed)


## Shows the screen and pauses the game.
func show_screen() -> void:
	if is_showing:
		return
	is_showing = true
	panel.visible = true
	get_tree().paused = true
	GameFlow.enter_game_over()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	load_last_button.grab_focus()


## Loads the last save, or starts the game over if there is none.
func load_last_save() -> void:
	var save: SaveData = SaveSystem.last_save
	_hide()
	if save:
		GameFlow.load_game(save)
	else:
		GameFlow.restart_game()


## Leaves for the title screen.
func quit_to_title() -> void:
	_hide()
	GameFlow.go_to_title()


func _hide() -> void:
	is_showing = false
	panel.visible = false


func _on_load_requested(save: SaveData) -> void:
	_hide()
	GameFlow.load_game(save)


func _on_save_screen_closed() -> void:
	if is_showing:
		load_game_button.grab_focus()
