## Tests for doors: opening, locking, swing direction and the navigation link.

extends GutTest

const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")

var _door: Door


func before_each() -> void:
	_door = DOOR_SCENE.instantiate() as Door
	_door.swing_time = 0.1
	add_child_autofree(_door)
	await get_tree().process_frame


func _settle() -> void:
	await get_tree().create_timer(0.2).timeout


func test_starts_closed_with_the_link_off() -> void:
	assert_false(_door.is_open)
	assert_false(_door.navigation_link.enabled)
	assert_eq(_door.get_prompt(), "Open")
	assert_true(_door.is_in_group(Interactable.GROUP))


func test_interact_opens_and_closes() -> void:
	var actor := Node3D.new()
	add_child_autofree(actor)
	actor.global_position = Vector3(0, 0, 2)
	watch_signals(_door)
	assert_eq(_door.interact(actor), "")
	assert_true(_door.is_open)
	assert_signal_emitted(_door, "opened")
	assert_eq(_door.get_prompt(), "Close")
	await _settle()
	assert_almost_eq(absf(_door.hinge.rotation.y), deg_to_rad(_door.open_angle), 0.01)
	_door.interact(actor)
	assert_false(_door.is_open)
	assert_signal_emitted(_door, "closed")
	await _settle()
	assert_almost_eq(_door.hinge.rotation.y, 0.0, 0.01)


func test_the_panel_swings_away_from_the_opener() -> void:
	_door.open(Vector3(0, 0, 3))
	await _settle()
	var panel := _door.hinge.get_child(0) as Node3D
	assert_lt(panel.global_position.z, -0.5, "swung to -Z when opened from +Z")
	_door.close()
	await _settle()
	_door.open(Vector3(0, 0, -3))
	await _settle()
	assert_gt(panel.global_position.z, 0.5, "swung to +Z when opened from -Z")


func test_the_link_is_on_only_while_open() -> void:
	_door.open(Vector3(0, 0, 3))
	assert_true(_door.navigation_link.enabled)
	_door.close()
	assert_false(_door.navigation_link.enabled)


func test_a_locked_door_shows_a_message_and_stays_closed() -> void:
	_door.is_locked = true
	watch_signals(_door)
	var actor := Node3D.new()
	add_child_autofree(actor)
	assert_eq(_door.interact(actor), "It's locked.")
	assert_false(_door.is_open)
	assert_false(_door.navigation_link.enabled)
	assert_signal_emitted(_door, "locked_attempted")
	assert_signal_not_emitted(_door, "opened")


func test_unlock_lets_it_open() -> void:
	_door.is_locked = true
	_door.unlock()
	assert_eq(_door.interact(null), "")
	assert_true(_door.is_open)


func test_lock_closes_an_open_door() -> void:
	_door.open(Vector3(0, 0, 3))
	_door.lock()
	assert_false(_door.is_open)
	assert_true(_door.is_locked)


func test_the_closed_panel_blocks_the_doorway() -> void:
	var panel := _door.hinge.get_child(0) as StaticBody3D
	assert_eq(panel.collision_layer & CombatLayers.WORLD, CombatLayers.WORLD)
	var shape := panel.get_child(1) as CollisionShape3D
	assert_almost_eq((shape.shape as BoxShape3D).size.x, 1.4, 0.01)
