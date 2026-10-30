extends GutTest

const GameFlowScript := preload("res://scripts/autoload/game_flow.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _flow: GameFlowScript
var _host: Node


func before_each() -> void:
	_host = Node.new()
	add_child_autofree(_host)
	_flow = GameFlowScript.new()
	add_child_autofree(_flow)
	_flow.title_scene = _scene_named("Title")
	_flow.start_level_scene = _scene_named("Level")
	_flow.attach_host(_host)


func after_each() -> void:
	get_tree().paused = false


func _scene_named(node_name: String) -> PackedScene:
	var node := Node.new()
	node.name = node_name
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func _screens() -> Array[String]:
	var names: Array[String] = []
	for child in _host.get_children():
		names.append(child.name)
	return names


func test_starts_with_no_state() -> void:
	assert_eq(_flow.state, GameFlowScript.State.NONE)


func test_go_to_title_shows_the_title() -> void:
	_flow.go_to_title()
	assert_eq(_screens(), ["Title"])
	assert_eq(_flow.state, GameFlowScript.State.TITLE)


func test_new_game_replaces_the_title_with_the_level() -> void:
	_flow.go_to_title()
	_flow.start_new_game()
	assert_eq(_screens(), ["Level"])
	assert_eq(_flow.state, GameFlowScript.State.PLAYING)


func test_going_back_to_the_title_removes_the_level_and_unpauses() -> void:
	_flow.start_new_game()
	get_tree().paused = true
	_flow.go_to_title()
	assert_eq(_screens(), ["Title"])
	assert_false(get_tree().paused)


func test_game_over_is_a_state() -> void:
	_flow.start_new_game()
	_flow.enter_game_over()
	assert_eq(_flow.state, GameFlowScript.State.GAME_OVER)


func test_restart_game_starts_a_fresh_level_and_unpauses() -> void:
	_flow.start_new_game()
	var first: Node = _host.get_child(0)
	_flow.enter_game_over()
	get_tree().paused = true
	_flow.restart_game()
	assert_eq(_screens(), ["Level"])
	assert_ne(_host.get_child(0), first)
	assert_eq(_flow.state, GameFlowScript.State.PLAYING)
	assert_false(get_tree().paused)


func test_state_changes_are_announced() -> void:
	watch_signals(_flow)
	_flow.go_to_title()
	assert_signal_emitted_with_parameters(_flow, "state_changed", [GameFlowScript.State.TITLE])


func test_the_default_scenes_exist() -> void:
	assert_true(ResourceLoader.exists(GameFlowScript.TITLE_SCENE_PATH))
	assert_true(ResourceLoader.exists(GameFlowScript.START_LEVEL_PATH))


func test_the_main_scene_opens_the_title_screen() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	assert_true(main.get_node("ScreenHost").get_child(0) is MainMenu)
	assert_eq(GameFlow.state, GameFlow.State.TITLE)


func test_the_title_screen_starts_a_new_game() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	var menu := main.get_node("ScreenHost").get_child(0) as MainMenu
	menu.new_game_button.pressed.emit()
	assert_eq(GameFlow.state, GameFlow.State.PLAYING)
	assert_not_null(main.get_node_or_null("ScreenHost/GrayboxLevel/Player"))
