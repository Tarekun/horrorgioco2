## Tests for the SaveSystem autoload.

extends GutTest


func after_each() -> void:
	SaveSystem.reset()


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
