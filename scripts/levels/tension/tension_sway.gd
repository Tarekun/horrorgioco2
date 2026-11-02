## A tension action that swings a node back and forth around one of its own axes:
## a curtain in a draught, hangers knocked in a wardrobe, a sheet brushed past.
##
## The angle is `lean_degrees` plus `degrees` either way every `period`
## seconds. Over `duration` it dies away and the node comes to rest where it
## was; with no duration it keeps going.

class_name TensionSway
extends TensionAction

## The node that swings.
@export var target: Node3D

## The axis it swings around, in its own space.
@export var axis: Vector3 = Vector3.RIGHT

## How far (degrees) it swings either way.
@export var degrees: float = 5.0

## A steady tilt (degrees) to swing around, so a curtain stays blown out.
@export var lean_degrees: float = 0.0

## Seconds for one swing there and back.
@export var period: float = 2.0

## Seconds until it comes to rest; 0 keeps it swinging.
@export var duration: float = 0.0

var _rest: Basis
var _time: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	if duration > 0.0 and _time >= duration:
		_end()
		return
	var angle: float = angle_at(_time, degrees, lean_degrees, period, duration)
	target.basis = _rest * Basis(axis.normalized(), deg_to_rad(angle))


## The swing's angle (degrees) `time` seconds in. The lean comes in over the
## first half swing, and both die away linearly over `duration` (if any).
static func angle_at(
	time: float, degrees: float, lean_degrees: float, period: float, duration: float
) -> float:
	var fade: float = 1.0
	if duration > 0.0:
		fade = clampf(1.0 - time / duration, 0.0, 1.0)
	var rise: float = clampf(time / maxf(period * 0.5, 0.001), 0.0, 1.0)
	var swing: float = sin(TAU * time / maxf(period, 0.001))
	return (lean_degrees * rise + degrees * swing) * fade


func _start() -> void:
	if target == null:
		return
	_rest = target.basis
	_time = 0.0
	set_process(true)


func _end() -> void:
	if target and is_processing():
		target.basis = _rest
	set_process(false)
