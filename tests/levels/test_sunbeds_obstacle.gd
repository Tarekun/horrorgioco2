## Tests for the sunbeds obstacle on its own: pushing it aside, the roll, and
## saving and loading it.

extends GutTest

const OBSTACLE_SCENE: PackedScene = preload("res://scenes/levels/sunbeds_obstacle.tscn")

var _obstacle: SunbedsObstacle
var _actor: Node3D


func before_each() -> void:
	SaveSystem.reset()
	_obstacle = OBSTACLE_SCENE.instantiate() as SunbedsObstacle
	_obstacle.obstacle_id = &"obstacle_test"
	_obstacle.roll_time = 0.2
	add_child_autofree(_obstacle)
	_actor = Node3D.new()
	add_child_autofree(_actor)
	_actor.global_position = Vector3(0, 0, -1)


func after_each() -> void:
	SaveSystem.reset()


func _settle() -> void:
	await get_tree().create_timer(_obstacle.roll_time + 0.2).timeout


func test_is_an_interactable_with_the_doc_prompt() -> void:
	assert_true(_obstacle.is_in_group(Interactable.GROUP))
	assert_eq(_obstacle.get_prompt(), "Push the sunbeds aside.")
	assert_false(_obstacle.is_moved)


func test_the_stack_collides() -> void:
	assert_gt(_obstacle.stack.find_children("*", "StaticBody3D").size(), 0)


func test_pushing_rolls_the_stack_clear() -> void:
	watch_signals(_obstacle)
	var placed: Vector3 = _obstacle.stack.position
	assert_eq(_obstacle.interact(_actor), "")
	assert_true(_obstacle.is_moved)
	assert_signal_emit_count(_obstacle, "moved", 1)
	assert_signal_emitted(_obstacle, "interacted")
	assert_almost_eq(_obstacle.stack.position, placed, Vector3.ONE * 0.01, "not there at once")
	await _settle()
	assert_almost_eq(
		_obstacle.stack.position, placed + _obstacle.roll_offset, Vector3.ONE * 0.01, "rolled clear"
	)


func test_once_moved_it_is_out_of_reach() -> void:
	_obstacle.interact(_actor)
	assert_false(_obstacle.is_in_group(Interactable.GROUP))


func test_pushing_again_does_nothing() -> void:
	watch_signals(_obstacle)
	_obstacle.interact(_actor)
	_obstacle.interact(_actor)
	assert_signal_emit_count(_obstacle, "moved", 1)


func test_it_wont_roll_onto_someone_in_its_path() -> void:
	watch_signals(_obstacle)
	# Behind the stack, where it rolls to.
	_actor.global_position = _obstacle.to_global(_obstacle.moved_position())
	assert_true(_obstacle.is_in_the_way(_actor.global_position))
	assert_eq(_obstacle.interact(_actor), SunbedsObstacle.IN_THE_WAY_MESSAGE)
	assert_false(_obstacle.is_moved)
	assert_signal_not_emitted(_obstacle, "moved")
	assert_false(SaveSystem.world.has_state(&"obstacle_test"))


func test_pushing_from_against_its_front_is_not_in_the_way() -> void:
	# Pressed against the stack's front (it is 0.75 m deep; a player 0.7 m wide).
	assert_false(_obstacle.is_in_the_way(_obstacle.to_global(Vector3(0, 0, -0.75))))
	# Beside it, on the side it rolls away from (it rolls toward +X here).
	assert_false(_obstacle.is_in_the_way(_obstacle.to_global(Vector3(-1.4, 0, 0))))


func test_is_persistent() -> void:
	assert_true(_obstacle.is_in_group(WorldState.GROUP))
	assert_eq(_obstacle.get_persistent_id(), &"obstacle_test")


func test_pushing_is_recorded() -> void:
	_obstacle.interact(_actor)
	assert_eq(SaveSystem.world.get_state(&"obstacle_test"), {"is_moved": true})


func test_left_alone_it_records_nothing() -> void:
	assert_false(SaveSystem.world.has_state(&"obstacle_test"))


func test_loading_a_moved_state_puts_it_there_at_once() -> void:
	watch_signals(_obstacle)
	_obstacle.load_state({"is_moved": true})
	assert_true(_obstacle.is_moved)
	assert_almost_eq(_obstacle.stack.position, _obstacle.moved_position(), Vector3.ONE * 0.001)
	assert_false(_obstacle.is_in_group(Interactable.GROUP))
	assert_signal_not_emitted(_obstacle, "moved")


func test_loading_another_state_leaves_it() -> void:
	_obstacle.load_state({})
	_obstacle.load_state({"is_moved": "yes"})
	assert_false(_obstacle.is_moved)
	assert_true(_obstacle.is_in_group(Interactable.GROUP))
