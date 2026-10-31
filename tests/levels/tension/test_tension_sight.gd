## Tests for TensionSight: the target has to be close, in front of the camera and
## not behind a wall.

extends GutTest

var _sight: TensionSight
var _target: Marker3D


func before_each() -> void:
	var world := Node3D.new()
	add_child_autofree(world)
	_target = Marker3D.new()
	_target.position = Vector3(0, 1, -5)
	world.add_child(_target)
	_sight = TensionSight.new()
	_sight.target = _target
	_sight.max_distance = 8.0
	_sight.view_angle = 30.0
	world.add_child(_sight)


func test_is_in_view_needs_range_and_angle() -> void:
	var eye := Vector3(0, 1, 0)
	assert_true(TensionSight.is_in_view(eye, Vector3.FORWARD, Vector3(0, 1, -5), 8.0, 30.0))
	assert_false(
		TensionSight.is_in_view(eye, Vector3.FORWARD, Vector3(0, 1, -9), 8.0, 30.0), "too far"
	)
	assert_false(
		TensionSight.is_in_view(eye, Vector3.FORWARD, Vector3(5, 1, -5), 8.0, 30.0),
		"45 degrees off"
	)
	assert_false(TensionSight.is_in_view(eye, Vector3.BACK, Vector3(0, 1, -5), 8.0, 30.0), "behind")


func test_sees_the_target_in_the_open() -> void:
	await wait_physics_frames(1)
	assert_true(_sight.sees(_eye_looking(Vector3.FORWARD)))
	assert_false(_sight.sees(_eye_looking(Vector3.LEFT)), "looking away")


func test_a_wall_hides_the_target() -> void:
	_add_box(Vector3(0, 1, -2.5), Vector3(3, 3, 0.2))
	await wait_physics_frames(2)
	assert_false(_sight.sees(_eye_looking(Vector3.FORWARD)))


func test_the_targets_own_collider_does_not_hide_it() -> void:
	_sight.target_radius = 0.4
	_add_box(Vector3(0, 1, -5), Vector3(0.5, 0.5, 0.5))
	await wait_physics_frames(2)
	assert_true(_sight.sees(_eye_looking(Vector3.FORWARD)))


func test_it_looks_only_while_the_player_is_in_its_area() -> void:
	var player := Player.new()
	autofree(player)
	assert_false(_sight.is_physics_processing())
	_sight.body_entered.emit(player)
	assert_true(_sight.is_physics_processing())
	_sight.body_exited.emit(player)
	assert_false(_sight.is_physics_processing())


func _eye_looking(direction: Vector3) -> Transform3D:
	var eye := Transform3D(Basis.IDENTITY, Vector3(0, 1, 0))
	return eye.looking_at(eye.origin + direction)


func _add_box(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_sight.get_parent().add_child(body)
