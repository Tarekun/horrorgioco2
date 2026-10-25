## Tests for Player: the camera-relative direction math, and scene-level
## behavior (wiring, movement, sprint, steps) with the real player scene.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player


func after_each() -> void:
	Input.action_release(&"move_forward")
	Input.action_release(&"sprint")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Adds a wide floor, and a player standing on it.
func _spawn_player() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)


func _add_step(height: float, z: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, height, 10.0)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0.0, height / 2.0, z - 5.0)
	add_child_autofree(body)


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


# --- Direction math ---


func test_forward_at_yaw_zero_is_minus_z() -> void:
	var dir: Vector3 = Player.camera_relative_direction(Vector2(0.0, -1.0), 0.0)
	assert_almost_eq(dir, Vector3.FORWARD, Vector3.ONE * 0.001)


func test_right_at_yaw_zero_is_plus_x() -> void:
	var dir: Vector3 = Player.camera_relative_direction(Vector2(1.0, 0.0), 0.0)
	assert_almost_eq(dir, Vector3.RIGHT, Vector3.ONE * 0.001)


func test_backward_at_yaw_zero_is_plus_z() -> void:
	var dir: Vector3 = Player.camera_relative_direction(Vector2(0.0, 1.0), 0.0)
	assert_almost_eq(dir, Vector3.BACK, Vector3.ONE * 0.001)


func test_forward_follows_godot_yaw_rotation() -> void:
	# Whatever the yaw, "forward" must equal -Z rotated by that yaw about +Y,
	# which is how the camera's spring arm is oriented.
	for angle_deg: int in range(0, 360, 15):
		var yaw: float = deg_to_rad(angle_deg)
		var expected: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, yaw)
		var dir: Vector3 = Player.camera_relative_direction(Vector2(0.0, -1.0), yaw)
		assert_almost_eq(dir, expected, Vector3.ONE * 0.001, "yaw %d" % angle_deg)


func test_right_follows_godot_yaw_rotation() -> void:
	for angle_deg: int in range(0, 360, 15):
		var yaw: float = deg_to_rad(angle_deg)
		var expected: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, yaw)
		var dir: Vector3 = Player.camera_relative_direction(Vector2(1.0, 0.0), yaw)
		assert_almost_eq(dir, expected, Vector3.ONE * 0.001, "yaw %d" % angle_deg)


func test_diagonal_is_normalized() -> void:
	var dir: Vector3 = Player.camera_relative_direction(Vector2(1.0, -1.0), 0.7)
	assert_almost_eq(dir.length(), 1.0, 0.001)


func test_zero_input_gives_zero_direction() -> void:
	assert_eq(Player.camera_relative_direction(Vector2.ZERO, 1.0), Vector3.ZERO)


# --- Scene wiring ---


func test_scene_references_are_wired() -> void:
	_spawn_player()
	var camera := _player.get_node("CameraController") as CameraController
	assert_not_null(_player.camera_controller, "player -> camera")
	assert_not_null(_player.stamina_component, "player -> stamina")
	assert_eq(camera.player, _player, "camera -> player")
	assert_not_null(camera.spring_arm, "camera -> spring arm")
	assert_not_null(_player.get_node("CollisionShape3D").shape, "collision shape")


# --- Movement ---


func test_idle_player_stays_put() -> void:
	_spawn_player()
	await _physics_frames(30)
	assert_almost_eq(_player.global_position.x, 0.0, 0.01)
	assert_almost_eq(_player.global_position.z, 0.0, 0.01)


func test_forward_input_moves_along_camera_forward() -> void:
	_spawn_player()
	await _physics_frames(5)
	Input.action_press(&"move_forward")
	await _physics_frames(60)
	assert_lt(_player.global_position.z, -1.0, "moved toward -Z")
	assert_almost_eq(_player.global_position.x, 0.0, 0.05)
	assert_almost_eq(_player.get_current_speed(), _player.run_speed, 0.001)


func test_sprint_is_faster_and_drains_stamina() -> void:
	_spawn_player()
	await _physics_frames(5)
	Input.action_press(&"move_forward")
	Input.action_press(&"sprint")
	await _physics_frames(60)
	assert_almost_eq(_player.get_current_speed(), _player.sprint_speed, 0.001)
	assert_lt(_player.stamina_component.current_stamina, 100.0, "stamina drained")


func test_sprint_without_movement_does_not_drain() -> void:
	_spawn_player()
	Input.action_press(&"sprint")
	await _physics_frames(60)
	assert_eq(_player.stamina_component.current_stamina, 100.0)


func test_blocked_sprint_does_not_drain() -> void:
	_spawn_player()
	_add_step(2.0, -1.0)
	await _physics_frames(5)
	Input.action_press(&"move_forward")
	Input.action_press(&"sprint")
	await _physics_frames(90)
	assert_gt(_player.stamina_component.current_stamina, 95.0, "wall doesn't burn stamina")


# --- Steps ---


func test_climbs_a_low_step() -> void:
	_spawn_player()
	_add_step(0.3, -1.0)
	await _physics_frames(5)
	Input.action_press(&"move_forward")
	await _physics_frames(90)
	assert_lt(_player.global_position.z, -1.5, "got past the step")
	assert_almost_eq(_player.global_position.y, 0.3, 0.05, "standing on the step")


func test_is_blocked_by_a_high_wall() -> void:
	_spawn_player()
	_add_step(1.0, -1.0)
	await _physics_frames(5)
	Input.action_press(&"move_forward")
	await _physics_frames(90)
	assert_gt(_player.global_position.z, -1.0, "stopped at the wall")
	assert_almost_eq(_player.global_position.y, 0.0, 0.05)
