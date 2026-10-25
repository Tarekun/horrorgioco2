## Third-person player character with camera-relative movement.
##
## Uses CharacterBody3D with movement direction computed relative to the
## camera's yaw. Supports analog (joystick) and keyboard input.
##
## Movement parameters are @export so designers can tune them without code changes.
## Gravity, steps and slopes are handled by the engine's built-in physics.

class_name PlayerController
extends CharacterBody3D

## Walk speed when stick tilt is below 50% threshold.
@export var walk_speed: float = 1.5

## Run speed at full stick input (above 50% threshold).
@export var run_speed: float = 3.5

## Maximum speed while sprinting.
@export var sprint_speed: float = 5.5

## Smooth turn rate toward movement direction in degrees per second.
@export var turn_speed: float = 720.0

## Analog stick deadzone for movement input.
@export var move_deadzone: float = 0.5

## Reference to the over-the-shoulder camera controller.
@export_node_path var camera_controller_path: NodePath

## Reference to the stamina component (child node).
@export_node_path var stamina_component_path: NodePath

var _camera_controller: CameraController
var _stamina_component: StaminaComponent
var _current_speed: float = 0.0
var _input_vector: Vector2 = Vector2.ZERO
var _is_sprinting: bool = false
var _movement_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	_camera_controller = get_node_or_null(camera_controller_path) as CameraController
	_stamina_component = get_node_or_null(stamina_component_path) as StaminaComponent
	if _stamina_component:
		_stamina_component.stamina_changed.connect(_on_stamina_changed)


func _physics_process(delta: float) -> void:
	## Read movement input from actions.
	_input_vector = _get_input_vector()

	## Determine target speed based on sprint state and input magnitude.
	_current_speed = _get_current_speed()

	## Calculate camera-relative movement direction.
	_movement_direction = _get_camera_relative_direction()

	## Apply gravity.
	if not is_on_floor():
		var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		velocity.y -= grav * delta

	## Set horizontal velocity.
	velocity.x = _movement_direction.x * _current_speed
	velocity.z = _movement_direction.z * _current_speed

	## Snap to floor when on ground.
	if is_on_floor():
		velocity.y = max(velocity.y, 0.0)

	move_and_slide()

	## Smoothly turn toward movement direction.
	_update_facing(delta)


func _get_input_vector() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_action_pressed(&"move_forward"):
		direction.y -= 1.0
	if Input.is_action_pressed(&"move_back"):
		direction.y += 1.0
	if Input.is_action_pressed(&"move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed(&"move_right"):
		direction.x += 1.0

	## Apply deadzone to analog input; keyboard input stays full magnitude.
	if direction.length() < move_deadzone:
		direction = Vector2.ZERO

	return direction


func _get_current_speed() -> float:
	var input_magnitude: float = _input_vector.length()

	## Walk speed when stick is tilted less than 50%.
	if input_magnitude < 0.5:
		return walk_speed

	var target_speed: float = run_speed
	if _is_sprinting:
		target_speed = sprint_speed

	return target_speed


func _get_camera_relative_direction() -> Vector3:
	if _camera_controller == null:
		return Vector3.FORWARD

	var camera_yaw: float = _camera_controller.get_camera_yaw()
	var forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, sin(camera_yaw))

	return (forward * -_input_vector.y + right * _input_vector.x).normalized()


func _update_facing(delta: float) -> void:
	if _movement_direction.length() < 0.01:
		return

	var target_angle: float = atan2(_movement_direction.x, _movement_direction.z)
	var current_angle: float = rotation.y

	## Find the shortest angle difference.
	var delta_angle: float = target_angle - current_angle
	while delta_angle > PI:
		delta_angle -= 2 * PI
	while delta_angle < -PI:
		delta_angle += 2 * PI

	## Clamp to maximum turn rate.
	var max_turn: float = deg_to_rad(turn_speed) * delta
	delta_angle = clamp(delta_angle, -max_turn, max_turn)

	rotation.y += delta_angle


func _on_sprint_requested(is_active: bool) -> void:
	if is_active and _stamina_component != null:
		if _stamina_component.start_sprinting():
			_is_sprinting = true
		else:
			_is_sprinting = false
	else:
		_is_sprinting = false
		if _stamina_component != null:
			_stamina_component.stop_sprinting()


func _on_stamina_changed(_new_value: float) -> void:
	## If stamina drops to zero, stop sprinting.
	if _stamina_component != null and _stamina_component.current_stamina <= 0.0:
		_is_sprinting = false
		_stamina_component.stop_sprinting()


## Public API: call when the sprint input changes state.
func set_sprint_active(is_active: bool) -> void:
	_on_sprint_requested(is_active)


## Returns the current movement speed.
func get_current_speed() -> float:
	return _current_speed


## Returns the current movement direction (normalized).
func get_movement_direction() -> Vector3:
	return _movement_direction
