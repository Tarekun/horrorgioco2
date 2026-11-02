## Third-person player character with camera-relative movement.
##
## Uses CharacterBody3D with movement direction computed relative to the
## camera's yaw. Supports analog (joystick) and keyboard input.
##
## Movement parameters are @export so designers can tune them without changes.
## Gravity and slopes are handled by the engine's built-in physics.
## Step height is handled explicitly because Godot 4 has no built-in step-up
## for CharacterBody3D.

class_name Player
extends CharacterBody3D

## How far ahead (metres) the step-up probe looks. Must exceed the body radius.
const STEP_PROBE_DISTANCE: float = 0.4

## Walk speed when stick tilt is below the walk threshold.
@export var walk_speed: float = 1.5

## Run speed at full stick input (above the walk threshold).
@export var run_speed: float = 3.5

## Maximum speed while sprinting.
@export var sprint_speed: float = 5.5

## Smooth turn rate toward movement direction in degrees per second.
@export var turn_speed: float = 720.0

## Stick tilt (0 to 1) below which the player walks instead of running.
@export_range(0.0, 1.0) var walk_threshold: float = 0.5

## Maximum step height the player can climb (metres).
@export var step_height: float = 0.35

## Reference to the over-the-shoulder camera controller.
@export var camera_controller: CameraController

## Reference to the stamina component (child node).
@export var stamina_component: StaminaComponent

## The player's health (child node).
@export var health_component: HealthComponent

## Where enemy hitboxes hit the player (child node).
@export var hurtbox: Hurtbox

## The flashlight, which makes the player easier for enemies to see.
@export var flashlight: Flashlight

## The visible character, animated from the player's ground speed.
@export var model: PlayerModel

## Uses and equips items; knows the weapon held.
@export var items: PlayerItems

## The save slot screen save spots open. A save chosen there to load is loaded.
@export var save_screen: SaveScreen

## What the player carries. Pickups add to it.
var inventory := Inventory.new()

## Which documents the player has read.
var document_log := DocumentLog.new()

## Scales walk, run and sprint speed; the health cues lower it in Danger.
var speed_multiplier: float = 1.0

## True while an action (attack, dodge, stagger) drives the body: input
## movement, sprinting and turning toward the input stop, and the horizontal
## velocity is `external_velocity` instead.
var is_movement_locked: bool = false

## Horizontal velocity (x, z) used while `is_movement_locked`. Set it every frame.
var external_velocity: Vector3 = Vector3.ZERO

var _current_speed: float = 0.0
var _input_vector: Vector2 = Vector2.ZERO
var _is_sprinting: bool = false
var _movement_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	if stamina_component:
		stamina_component.exhausted.connect(_on_exhausted)
	if save_screen:
		save_screen.load_requested.connect(GameFlow.load_game)


func _physics_process(delta: float) -> void:
	# Read movement input from actions (applies per-action deadzones).
	_input_vector = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")

	_process_sprint()
	_current_speed = _get_current_speed()

	var camera_yaw: float = 0.0
	if camera_controller:
		camera_yaw = camera_controller.get_camera_yaw()
	_movement_direction = camera_relative_direction(_input_vector, camera_yaw)

	if not is_on_floor():
		var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		velocity.y -= gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	if is_movement_locked:
		velocity.x = external_velocity.x
		velocity.z = external_velocity.z
	else:
		velocity.x = _movement_direction.x * _current_speed
		velocity.z = _movement_direction.z * _current_speed

	_try_step_up(delta)
	move_and_slide()
	if not is_movement_locked:
		_update_facing(delta)
	_update_model()


## Converts a movement input (x: right, y: back) into a world-space direction
## relative to the camera yaw (radians). Returns ZERO for no input.
static func camera_relative_direction(input: Vector2, camera_yaw: float) -> Vector3:
	if input.length() < 0.001:
		return Vector3.ZERO

	# Godot +Y rotation: forward = (-sin θ, 0, -cos θ), right = (cos θ, 0, -sin θ).
	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	return (forward * -input.y + right * input.x).normalized()


## Whether the player's flashlight is on.
func is_lit() -> bool:
	return flashlight != null and flashlight.is_on()


## Puts the player's part of a save in `save`: health, inventory, the weapon
## held and the flashlight.
func write_save(save: SaveData) -> void:
	save.player_health = health_component.current_health
	save.inventory = inventory.to_dict()
	save.documents_read = document_log.to_dict()
	var weapon: ItemData = items.equipped_weapon if items else null
	save.equipped_weapon = weapon.id if weapon else &""
	save.is_flashlight_on = is_lit()


## Takes back the player's part of `save`: health, inventory, the weapon held
## and the flashlight.
func read_save(save: SaveData) -> void:
	# Revive sets the health whether or not the player is down.
	health_component.revive(save.player_health)
	inventory.from_dict(save.inventory)
	document_log.from_dict(save.documents_read)
	if items and not save.equipped_weapon.is_empty():
		items.equip(ItemCatalog.find(save.equipped_weapon))
	if flashlight:
		flashlight.set_on(save.is_flashlight_on)


## Puts the player at `marker`, facing its way, with the camera behind.
func place_at(marker: Node3D) -> void:
	global_position = marker.global_position
	rotation.y = marker.global_rotation.y
	velocity = Vector3.ZERO
	if camera_controller:
		camera_controller.snap_behind_player()


## Returns the current movement speed.
func get_current_speed() -> float:
	return _current_speed


## Returns the current movement direction (normalized, ZERO when idle).
func get_movement_direction() -> Vector3:
	return _movement_direction


func _process_sprint() -> void:
	if is_movement_locked:
		_is_sprinting = false
		if stamina_component:
			stamina_component.stop_sprinting()
		return
	if stamina_component == null:
		return

	# Sprinting needs movement input and actual progress, so pushing against a
	# wall doesn't burn stamina. Real velocity lags a frame behind the input.
	var real_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	var is_moving: bool = _input_vector != Vector2.ZERO and real_speed > 0.1

	if Input.is_action_pressed(&"sprint") and is_moving and stamina_component.start_sprinting():
		_is_sprinting = true
	else:
		_is_sprinting = false
		stamina_component.stop_sprinting()


func _get_current_speed() -> float:
	var speed: float = run_speed
	if _input_vector.length() < walk_threshold:
		speed = walk_speed
	elif _is_sprinting:
		speed = sprint_speed
	return speed * speed_multiplier


## Lifts the body over a low obstacle in the way of the horizontal motion.
## Probes: blocked ahead, headroom for the step, clear ahead at the raised
## height, and walkable ground below that.
func _try_step_up(delta: float) -> void:
	var motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	if not is_on_floor() or motion.is_zero_approx():
		return

	var start: Transform3D = global_transform
	if not test_move(start, motion):
		return

	var lift := Vector3.UP * step_height
	if test_move(start, lift):
		return

	# Look ahead past the capsule's radius, so the ground probe lands on the top
	# of the step and not on its rounded edge.
	var probe: Vector3 = motion.normalized() * maxf(motion.length(), STEP_PROBE_DISTANCE)
	var raised: Transform3D = start.translated(lift)
	if test_move(raised, probe):
		return

	var ground := KinematicCollision3D.new()
	var is_ground_found: bool = test_move(raised.translated(probe), -lift, ground)
	if not is_ground_found or ground.get_normal().y < cos(floor_max_angle):
		return

	# The probe's travel is negative on the way down, leaving the net rise.
	var rise: float = step_height + ground.get_travel().y
	if rise > 0.001:
		global_position.y += rise


func _update_facing(delta: float) -> void:
	if _movement_direction.is_zero_approx():
		return

	# Godot forward is -Z.
	var target_angle: float = atan2(-_movement_direction.x, -_movement_direction.z)
	var delta_angle: float = angle_difference(rotation.y, target_angle)
	var max_turn: float = deg_to_rad(turn_speed) * delta
	rotation.y += clampf(delta_angle, -max_turn, max_turn)


## Feeds the model the speed actually achieved, so pushing against a wall
## plays idle rather than running on the spot.
func _update_model() -> void:
	if model == null:
		return
	var real_velocity: Vector3 = get_real_velocity()
	model.set_speed(Vector2(real_velocity.x, real_velocity.z).length())


func _on_exhausted() -> void:
	_is_sprinting = false
