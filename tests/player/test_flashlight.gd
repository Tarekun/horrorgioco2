## Tests for the Flashlight: scene wiring, toggling, and lag behind the camera.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _flashlight: Flashlight
var _camera: Camera3D


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_camera = _player.get_node("CameraController/SpringArm3D/Camera3D") as Camera3D
	_flashlight = _camera.get_node("Flashlight") as Flashlight


func _press_flashlight() -> void:
	var event := InputEventAction.new()
	event.action = &"flashlight"
	event.pressed = true
	_flashlight._unhandled_input(event)


# --- Wiring ---


func test_flashlight_is_a_shadowed_spotlight_under_the_camera() -> void:
	assert_not_null(_flashlight, "flashlight under the camera")
	assert_not_null(_flashlight.light, "light reference assigned")
	assert_true(_flashlight.light is SpotLight3D)
	assert_true(_flashlight.light.shadow_enabled, "casts shadows")


func test_flashlight_starts_on() -> void:
	assert_true(_flashlight.is_on())


# --- Toggle ---


func test_flashlight_action_toggles_the_light() -> void:
	_press_flashlight()
	assert_false(_flashlight.is_on())
	assert_false(_flashlight.light.visible)
	_press_flashlight()
	assert_true(_flashlight.is_on())


func test_other_actions_do_not_toggle() -> void:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	_flashlight._unhandled_input(event)
	assert_true(_flashlight.is_on())


func test_toggled_signal_is_the_sound_hook() -> void:
	watch_signals(_flashlight)
	_flashlight.toggle()
	assert_signal_emitted_with_parameters(_flashlight, "toggled", [false])
	_flashlight.toggle()
	assert_signal_emitted_with_parameters(_flashlight, "toggled", [true])
	assert_signal_emit_count(_flashlight, "toggled", 2)


func test_set_on_to_current_state_emits_nothing() -> void:
	watch_signals(_flashlight)
	_flashlight.set_on(true)
	assert_signal_not_emitted(_flashlight, "toggled")


# --- Follow, lag and sway ---


func test_beam_lags_the_camera_then_catches_up() -> void:
	_camera.get_parent().rotation.y += 1.0
	_flashlight._process(1.0 / 60.0)
	var angle: float = _flashlight.global_basis.get_rotation_quaternion().angle_to(
		_camera.global_basis.get_rotation_quaternion()
	)
	assert_gt(angle, 0.5, "still behind after one frame")
	assert_lt(angle, 1.0 + 0.1, "but already moving")

	for i: int in 180:
		_flashlight._process(1.0 / 60.0)
	angle = _flashlight.global_basis.get_rotation_quaternion().angle_to(
		_camera.global_basis.get_rotation_quaternion()
	)
	assert_lt(angle, deg_to_rad(_flashlight.sway_amplitude) * 3.0, "settles on the aim")


func test_lagged_basis_moves_part_way() -> void:
	var target := Basis(Vector3.UP, 1.0)
	var result: Basis = Flashlight.lagged_basis(Basis.IDENTITY, target, 9.0, 0.05)
	var angle: float = result.get_rotation_quaternion().angle_to(target.get_rotation_quaternion())
	assert_gt(angle, 0.0)
	assert_lt(angle, 1.0)


func test_sway_is_bounded_and_varies() -> void:
	var amplitude: float = 0.01
	var first: Vector3 = Flashlight.sway_offset(0.0, amplitude, 1.7)
	var later: Vector3 = Flashlight.sway_offset(1.0, amplitude, 1.7)
	assert_ne(first, later)
	for t: float in [0.0, 0.5, 1.0, 2.0, 5.0]:
		var offset: Vector3 = Flashlight.sway_offset(t, amplitude, 1.7)
		assert_lte(absf(offset.x), amplitude)
		assert_lte(absf(offset.y), amplitude)
