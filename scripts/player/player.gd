## Third-person player character with camera-relative movement.
##
## Uses CharacterBody3D with movement direction computed relative to the
## camera's yaw. Supports analog (joystick) and keyboard input.
##
## Movement parameters are @export so designers can tune them without changes.
## Gravity and slopes are handled by the engine's built-in physics.
## Step height (0.35 m) is handled explicitly because Godot 4 has no built-in
## step-up for CharacterBody3D.

class_name Player
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

## Maximum step height the player can climb (metres).
@export var step_height: float = 0.35

## Reference to the over-the-shoulder camera controller.
@export var camera_controller: CameraController

## Reference to the stamina component (child node).
@export var stamina_component: StaminaComponent

var _current_speed: float = 0.0
var _input_vector: Vector2 = Vector2.ZERO
var _is_sprinting: bool = false
var _movement_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	## Initialise stamina after exported overrides are applied.
	if stamina_component:
		stamina_component.current_stamina = stamina_component.max_stamina
		stamina_component.stamina_changed.connect(_on_stamina_changed)


func _unhandled_input(event: InputEvent) -> void:
	## Capture mouse when left button is pressed so look input works.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_controller._handle_mouse_motion(event)


func _physics_process(delta: float) -> void:
	# Read movement input from actions (applies per-action deadzones).
	_input_vector = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")

	# Handle sprint input.
	_process_sprint(delta)

	# Determine target speed based on sprint state and input magnitude.
	_current_speed = _get_current_speed()

	# Calculate camera-relative movement direction.
	_movement_direction = _get_camera_relative_direction()

	# Apply gravity.
	if not is_on_floor():
		var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		velocity.y -= grav * delta

	# Set horizontal velocity.
	velocity.x = _movement_direction.x * _current_speed
	velocity.z = _movement_direction.z * _current_speed

	# Handle step-up: if we hit a wall and the floor above is reachable,
	# lift the velocity to climb over small steps.
	_handle_step_up(delta)

	# Snap to floor when on ground.
	if is_on_floor():
		velocity.y = max(velocity.y, 0.0)

	move_and_slide()

	# Smoothly turn toward movement direction.
	_update_facing(delta)


func _process_sprint(_delta: float) -> void:
	var want_sprint: bool = Input.is_action_pressed(&"sprint")
	var is_moving: bool = _input_vector.length() > 0.0

	# Only drain stamina while sprinting AND moving.
	if want_sprint and is_moving and stamina_component:
		if stamina_component.start_sprinting():
			_is_sprinting = true
		else:
			_is_sprinting = false
	elif _is_sprinting:
		_is_sprinting = false
		if stamina_component:
			stamina_component.stop_sprinting()


func _handle_step_up(_delta: float) -> void:
	# Only attempt step-up when moving horizontally.
	if _movement_direction.length() < 0.01:
		return

	# Check for collisions with walls ahead.
	for i: int in get_slide_collision_count():
		var col: KinematicCollision3D = get_slide_collision(i)
		var normal: Vector3 = col.get_normal()

		# Only care about vertical walls (not floors/ceilings).
		if normal.y > 0.5:
			continue

		# If we're close to the floor and the step is climbable.
		if is_on_floor() or col.get_travel().length() < step_height:
			var step_up: Vector3 = normal * step_height
			# Project step direction onto horizontal plane.
			step_up.y = 0.0
			position += step_up


func _get_floor_collision() -> Vector3:
	# Simple floor snap: raycast down from current position.
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(position, position + Vector3.DOWN * 1.0)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)
	if result:
		return result.position - position
	return Vector3.ZERO


func _get_current_speed() -> float:
	var input_magnitude: float = _input_vector.length()

	# Walk speed when stick is tilted less than 50%.
	if input_magnitude < 0.5:
		return walk_speed

	var target_speed: float = run_speed
	if _is_sprinting:
		target_speed = sprint_speed

	return target_speed


func _get_camera_relative_direction() -> Vector3:
	if camera_controller == null:
		return Vector3.ZERO

	var camera_yaw: float = camera_controller.get_camera_yaw()
	# Godot +Y rotation: forward = (-sin θ, 0, -cos θ), right = (cos θ, 0, -sin θ).
	var forward: Vector3 = Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right: Vector3 = Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))

	return (forward * -_input_vector.y + right * _input_vector.x).normalized()


func _update_facing(delta: float) -> void:
	if _movement_direction.length() < 0.01:
		return

	# Godot forward is -Z, so target angle is atan2(-dir.x, -dir.z).
	var target_angle: float = atan2(-_movement_direction.x, -_movement_direction.z)
	var current_angle: float = rotation.y

	# Find the shortest angle difference using angle_difference.
	var delta_angle: float = wrapf(target_angle - current_angle + PI, 0.0, 2.0 * PI)
	if delta_angle > PI:
		delta_angle -= 2.0 * PI

	# Clamp to maximum turn rate.
	var max_turn: float = deg_to_rad(turn_speed) * delta
	delta_angle = clampf(delta_angle, -max_turn, max_turn)

	rotation.y += delta_angle


func _on_stamina_changed(_new_value: float) -> void:
	# If stamina drops to zero, stop sprinting.
	if stamina_component and stamina_component.current_stamina <= 0.0:
		_is_sprinting = false
		stamina_component.stop_sprinting()


# --- Public API ---


## Call when the sprint input changes state.
func set_sprint_active(_is_active: bool) -> void:
	# Input is now handled directly in _process_sprint().
	# Kept for backwards compatibility with external callers.
	pass


## Returns the current movement speed.
func get_current_speed() -> float:
	return _current_speed


## Returns the current movement direction (normalized).
func get_movement_direction() -> Vector3:
	return _movement_direction
