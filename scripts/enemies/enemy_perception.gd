## How an enemy notices the player: by sight and by sound.
##
## Sight needs the target inside a view cone and range, and an unobstructed
## line from the eye to the target. A lit flashlight makes the player visible
## from much further away. Very close targets are noticed all round. Noises
## from NoiseEvent that reach the enemy alert it to where they came from.
##
## Being alert is what the enemy's state machine reads as having a target. The
## alert lasts `lose_track_time` seconds from the last sighting or noise, then
## the enemy loses track. Place this node at the enemy's eyes; it looks along
## -Z.

class_name EnemyPerception
extends Node3D

## Emitted when the enemy becomes alert.
signal alerted
## Emitted when the enemy loses track of the target.
signal track_lost

## Metres the player can be seen from in the dark.
@export var sight_range: float = 10.0

## Multiplier of the sight range while the player's flashlight is on.
@export var lit_range_multiplier: float = 1.8

## Half angle of the view cone in degrees.
@export_range(0.0, 180.0) var sight_half_angle: float = 55.0

## Targets this close (metres) are noticed from any direction.
@export var awareness_radius: float = 1.5

## Seconds the alert lasts after the last sighting or noise.
@export var lose_track_time: float = 6.0

## Height above the target's feet that the line of sight aims for.
@export var target_height: float = 1.0

## Physics layers that block sight.
@export_flags_3d_physics var obstruction_mask: int = CombatLayers.WORLD

## The enemy this node belongs to; it hears nothing while dormant, down or dead.
@export var enemy: Enemy

## Whether the target was in sight at the last update.
var is_target_visible: bool = false

## Where the enemy last saw or heard the target.
var last_known_position: Vector3 = Vector3.ZERO

var _alert_left: float = 0.0


func _ready() -> void:
	add_to_group(NoiseEvent.HEARING_GROUP)


## Advances the alert timer and looks for `target`.
func update(delta: float, target: Node3D) -> void:
	is_target_visible = target != null and can_see(target)
	if is_target_visible:
		alert_to(target.global_position)
	elif _alert_left > 0.0:
		_alert_left -= delta
		if _alert_left <= 0.0:
			_alert_left = 0.0
			track_lost.emit()


## Whether the enemy is aware of the target.
func is_alert() -> bool:
	return _alert_left > 0.0


## Becomes alert (or stays so, renewing the timer) about `position`.
func alert_to(position: Vector3) -> void:
	var was_alert: bool = is_alert()
	last_known_position = position
	_alert_left = lose_track_time
	if not was_alert:
		alerted.emit()


## Hears a noise: alerts the enemy to `position` if it carries this far.
func hear_noise(position: Vector3, radius: float) -> void:
	if enemy and (enemy.is_dormant or enemy.is_downed() or enemy.is_dead()):
		return
	if NoiseEvent.is_audible(global_position, position, radius):
		alert_to(position)


## Forgets the target at once.
func lose_track() -> void:
	if is_alert():
		_alert_left = 0.0
		track_lost.emit()


## Whether `target` is in sight right now: in range, in the cone (or very
## close) and not behind a wall.
func can_see(target: Node3D) -> bool:
	var range_now: float = effective_range(
		sight_range, lit_range_multiplier, _is_target_lit(target)
	)
	var point: Vector3 = target.global_position + Vector3.UP * target_height
	var forward: Vector3 = -global_basis.z
	if not is_in_view(
		global_position, forward, point, range_now, sight_half_angle, awareness_radius
	):
		return false
	return _has_line_of_sight(point)


## Sight range given the flashlight state.
static func effective_range(base: float, lit_multiplier: float, is_lit: bool) -> float:
	return base * lit_multiplier if is_lit else base


## Whether `point` is within `max_range` of `origin` and inside the view cone
## around `forward` (half angle in degrees), or within `close_radius`.
static func is_in_view(
	origin: Vector3,
	forward: Vector3,
	point: Vector3,
	max_range: float,
	half_angle: float,
	close_radius: float
) -> bool:
	var offset: Vector3 = point - origin
	var distance: float = offset.length()
	if distance > max_range:
		return false
	if distance <= close_radius:
		return true
	return rad_to_deg(forward.angle_to(offset)) <= half_angle


func _is_target_lit(target: Node3D) -> bool:
	var player := target as Player
	return player != null and player.is_lit()


func _has_line_of_sight(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, point, obstruction_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
