## Tests for self-closing doors: they shut by themselves a set time after
## opening, once nobody stands where the panel swings.

extends GutTest

const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")

var _door: Door


func before_each() -> void:
	_door = DOOR_SCENE.instantiate() as Door
	_door.swing_time = 0.1
	add_child_autofree(_door)
	await get_tree().process_frame


func test_a_door_is_not_self_closing_by_default() -> void:
	assert_false(_door.is_self_closing)
	assert_false(_door.doorway.monitoring)
	_door.open(Vector3(0, 0, 3))
	await get_tree().create_timer(_door.close_delay + 0.3).timeout
	assert_true(_door.is_open)


func test_the_self_closing_rule() -> void:
	assert_false(Door.should_close_by_itself(0.5, 1.0, true), "too soon")
	assert_false(Door.should_close_by_itself(2.0, 1.0, false), "someone in the doorway")
	assert_true(Door.should_close_by_itself(1.0, 1.0, true))


func test_a_self_closing_door_shuts_after_its_delay() -> void:
	var door: Door = _self_closing_door()
	await get_tree().physics_frame
	watch_signals(door)
	door.open(Vector3(0, 0, 3))
	await get_tree().create_timer(door.close_delay * 0.5).timeout
	assert_true(door.is_open, "still open before the delay")
	await get_tree().create_timer(door.close_delay).timeout
	assert_false(door.is_open)
	assert_false(door.navigation_link.enabled)
	assert_signal_emitted(door, "closed")


func test_a_self_closing_door_waits_for_its_doorway_to_clear() -> void:
	var door: Door = _self_closing_door()
	# Opened from +Z, it swings to -Z: someone stands where the panel goes.
	var body: CharacterBody3D = _body(CombatLayers.ENEMY, Vector3(0, 0, -0.8))
	door.open(Vector3(0, 0, 3))
	await get_tree().create_timer(door.close_delay + 0.3).timeout
	assert_true(door.is_open, "kept open while someone stands in the doorway")
	body.global_position = Vector3(0, 0, -4)
	await get_tree().create_timer(0.2).timeout
	assert_false(door.is_open, "shut once the doorway is clear")


func test_the_player_holds_a_self_closing_door_too() -> void:
	var door: Door = _self_closing_door()
	_body(CombatLayers.PLAYER, Vector3(0, 0, -0.5))
	door.open(Vector3(0, 0, 3))
	await get_tree().create_timer(door.close_delay + 0.3).timeout
	assert_true(door.is_open)


func test_someone_behind_the_opener_does_not_hold_it() -> void:
	# Opened from +Z, the panel sweeps -Z: a chaser on the +Z side doesn't stop it.
	var door: Door = _self_closing_door()
	_body(CombatLayers.ENEMY, Vector3(0, 0, 1.0))
	door.open(Vector3(0, 0, 3))
	await get_tree().create_timer(door.close_delay + 0.3).timeout
	assert_false(door.is_open)


func test_the_doorway_follows_the_swing() -> void:
	_door.open(Vector3(0, 0, 3))
	assert_lt(_door.doorway.position.z, 0.0, "panel swings to -Z")
	_door.close()
	_door.open(Vector3(0, 0, -3))
	assert_gt(_door.doorway.position.z, 0.0, "panel swings to +Z")


## A self-closing door in the tree, with a short swing.
func _self_closing_door() -> Door:
	var door := DOOR_SCENE.instantiate() as Door
	door.is_self_closing = true
	door.close_delay = 0.5
	door.swing_time = 0.1
	add_child_autofree(door)
	return door


## A capsule body on `layer`, standing at `at`.
func _body(layer: int, at: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = at
	return body
