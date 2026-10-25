## Tests for the camera shake used by the hit reaction.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_offset_fades_out_linearly() -> void:
	var full: Vector2 = CameraController.shake_offset(0.1, 1.0, 1.0, 1.0, -1.0)
	assert_almost_eq(full, Vector2(0.1, -0.1), Vector2.ONE * 0.0001)
	var half: Vector2 = CameraController.shake_offset(0.1, 0.5, 1.0, 1.0, 1.0)
	assert_almost_eq(half, Vector2(0.05, 0.05), Vector2.ONE * 0.0001)
	assert_eq(CameraController.shake_offset(0.1, 0.0, 1.0, 1.0, 1.0), Vector2.ZERO)


func test_shake_moves_the_rig_and_settles() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	var camera: CameraController = player.camera_controller
	var arm: SpringArm3D = camera.spring_arm
	var rest: Vector3 = Vector3(camera.shoulder_offset.x, camera.shoulder_offset.y, 0.0)
	await get_tree().process_frame
	assert_eq(arm.position, rest)

	camera.shake(0.2, 0.2)
	var moved: bool = false
	for i: int in 5:
		await get_tree().process_frame
		moved = moved or not arm.position.is_equal_approx(rest)
	assert_true(moved)

	await get_tree().create_timer(0.4).timeout
	await get_tree().process_frame
	assert_almost_eq(arm.position, rest, Vector3.ONE * 0.0001)
