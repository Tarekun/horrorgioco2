## Tests for the SaveSystem autoload.

extends GutTest

var _previous_state: GameFlow.State


func before_each() -> void:
	_previous_state = GameFlow.state


func after_each() -> void:
	SaveSystem.reset()
	GameFlow.state = _previous_state
	get_tree().paused = false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func test_reset_starts_an_empty_world() -> void:
	SaveSystem.world.record(&"door", {"is_locked": false})
	SaveSystem.reset()
	assert_true(SaveSystem.world.is_empty())


func test_a_new_game_starts_an_empty_world() -> void:
	SaveSystem.world.record(&"door", {"is_locked": false})
	var main: Node = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	GameFlow.start_new_game()
	assert_true(SaveSystem.world.is_empty())


func test_reset_starts_play_time_from_zero() -> void:
	SaveSystem.play_time = 42.0
	SaveSystem.reset()
	assert_eq(SaveSystem.play_time, 0.0)


func test_play_time_counts_during_play() -> void:
	GameFlow.state = GameFlow.State.PLAYING
	SaveSystem.play_time = 10.0
	await _wait(0.2)
	assert_between(SaveSystem.play_time, 10.1, 10.5)


func test_play_time_stops_while_paused() -> void:
	GameFlow.state = GameFlow.State.PLAYING
	get_tree().paused = true
	assert_false(SaveSystem.is_counting_play_time())
	SaveSystem.play_time = 10.0
	await _wait(0.2)
	assert_eq(SaveSystem.play_time, 10.0)


func test_play_time_stops_outside_play() -> void:
	for state: GameFlow.State in [GameFlow.State.TITLE, GameFlow.State.GAME_OVER]:
		GameFlow.state = state
		assert_false(SaveSystem.is_counting_play_time(), str(state))
	GameFlow.state = GameFlow.State.TITLE
	SaveSystem.play_time = 10.0
	await _wait(0.2)
	assert_eq(SaveSystem.play_time, 10.0)
