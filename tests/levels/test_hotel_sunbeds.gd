## Tests for the sunbeds against the ground floor's stairs door in the hotel
## (docs/design/slice.md, "The obstacle"): both sides of the door, pushing the
## stack aside, loading, and the navmesh.

extends "res://tests/levels/hotel_level_test.gd"

const OBSTACLE_PATH: String = "Doors/GroundFloor/ObstacleSunbeds"
const BLOCKED_MESSAGE: String = "Something heavy on the other side."
## Where the player stands on either side of the stairs door.
const STAIRS_SIDE := Vector3(3, GROUND_Y, 1.8)
const CORRIDOR_SIDE := Vector3(3, GROUND_Y, -0.45)
## Further along the corridor, and on the stairs landing.
const CORRIDOR := Vector3(8, GROUND_Y, -0.3)
const LANDING := Vector3(1.5, GROUND_Y, 2)


func before_each() -> void:
	SaveSystem.reset()
	await super()


func after_each() -> void:
	super()
	SaveSystem.reset()


func _obstacle(level: Node = _level) -> SunbedsObstacle:
	return level.get_node(OBSTACLE_PATH) as SunbedsObstacle


func _player(level: Node = _level) -> Player:
	return level.get_node("Player") as Player


## Puts the level's player at `at`, facing `facing`, and returns what it can use.
func _stand(at: Vector3, facing: Vector3, level: Node = _level) -> Interactable:
	var player: Player = _player(level)
	player.global_position = at
	# Godot forward is -Z.
	player.rotation.y = atan2(-facing.x, -facing.z)
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	return interaction.focus


func _push_aside() -> void:
	var obstacle: SunbedsObstacle = _obstacle()
	_stand(CORRIDOR_SIDE, Vector3.BACK).interact(_player())
	await get_tree().create_timer(obstacle.roll_time + 0.3).timeout


func test_the_obstacle_has_its_doc_id() -> void:
	assert_eq(_obstacle().get_persistent_id(), &"obstacle_sunbeds")
	assert_false(_obstacle().is_moved)


func test_from_the_stairs_side_something_heavy_holds_the_door() -> void:
	var door: Door = _door(&"door_stairs_gf")
	var focus: Interactable = _stand(STAIRS_SIDE, Vector3.FORWARD)
	assert_eq(focus, door as Interactable, "the player on the stairs reaches the door")
	assert_eq(focus.interact(_player()), BLOCKED_MESSAGE)
	assert_true(door.is_locked)
	assert_false(door.is_open)


func test_from_the_corridor_the_sunbeds_are_pushed_aside() -> void:
	var obstacle: SunbedsObstacle = _obstacle()
	var focus: Interactable = _stand(CORRIDOR_SIDE, Vector3.BACK)
	assert_eq(focus, obstacle as Interactable, "the player in the corridor reaches the sunbeds")
	assert_eq(focus.get_prompt(), "Push the sunbeds aside.")
	assert_eq(focus.interact(_player()), "")
	assert_true(obstacle.is_moved)
	assert_false(_door(&"door_stairs_gf").is_locked, "pushing them unlocks the door")
	await get_tree().create_timer(obstacle.roll_time + 0.3).timeout
	var stack: Vector3 = obstacle.stack.global_position
	assert_almost_eq(stack, obstacle.to_global(obstacle.moved_position()), Vector3.ONE * 0.01)
	# Clear of the doorway (x 2.3..3.7), in the corridor's west end.
	assert_lt(stack.x + 1.0, 2.3, "clear of the doorway")
	assert_gt(stack.x - 1.0, 0.1, "inside the corridor")


func test_from_the_dead_end_behind_the_stack_it_wont_roll() -> void:
	var obstacle: SunbedsObstacle = _obstacle()
	# Squeezed past the stack into the corridor's west end, facing it.
	var focus: Interactable = _stand(Vector3(1.6, GROUND_Y, 0.4), Vector3.RIGHT)
	assert_eq(focus, obstacle as Interactable)
	assert_eq(focus.interact(_player()), SunbedsObstacle.IN_THE_WAY_MESSAGE)
	assert_false(obstacle.is_moved)
	assert_true(_door(&"door_stairs_gf").is_locked)


func test_once_pushed_the_door_works_from_both_sides() -> void:
	await _push_aside()
	var door: Door = _door(&"door_stairs_gf")
	var focus: Interactable = _stand(CORRIDOR_SIDE, Vector3.BACK)
	assert_eq(focus, door as Interactable, "the corridor side reaches the door now")
	assert_eq(focus.interact(_player()), "")
	assert_true(door.is_open, "opened from the corridor")
	door.close()
	focus = _stand(STAIRS_SIDE, Vector3.FORWARD)
	assert_eq(focus, door as Interactable)
	assert_eq(focus.interact(_player()), "")
	assert_true(door.is_open, "opened from the stairs")


func test_after_loading_the_stack_stays_moved_and_the_door_works() -> void:
	await _push_aside()
	var world: WorldState = SaveSystem.world.copy()
	assert_true(world.has_state(&"obstacle_sunbeds"))
	assert_true(world.has_state(&"door_stairs_gf"))
	# Loading instances the level fresh and hands it the saved world.
	_level.free()
	var loaded := LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(loaded)
	world.apply(loaded)
	var obstacle: SunbedsObstacle = _obstacle(loaded)
	assert_true(obstacle.is_moved)
	assert_almost_eq(obstacle.stack.position, obstacle.moved_position(), Vector3.ONE * 0.001)
	var door: Door = loaded.get_node("Doors/GroundFloor/DoorStairsGF") as Door
	assert_false(door.is_locked)
	var focus: Interactable = _stand(STAIRS_SIDE, Vector3.FORWARD, loaded)
	assert_eq(focus, door as Interactable, "the stack is out of reach after loading")
	assert_eq(focus.interact(_player(loaded)), "")
	assert_true(door.is_open)


func test_loading_a_save_made_before_pushing_keeps_the_stack_in_place() -> void:
	var world: WorldState = SaveSystem.world.copy()
	await _push_aside()
	_level.free()
	var loaded := LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(loaded)
	world.apply(loaded)
	assert_false(_obstacle(loaded).is_moved)
	assert_true((loaded.get_node("Doors/GroundFloor/DoorStairsGF") as Door).is_locked)
	var focus: Interactable = _stand(CORRIDOR_SIDE, Vector3.BACK, loaded)
	assert_eq(focus, _obstacle(loaded) as Interactable, "the sunbeds can be pushed again")


func test_the_stairs_stay_shut_off_until_the_stack_is_moved() -> void:
	assert_gt(_path_length(CORRIDOR, CORRIDOR_SIDE), 0.0, "in front of the stack")
	assert_eq(_path_length(CORRIDOR, LANDING), -1.0, "stack in place")
	await _push_aside()
	await _open(&"door_stairs_gf")
	assert_gt(_path_length(CORRIDOR, LANDING), 0.0, "stack moved, door open")


func test_the_navmesh_leaves_out_the_moved_stack() -> void:
	await _push_aside()
	var stack: Vector3 = _obstacle().stack.global_position
	assert_gt(_distance_from_floor(stack), 0.5, "nothing walkable under the stack")
	assert_lt(_distance_from_floor(CORRIDOR_SIDE), 0.2, "the doorway's corridor side is walkable")
