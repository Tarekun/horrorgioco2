## Over-the-shoulder third-person camera on a SpringArm3D.
##
## The camera orbits with mouse motion or the right stick (look_* actions),
## with configurable sensitivity and pitch limits. Position follows the player
## with light smoothing.
##
## The SpringArm3D has collision enabled so the camera never clips through
## walls or other geometry.

class_name CameraController
extends Node3D

## Arm length from the shoulder pivot to the camera.
@export var arm_length: float = 2.2

## Shoulder offset: (right, up) from the player position.
@export var shoulder_offset: Vector2 = Vector2(0.5, 1.6)

## Mouse look sensitivity (degrees per pixel).
@export var mouse_sensitivity: float = 0.3

## Joystick look sensitivity (degrees per axis unit).
@export var joystick_sensitivity: float = 25.0

## Camera pitch limits in degrees.
@export var pitch_min: float = -60.0
@export var pitch_max: float = 50.0

## Reference to the player character (for position following).
@export_node_path var player_path: NodePath

## Reference to the SpringArm3D child node.
@export_node_path var spring_arm_path: NodePath

## Camera follow smoothing time in seconds (how quickly the camera catches up).
@export var follow_smoothing_time: float = 0.1

var _spring_arm: SpringArm3D
var _player: CharacterBody3D
var _camera_pitch: float = 0.0
var _camera_yaw: float = 0.0
var _previous_player_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	_spring_arm = get_node_or_null(spring_arm_path) as SpringArm3D

	## Enable collision on the spring arm to prevent wall clipping.
	if _spring_arm != null:
		_spring_arm.collide_with_enemies = false
		_spring_arm.collide_with_areas = false
		_spring_arm.collide_with_bodies = true
		_spring_arm.collide_with_skeletons = false

	## Initialise the previous position to avoid a jump on the first frame.
	if _player != null:
		_previous_player_position = _player.position


func _process(delta: float) -> void:
	## Orbit the camera with mouse or joystick input.
	_handle_look_input()

	## Position the camera to follow the player with smoothing.
	_follow_player(delta)


func _handle_look_input() -> void:
	var delta_yaw: float = 0.0
	var delta_pitch: float = 0.0

	## Mouse input (only when captured).
	var mouse_delta := Input.get_last_mouse_velocity()
	if mouse_delta.length() > 0:
		delta_yaw = mouse_delta.x * mouse_sensitivity
		delta_pitch = -mouse_delta.y * mouse_sensitivity

	## Joystick input (always active for look).
	if Input.is_action_pressed(&"look_right"):
		delta_yaw += joystick_sensitivity
	if Input.is_action_pressed(&"look_left"):
		delta_yaw -= joystick_sensitivity
	if Input.is_action_pressed(&"look_down"):
		delta_pitch += joystick_sensitivity
	if Input.is_action_pressed(&"look_up"):
		delta_pitch -= joystick_sensitivity

	if delta_yaw != 0.0 or delta_pitch != 0.0:
		_camera_yaw += delta_yaw
		_camera_pitch = clamp(_camera_pitch + delta_pitch, pitch_min, pitch_max)

		if _spring_arm != null:
			_spring_arm.rotation.y = deg_to_rad(_camera_yaw)
			_spring_arm.rotation.x = deg_to_rad(_camera_pitch)


func _follow_player(delta: float) -> void:
	if _player == null:
		return

	## Smoothly follow the player position.
	var target_position: Vector3 = _player.position
	var smooth_time: float = max(follow_smoothing_time, delta)
	var t: float = 1.0 - exp(-smooth_time / max(follow_smoothing_time, 0.001))
	position = position.lerp(target_position, t)
	_previous_player_position = target_position

	## Set the shoulder offset on the spring arm.
	if _spring_arm != null:
		_spring_arm.position = Vector3(shoulder_offset.x, shoulder_offset.y, 0.0)


## Returns the current camera yaw in radians.
func get_camera_yaw() -> float:
	return deg_to_rad(_camera_yaw)
