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

class_name CameraController
extends Node3D

## Arm length from the shoulder pivot to the camera.
@export var arm_length: float = 2.2

## Shoulder offset: (right, up) from the player position.
@export var shoulder_offset: Vector2 = Vector2(0.5, 1.6)

## Mouse look sensitivity (degrees per pixel).
@export var mouse_sensitivity: float = 0.3

## Joystick look sensitivity (degrees per axis unit per second).
@export var joystick_sensitivity: float = 40.0

## Camera pitch limits in degrees.
@export var pitch_min: float = -60.0
@export var pitch_max: float = 50.0

## Reference to the player character (for position following).
@export var player: CharacterBody3D

## Reference to the SpringArm3D child node.
@export var spring_arm: SpringArm3D

## Camera follow smoothing time in seconds (how quickly the camera catches up).
@export var follow_smoothing_time: float = 0.1

var _camera_pitch: float = 0.0
var _camera_yaw: float = 0.0
var _previous_player_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	## Make the camera rig top-level so it doesn't inherit player rotation.
	top_level = true

	## Enable collision on the spring arm to prevent wall clipping.
	if spring_arm:
		spring_arm.collide_with_enemies = false
		spring_arm.collide_with_areas = false
		spring_arm.collide_with_bodies = true
		spring_arm.collide_with_skeletons = false

	## Initialise the previous position to avoid a jump on the first frame.
	if player:
		_previous_player_position = player.position


func _process(delta: float) -> void:
	# Orbit the camera with joystick input.
	_handle_joystick_look(delta)

	# Position the camera to follow the player with smoothing.
	_follow_player(delta)


## Called from Player._unhandled_input() when the mouse is captured.
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var delta_yaw: float = -event.relative.x * mouse_sensitivity
	var delta_pitch: float = event.relative.y * mouse_sensitivity

	_camera_yaw += delta_yaw
	_camera_pitch = clampf(_camera_pitch + delta_pitch, pitch_min, pitch_max)

	if spring_arm:
		spring_arm.rotation.y = deg_to_rad(_camera_yaw)
		spring_arm.rotation.x = deg_to_rad(_camera_pitch)


func _handle_joystick_look(delta: float) -> void:
	var look_x: float = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down").x

	if abs(look_x) > 0.0:
		var delta_yaw: float = look_x * joystick_sensitivity * delta
		_camera_yaw += delta_yaw

		if spring_arm:
			spring_arm.rotation.y = deg_to_rad(_camera_yaw)


func _follow_player(delta: float) -> void:
	if player == null:
		return

	# Smoothly follow the player position.
	var target_position: Vector3 = player.position
	var t: float = 1.0 - exp(-delta / maxf(follow_smoothing_time, 0.001))
	position = position.lerp(target_position, t)
	_previous_player_position = target_position

	# Set the shoulder offset on the spring arm.
	if spring_arm:
		spring_arm.position = Vector3(shoulder_offset.x, shoulder_offset.y, 0.0)


## Returns the current camera yaw in radians.
func get_camera_yaw() -> float:
	return deg_to_rad(_camera_yaw)
