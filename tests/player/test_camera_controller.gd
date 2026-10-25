## Tests for CameraController: look limits, directions, arm setup and following.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _camera: CameraController


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_camera = _player.get_node("CameraController") as CameraController


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _mouse_motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	_camera._unhandled_input(event)


func test_arm_length_and_shoulder_offset_are_applied() -> void:
	assert_almost_eq(_camera.spring_arm.spring_length, _camera.arm_length, 0.001)
	assert_eq(_camera.spring_arm.position, Vector3(0.5, 1.6, 0.0))


func test_mouse_right_turns_view_right() -> void:
	_mouse_motion(Vector2(100.0, 0.0))
	# Looking right from -Z means the view direction gains +X.
	var view: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, _camera.get_camera_yaw())
	assert_gt(view.x, 0.0)


func test_mouse_up_looks_up() -> void:
	_mouse_motion(Vector2(0.0, -100.0))
	assert_gt(_camera.get_camera_pitch(), 0.0)


func test_pitch_is_clamped() -> void:
	_mouse_motion(Vector2(0.0, -100000.0))
	assert_almost_eq(_camera.get_camera_pitch(), deg_to_rad(_camera.pitch_max), 0.001)
	_mouse_motion(Vector2(0.0, 100000.0))
	assert_almost_eq(_camera.get_camera_pitch(), deg_to_rad(_camera.pitch_min), 0.001)


func test_camera_view_matches_movement_forward() -> void:
	# Movement "forward" must be where the camera actually looks, at any yaw.
	for yaw_px: float in [0.0, 150.0, -420.0, 900.0]:
		_mouse_motion(Vector2(yaw_px, 0.0))
		var view: Vector3 = -_camera.spring_arm.global_transform.basis.z
		view.y = 0.0
		var forward: Vector3 = Player.camera_relative_direction(
			Vector2(0.0, -1.0), _camera.get_camera_yaw()
		)
		assert_almost_eq(view.normalized(), forward, Vector3.ONE * 0.001, "yaw px %f" % yaw_px)


func test_mouse_is_ignored_when_not_captured() -> void:
	var pause := InputEventAction.new()
	pause.action = &"pause"
	pause.pressed = true
	_camera._unhandled_input(pause)
	_mouse_motion(Vector2(100.0, 100.0))
	assert_eq(_camera.get_camera_yaw(), 0.0)

	# A click captures the mouse again.
	var click := InputEventMouseButton.new()
	click.pressed = true
	_camera._unhandled_input(click)
	_mouse_motion(Vector2(100.0, 0.0))
	assert_ne(_camera.get_camera_yaw(), 0.0)


func test_rig_is_top_level_and_does_not_inherit_player_rotation() -> void:
	_player.rotation.y = 1.0
	assert_true(_camera.top_level)
	assert_almost_eq(_camera.global_rotation.y, 0.0, 0.001)


func test_follows_player_position() -> void:
	_player.position = Vector3(10.0, 0.0, 0.0)
	for i: int in 60:
		_camera._process(1.0 / 60.0)
	assert_almost_eq(_camera.position.x, 10.0, 0.05)


func test_invert_y_flips_vertical_look() -> void:
	_camera.invert_y = true
	_mouse_motion(Vector2(0.0, -100.0))
	assert_lt(_camera.get_camera_pitch(), 0.0, "mouse up now looks down")


func test_follow_is_smoothed_not_instant() -> void:
	_player.position = Vector3(10.0, 0.0, 0.0)
	_camera._process(1.0 / 60.0)
	assert_gt(_camera.position.x, 0.0, "starts moving")
	assert_lt(_camera.position.x, 10.0, "lags behind the player")


func test_follow_uses_global_position() -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0.0, 0.0, 50.0)
	add_child_autofree(holder)
	var player := PLAYER_SCENE.instantiate() as Player
	holder.add_child(player)
	var camera := player.get_node("CameraController") as CameraController
	for i: int in 120:
		camera._process(1.0 / 60.0)
	assert_almost_eq(camera.global_position.z, 50.0, 0.05)


func test_spring_arm_shortens_against_a_wall() -> void:
	# A wall just behind the player (the arm extends along +Z at yaw 0).
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 0.0, 1.5)
	add_child_autofree(wall)

	for i: int in 5:
		await get_tree().physics_frame
	assert_lt(_camera.spring_arm.get_hit_length(), _camera.arm_length - 0.5, "arm pulled in")
	assert_gt(_camera.spring_arm.get_hit_length(), 0.0)
