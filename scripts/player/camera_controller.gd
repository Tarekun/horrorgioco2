## Over-the-shoulder third-person camera on a SpringArm3D.
##
## The camera orbits with mouse motion or the right stick (look_* actions),
## with configurable sensitivity and pitch limits. Position follows the player
## with light smoothing.
##
## The SpringArm3D has collision enabled so the camera never clips through
## walls or other geometry.
##
## The camera rig is top-level (not a child of the player) so it doesn't
## inherit the player's rotation.
##
## The mouse is captured while the game runs and released with the `pause`
## action; a click captures it again.

class_name CameraController
extends Node3D

## Arm length from the shoulder pivot to the camera.
@export var arm_length: float = 2.2

## Shoulder offset: (right, up) from the player position.
@export var shoulder_offset: Vector2 = Vector2(0.5, 1.6)

## Mouse look sensitivity (degrees per pixel).
@export var mouse_sensitivity: float = 0.1

## Joystick look sensitivity (degrees per second at full tilt).
@export var joystick_sensitivity: float = 120.0

## Inverts vertical look for both mouse and stick.
@export var invert_y: bool = false

## Camera pitch limits in degrees. Positive looks up.
@export var pitch_min: float = -60.0
@export var pitch_max: float = 50.0

## Reference to the player character (for position following).
@export var player: CharacterBody3D

## Reference to the SpringArm3D child node.
@export var spring_arm: SpringArm3D

## Camera follow smoothing time in seconds (how quickly the camera catches up).
@export var follow_smoothing_time: float = 0.1

var _is_mouse_captured: bool = false
var _shake_amplitude: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _camera_pitch: float = 0.0
var _camera_yaw: float = 0.0


func _ready() -> void:
	top_level = true

	if spring_arm:
		spring_arm.spring_length = arm_length
		spring_arm.position = Vector3(shoulder_offset.x, shoulder_offset.y, 0.0)

	if player:
		global_position = player.global_position
		# The arm would otherwise collide with the player's own body.
		if spring_arm:
			spring_arm.add_excluded_object(player.get_rid())

	_set_mouse_captured(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_set_mouse_captured(false)
	elif event is InputEventMouseButton and event.pressed:
		_set_mouse_captured(true)
	elif event is InputEventMouseMotion and _is_mouse_captured:
		_rotate_camera(
			-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity * _y_sign()
		)


func _process(delta: float) -> void:
	var look: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if look != Vector2.ZERO:
		var step: float = joystick_sensitivity * delta
		_rotate_camera(-look.x * step, -look.y * step * _y_sign())

	_follow_player(delta)
	_update_shake(delta)


## Shakes the camera for `duration` seconds, with offsets up to `amplitude`
## metres that fade out. A stronger shake replaces a weaker one in progress.
func shake(amplitude: float, duration: float) -> void:
	if amplitude < _shake_amplitude * (_shake_time_left / maxf(_shake_duration, 0.001)):
		return
	_shake_amplitude = amplitude
	_shake_duration = maxf(duration, 0.001)
	_shake_time_left = _shake_duration


## Offset applied to the camera pivot `time_left` of `duration` seconds into a
## shake: random per axis, fading out linearly. `random_x` and `random_y` are
## in [-1, 1] (injected so tests are deterministic).
static func shake_offset(
	amplitude: float, time_left: float, duration: float, random_x: float, random_y: float
) -> Vector2:
	var falloff: float = clampf(time_left / maxf(duration, 0.001), 0.0, 1.0)
	return Vector2(random_x, random_y) * amplitude * falloff


## Returns the current camera yaw in radians.
func get_camera_yaw() -> float:
	return deg_to_rad(_camera_yaw)


## Returns the current camera pitch in radians.
func get_camera_pitch() -> float:
	return deg_to_rad(_camera_pitch)


## Rotates the camera by the given degrees. Positive pitch looks up.
func _rotate_camera(delta_yaw: float, delta_pitch: float) -> void:
	_camera_yaw = wrapf(_camera_yaw + delta_yaw, -180.0, 180.0)
	_camera_pitch = clampf(_camera_pitch + delta_pitch, pitch_min, pitch_max)

	if spring_arm:
		spring_arm.rotation.y = deg_to_rad(_camera_yaw)
		spring_arm.rotation.x = deg_to_rad(_camera_pitch)


func _set_mouse_captured(is_captured: bool) -> void:
	_is_mouse_captured = is_captured
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if is_captured else Input.MOUSE_MODE_VISIBLE)


func _y_sign() -> float:
	return -1.0 if invert_y else 1.0


func _update_shake(delta: float) -> void:
	if spring_arm == null:
		return
	var base := Vector3(shoulder_offset.x, shoulder_offset.y, 0.0)
	if _shake_time_left <= 0.0:
		spring_arm.position = base
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var offset: Vector2 = shake_offset(
		_shake_amplitude,
		_shake_time_left,
		_shake_duration,
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	spring_arm.position = base + Vector3(offset.x, offset.y, 0.0)


func _follow_player(delta: float) -> void:
	if player == null:
		return

	var t: float = 1.0 - exp(-delta / maxf(follow_smoothing_time, 0.001))
	global_position = global_position.lerp(player.global_position, t)
