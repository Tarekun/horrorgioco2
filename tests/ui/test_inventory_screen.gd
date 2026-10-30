## Tests for the inventory screen: opening, closing, pausing and the status
## readout. The items and actions are in test_inventory_screen_items.gd.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _screen: InventoryScreen


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_screen = _player.get_node("InventoryScreen") as InventoryScreen
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_screen._unhandled_input(event)


func test_is_hidden_and_the_game_runs_at_first() -> void:
	assert_false(_screen.is_open)
	assert_false(_screen.panel.visible)
	assert_false(get_tree().paused)


func test_inventory_opens_it_pauses_and_releases_the_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_press(&"inventory")
	assert_true(_screen.is_open)
	assert_true(_screen.panel.visible)
	assert_true(get_tree().paused)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE)
	assert_true(_screen.item_list.has_focus())


func test_inventory_again_closes_it_and_resumes() -> void:
	_press(&"inventory")
	_press(&"inventory")
	assert_false(_screen.is_open)
	assert_false(_screen.panel.visible)
	assert_false(get_tree().paused)
	assert_true(_player.camera_controller.is_mouse_captured())


func test_pause_closes_it() -> void:
	_screen.open()
	_press(&"pause")
	assert_false(_screen.is_open)
	assert_false(get_tree().paused)


func test_cancel_closes_it_from_the_list() -> void:
	_screen.open()
	_press(&"ui_cancel")
	assert_false(_screen.is_open)


func test_cancel_and_pause_do_not_open_it() -> void:
	_press(&"ui_cancel")
	_press(&"pause")
	assert_false(_screen.is_open)


func test_signals_on_open_and_close() -> void:
	watch_signals(_screen)
	_screen.open()
	assert_signal_emitted(_screen, "opened")
	_screen.close()
	assert_signal_emitted(_screen, "closed")


func test_cannot_open_over_another_pausing_screen() -> void:
	get_tree().paused = true  # the pause menu, say
	_press(&"inventory")
	assert_false(_screen.is_open)
	assert_false(_screen.panel.visible)


func test_cannot_open_when_dead() -> void:
	_player.health_component.take_damage(500.0)
	_press(&"inventory")
	assert_false(_screen.is_open)


func test_the_screen_and_its_trace_keep_running_while_paused() -> void:
	assert_eq(_screen.process_mode, Node.PROCESS_MODE_ALWAYS)
	_screen.open()
	assert_true(_screen.ecg_line.can_process())


func test_the_player_stops_while_it_is_open() -> void:
	_screen.open()
	assert_false(_player.can_process())
	_screen.close()
	assert_true(_player.can_process())


func test_status_reads_fine_at_full_health() -> void:
	assert_eq(_screen.status_label.text, "Fine")
	assert_eq(_screen.ecg_line.state, HealthState.State.FINE)


func test_status_follows_the_health_state() -> void:
	_player.health_component.take_damage(50.0)
	assert_eq(_screen.status_label.text, "Caution")
	assert_eq(_screen.ecg_line.state, HealthState.State.CAUTION)
	_player.health_component.take_damage(30.0)
	assert_eq(_screen.status_label.text, "Danger")
	assert_eq(_screen.ecg_line.state, HealthState.State.DANGER)
	_player.health_component.heal(100.0)
	assert_eq(_screen.status_label.text, "Fine")


func test_status_never_shows_a_number() -> void:
	var digits := RegEx.create_from_string("\\d")
	for damage: float in [0.0, 25.0, 30.0, 40.0]:
		_player.health_component.take_damage(damage)
		_screen.open()
		assert_null(digits.search(_screen.status_label.text), _screen.status_label.text)
		_screen.close()


func test_status_colour_matches_the_trace() -> void:
	_player.health_component.take_damage(80.0)
	assert_eq(_screen.status_label.get_theme_color(&"font_color"), _screen.ecg_line.get_color())
