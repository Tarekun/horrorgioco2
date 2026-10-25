## The player's visible character: a skinned rig with idle, walk and run
## animations blended by movement speed through an AnimationTree.
##
## The player reports its ground speed with set_speed(); the model smooths it
## and feeds it to the locomotion blend space.

class_name PlayerModel
extends Node3D

## Name of the AnimationTree parameter driving the locomotion blend space.
const BLEND_PARAMETER: StringName = &"parameters/blend_position"

## How quickly the blend follows the speed (higher is snappier).
@export var blend_responsiveness: float = 12.0

## The AnimationTree holding the locomotion blend space.
@export var animation_tree: AnimationTree

var _target_speed: float = 0.0
var _blend_speed: float = 0.0


func _process(delta: float) -> void:
	_blend_speed = smoothed_speed(_blend_speed, _target_speed, blend_responsiveness, delta)
	if animation_tree:
		animation_tree.set(BLEND_PARAMETER, _blend_speed)


## Exponentially approaches `target` from `current`, frame-rate independent.
static func smoothed_speed(
	current: float, target: float, responsiveness: float, delta: float
) -> float:
	return lerpf(current, target, 1.0 - exp(-responsiveness * delta))


## Sets the horizontal speed (m/s) the locomotion animations should match.
func set_speed(speed: float) -> void:
	_target_speed = maxf(speed, 0.0)


## Returns the smoothed speed currently driving the blend.
func get_blend_speed() -> float:
	return _blend_speed
