## The player's visible character (see CharacterModel), plus what only the
## player's body does: footsteps called from the walk and run clips, and a limp
## when hurt.

class_name PlayerModel
extends CharacterModel

## Emitted when a foot lands, with the speed (m/s) the character is moving at.
signal footstep_taken(speed: float)

## The node the limp tilts and dips: the model, which no clip moves.
@export var limp_pivot: Node3D

## How far (metres) the body dips and how far (radians) it rolls at a full limp
## at walking pace.
@export var limp_dip: float = 0.05
@export var limp_roll: float = 0.07

## How quickly the limp fades in and out (higher is snappier).
@export var limp_responsiveness: float = 3.0

## Limp cycles per metre travelled.
@export var limp_cycles_per_metre: float = 0.5

## Footsteps are ignored below this blend speed (m/s), so a near-idle pose
## stays silent even though the walk clip has a little weight.
@export var min_footstep_speed: float = 0.6

## Shortest time between two footsteps. Blended clips both call
## emit_footstep() at the same instant; this folds those into one.
@export var min_footstep_interval: float = 0.15

var _time_since_footstep: float = 1.0
var _limp_target: float = 0.0
var _limp: float = 0.0
var _limp_phase: float = 0.0


func _process(delta: float) -> void:
	_time_since_footstep += delta
	super(delta)
	_update_limp(delta)


## Sets how strongly the character limps (0 to 1). It eases in and out, and
## only shows while moving, in step with the stride.
func set_limp(amount: float) -> void:
	_limp_target = clampf(amount, 0.0, 1.0)


## How far the limp has eased in (0 to 1).
func get_limp() -> float:
	return _limp


## The body's (dip, roll) offset in metres and radians at `phase` radians into
## the limp cycle, at `weight` (0 to 1). The body sinks and leans together on
## one side of the cycle and recovers on the other.
static func limp_offset(phase: float, weight: float, dip: float, roll: float) -> Vector2:
	var sway: float = sin(phase)
	return Vector2(-dip * weight * (0.5 + 0.5 * sway), roll * weight * sway)


func _update_limp(delta: float) -> void:
	_limp = lerpf(_limp, _limp_target, 1.0 - exp(-limp_responsiveness * delta))
	# The limp only shows while moving: full at walking pace, none at rest.
	var moving: float = clampf(_blend_speed / 1.5, 0.0, 1.0)
	_limp_phase = wrapf(_limp_phase + _blend_speed * limp_cycles_per_metre * TAU * delta, 0.0, TAU)
	if limp_pivot == null:
		return
	var offset: Vector2 = limp_offset(_limp_phase, _limp * moving, limp_dip, limp_roll)
	limp_pivot.position.y = offset.x
	limp_pivot.rotation.z = offset.y


## Called by the walk and run animations when a foot lands (method track).
func emit_footstep() -> void:
	if _blend_speed < min_footstep_speed or _time_since_footstep < min_footstep_interval:
		return
	_time_since_footstep = 0.0
	footstep_taken.emit(_blend_speed)
