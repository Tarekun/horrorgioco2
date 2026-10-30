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


func test_writing_a_save_makes_it_the_last() -> void:
	var previous_slots: SaveSlots = SaveSystem.slots
	SaveSystem.slots = SaveSlots.new("user://test_save_system")
	var save := SaveData.new()
	save.level_path = "res://scenes/levels/graybox_level.tscn"
	assert_eq(SaveSystem.write_slot(0, save), OK)
	assert_eq(SaveSystem.last_save, save)
	assert_gt(save.timestamp, 0)
	SaveSystem.slots.delete(0)
	DirAccess.remove_absolute("user://test_save_system")
	SaveSystem.slots = previous_slots


func test_a_failed_write_isnt_the_last_save() -> void:
	SaveSystem.write_slot(SaveSlots.SLOT_COUNT, SaveData.new())
	assert_null(SaveSystem.last_save)


func test_loading_a_save_makes_it_the_last_and_copies_its_world() -> void:
	var save := SaveData.new()
	save.play_time = 75.0
	save.world.record(&"door", {"is_locked": false})
	SaveSystem.begin_from(save)
	assert_eq(SaveSystem.last_save, save)
	assert_eq(SaveSystem.play_time, 75.0)
	SaveSystem.world.record(&"pickup", {"is_collected": true})
	assert_false(save.world.has_state(&"pickup"))


func test_a_new_game_forgets_the_last_save() -> void:
	SaveSystem.begin_from(SaveData.new())
	SaveSystem.reset()
	assert_null(SaveSystem.last_save)
