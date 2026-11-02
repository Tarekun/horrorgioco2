## Tests for the double door: two leaves that open and close together, to the
## same side, in a standard doorway.

extends GutTest

const DOUBLE_DOOR_SCENE: PackedScene = preload("res://scenes/levels/double_door.tscn")

var _door: Door


func before_each() -> void:
	_door = DOUBLE_DOOR_SCENE.instantiate() as Door
	_door.swing_time = 0.1
	add_child_autofree(_door)
	await get_tree().process_frame


func after_each() -> void:
	SaveSystem.reset()


func _settle() -> void:
	await get_tree().create_timer(0.2).timeout


func _first_leaf() -> StaticBody3D:
	return _door.hinge.get_node("Panel") as StaticBody3D


func _second_leaf() -> StaticBody3D:
	return _door.second_hinge.get_node("Panel") as StaticBody3D


func _leaf_width(leaf: StaticBody3D) -> float:
	return ((leaf.get_node("Shape") as CollisionShape3D).shape as BoxShape3D).size.x


func test_is_a_door_with_two_leaves() -> void:
	assert_not_null(_door.second_hinge)
	assert_false(_door.is_open)
	assert_false(_door.navigation_link.enabled)
	assert_eq(_first_leaf().collision_layer & CombatLayers.WORLD, CombatLayers.WORLD)
	assert_eq(_second_leaf().collision_layer & CombatLayers.WORLD, CombatLayers.WORLD)


func test_closed_the_leaves_fill_a_standard_doorway() -> void:
	# The kit's door_frame clears 1.4 m, the width of a single door.
	assert_almost_eq(_leaf_width(_first_leaf()) + _leaf_width(_second_leaf()), 1.4, 0.01)
	assert_almost_eq(_first_leaf().global_position.x, -0.35, 0.01)
	assert_almost_eq(_second_leaf().global_position.x, 0.35, 0.01)
	assert_almost_eq(_first_leaf().global_position.z, 0.0, 0.01)
	assert_almost_eq(_second_leaf().global_position.z, 0.0, 0.01)


func test_both_leaves_open_together_away_from_the_opener() -> void:
	watch_signals(_door)
	_door.open(Vector3(0, 0, 3))
	assert_true(_door.navigation_link.enabled)
	assert_signal_emit_count(_door, "opened", 1)
	await _settle()
	assert_lt(_first_leaf().global_position.z, -0.3, "first leaf swung to -Z")
	assert_lt(_second_leaf().global_position.z, -0.3, "second leaf swung to -Z")
	assert_almost_eq(
		_door.second_hinge.rotation.y, -_door.hinge.rotation.y, 0.01, "mirrored swings"
	)
	_door.close()
	await _settle()
	_door.open(Vector3(0, 0, -3))
	await _settle()
	assert_gt(_first_leaf().global_position.z, 0.3, "first leaf swung to +Z")
	assert_gt(_second_leaf().global_position.z, 0.3, "second leaf swung to +Z")


func test_both_leaves_close_together() -> void:
	_door.open(Vector3(0, 0, 3))
	await _settle()
	_door.close()
	assert_false(_door.navigation_link.enabled)
	await _settle()
	assert_almost_eq(_door.hinge.rotation.y, 0.0, 0.01)
	assert_almost_eq(_door.second_hinge.rotation.y, 0.0, 0.01)


func test_the_open_leaves_clear_the_doorway() -> void:
	_door.open(Vector3(0, 0, 3))
	await _settle()
	var space: PhysicsDirectSpaceState3D = _door.get_world_3d().direct_space_state
	var through := PhysicsRayQueryParameters3D.create(
		Vector3(0, 1.2, 2), Vector3(0, 1.2, -2), CombatLayers.WORLD
	)
	assert_true(space.intersect_ray(through).is_empty())
	_door.close()
	await _settle()
	assert_false(space.intersect_ray(through).is_empty())


func test_a_double_door_can_start_open() -> void:
	var door := DOUBLE_DOOR_SCENE.instantiate() as Door
	door.starts_open = true
	add_child_autofree(door)
	assert_true(door.is_open)
	assert_gt((door.hinge.get_node("Panel") as Node3D).global_position.z, 0.3)
	assert_gt((door.second_hinge.get_node("Panel") as Node3D).global_position.z, 0.3)
