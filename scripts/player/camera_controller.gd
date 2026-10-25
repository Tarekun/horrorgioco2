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
var _camera_pitch: float = 0.0
var _camera_yaw: float = 0.0
var _previous_player_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	top_level = true

	if spring_arm:
		spring_arm.spring_length = arm_length
		spring_arm.position = Vector3(shoulder_offset.x, shoulder_offset.y, 0.0)

	if player:
		position = player.position
		# The arm would otherwise collide with the player's own body.
		if spring_arm:
			spring_arm.add_excluded_object(player.get_rid())

	_set_mouse_captured(true)

	## Enable collision on the spring arm to prevent wall clipping.
	if _spring_arm != null:
		_spring_arm.collide_with_enemies = false
		_spring_arm.collide_with_areas = false
		_spring_arm.collide_with_bodies = true
		_spring_arm.collide_with_skeletons = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_set_mouse_captured(false)
	elif event is InputEventMouseButton and event.pressed:
		_set_mouse_captured(true)
	elif event is InputEventMouseMotion and _is_mouse_captured:
		_rotate_camera(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)


func _process(delta: float) -> void:
	var look: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if look != Vector2.ZERO:
		var step: float = joystick_sensitivity * delta
		_rotate_camera(-look.x * step, -look.y * step)

	_follow_player(delta)


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


func _follow_player(delta: float) -> void:
	if player == null:
		return

	var t: float = 1.0 - exp(-delta / maxf(follow_smoothing_time, 0.001))
	position = position.lerp(player.position, t)
