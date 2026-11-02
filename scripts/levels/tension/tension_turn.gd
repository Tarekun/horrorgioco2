## A tension action that turns a node by `degrees` around one of its own axes and
## leaves it there: a wardrobe door creaking open.

class_name TensionTurn
extends TensionAction

## The node that turns, such as a door's hinge.
@export var target: Node3D

## The axis it turns around, in its own space.
@export var axis: Vector3 = Vector3.UP

## How far (degrees) it turns.
@export var degrees: float = 70.0

## Seconds the turn takes.
@export var duration: float = 2.0

var _motion: Tween


func _start() -> void:
	if target == null:
		return
	var turn := Quaternion(axis.normalized(), deg_to_rad(degrees))
	var end: Quaternion = target.quaternion * turn
	_motion = create_tween()
	_motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.tween_property(target, ^"quaternion", end, maxf(duration, 0.001))
