## The player's visible character: a skinned rig with idle, walk and run
## animations blended by movement speed through an AnimationTree.
##
## The player reports its ground speed with set_speed(); the model smooths it
## and feeds it to the locomotion blend space. One-off actions (attacks, dodge,
## hit reactions) are further states of the tree's state machine: play_action()
## jumps to one and return_to_locomotion() goes back.

class_name PlayerModel
extends Node3D

## Emitted when a foot lands, with the speed (m/s) the character is moving at.
signal footstep_taken(speed: float)

## Name of the AnimationTree parameter driving the locomotion blend space.
const BLEND_PARAMETER: StringName = &"parameters/locomotion/blend_position"

## Name of the state machine state holding the locomotion blend space.
const LOCOMOTION_STATE: StringName = &"locomotion"

## Name of the AnimationTree parameter holding the state machine playback.
const PLAYBACK_PARAMETER: StringName = &"parameters/playback"

## How quickly the blend follows the speed (higher is snappier).
@export var blend_responsiveness: float = 12.0

## The AnimationTree holding the locomotion blend space.
@export var animation_tree: AnimationTree

## Footsteps are ignored below this blend speed (m/s), so a near-idle pose
## stays silent even though the walk clip has a little weight.
@export var min_footstep_speed: float = 0.6

## Shortest time between two footsteps. Blended clips both call
## emit_footstep() at the same instant; this folds those into one.
@export var min_footstep_interval: float = 0.15

var _target_speed: float = 0.0
var _blend_speed: float = 0.0
var _time_since_footstep: float = 1.0
var _playback: AnimationNodeStateMachinePlayback


func _ready() -> void:
	if animation_tree:
		_playback = animation_tree.get(PLAYBACK_PARAMETER) as AnimationNodeStateMachinePlayback


func _process(delta: float) -> void:
	_time_since_footstep += delta
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


## Plays a one-off action clip (an attack, say) from its start.
func play_action(action: StringName) -> void:
	if _playback:
		_playback.start(action, true)


## Goes back to the locomotion blend.
func return_to_locomotion() -> void:
	if _playback:
		_playback.start(LOCOMOTION_STATE, true)


## Returns the state currently playing: LOCOMOTION_STATE or an action's name.
func get_current_state() -> StringName:
	return _playback.get_current_node() if _playback else &""


## Freezes or resumes the animation (hitstop).
func set_frozen(is_frozen: bool) -> void:
	if animation_tree == null:
		return
	animation_tree.callback_mode_process = (
		AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		if is_frozen
		else AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	)


## Called by the walk and run animations when a foot lands (method track).
func emit_footstep() -> void:
	if _blend_speed < min_footstep_speed or _time_since_footstep < min_footstep_interval:
		return
	_time_since_footstep = 0.0
	footstep_taken.emit(_blend_speed)
