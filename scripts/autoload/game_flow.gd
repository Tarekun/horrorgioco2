## Moves the game between the title screen, a level and game over.
##
## `scenes/main.tscn` stays loaded for the whole run (it holds the post-process
## layer) and registers its screen host here; the title screen and the levels
## are instanced inside that host, one at a time. Menus and screens ask for a
## change through the methods below instead of switching scenes themselves.
## Loading a save instances its level fresh and has SaveSystem restore it.
##
## Without a host (a level run on its own from the editor) restart_game()
## falls back to reloading the current scene.

extends Node

## Emitted after the state changes, with the new state.
signal state_changed(new_state: State)

enum State { NONE, TITLE, PLAYING, GAME_OVER }

const TITLE_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"

## The level a new game starts in. #70 replaces it with the hotel.
const START_LEVEL_PATH: String = "res://scenes/levels/graybox_level.tscn"

## Scene shown as the title screen. Tests replace it.
var title_scene: PackedScene = load(TITLE_SCENE_PATH)

## Scene a new game starts in. Tests replace it.
var start_level_scene: PackedScene = load(START_LEVEL_PATH)

var state: State = State.NONE

var _host: Node
var _screen: Node


## Registers the node that holds the current screen. Called by `main.tscn`.
func attach_host(host: Node) -> void:
	_host = host


## Shows the title screen, leaving any level and unpausing the game.
func go_to_title() -> void:
	_show_screen(title_scene)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_state(State.TITLE)


## Starts a new game in the starting level, with a fresh world state.
func start_new_game() -> void:
	SaveSystem.reset()
	_show_screen(start_level_scene)
	_set_state(State.PLAYING)


## Loads `save`: its level from scratch, put back in the state the save holds,
## with the player at the save spot used.
func load_game(save: SaveData) -> void:
	if not is_instance_valid(_host):
		push_warning("GameFlow has no screen host; is scenes/main.tscn running?")
		return
	if not ResourceLoader.exists(save.level_path):
		push_warning("GameFlow: the save's level %s doesn't exist." % save.level_path)
		return
	var scene := load(save.level_path) as PackedScene
	if scene == null:
		push_warning("GameFlow: %s isn't a scene." % save.level_path)
		return
	SaveSystem.begin_from(save)
	_show_screen(scene)
	SaveSystem.restore(_screen, save)
	_set_state(State.PLAYING)


## Starts the game over from the beginning: what game over's Load last save
## does when nothing was saved yet. Without a host, reloads the current scene.
func restart_game() -> void:
	get_tree().paused = false
	if not is_instance_valid(_host):
		SaveSystem.reset()
		get_tree().reload_current_scene()
		_set_state(State.PLAYING)
		return
	start_new_game()


## Records that the game over screen is up. It pauses the game itself.
func enter_game_over() -> void:
	_set_state(State.GAME_OVER)


## Quits the application.
func quit_game() -> void:
	get_tree().quit()


func _show_screen(scene: PackedScene) -> void:
	get_tree().paused = false
	if not is_instance_valid(_host):
		push_warning("GameFlow has no screen host; is scenes/main.tscn running?")
		return
	if is_instance_valid(_screen):
		# Removed first so the old screen is gone before the new one starts.
		_host.remove_child(_screen)
		_screen.queue_free()
	_screen = scene.instantiate()
	_host.add_child(_screen)


func _set_state(new_state: State) -> void:
	state = new_state
	state_changed.emit(new_state)
