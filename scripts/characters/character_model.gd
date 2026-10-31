## A character's visible, animated body: a skinned rig whose AnimationTree
## blends idle, walk and run by movement speed, with one-off actions as
## further states of its state machine.
##
## The owner reports its ground speed with set_speed(); the model smooths it
## and feeds it to the locomotion blend space. play_action() jumps to an action
## (an attack, a hit reaction) and return_to_locomotion() goes back.
##
## The model advances the tree itself each frame, so an action can be played
## faster or slower than its clip (a slow weapon's swing) and the whole
## animation can freeze (hitstop) without restarting the state machine.

class_name CharacterModel
extends Node3D

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

var _target_speed: float = 0.0
var _blend_speed: float = 0.0
var _playback: AnimationNodeStateMachinePlayback
var _action_speed: float = 1.0
var _is_frozen: bool = false


func _ready() -> void:
	if animation_tree:
		animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_playback = animation_tree.get(PLAYBACK_PARAMETER) as AnimationNodeStateMachinePlayback


func _process(delta: float) -> void:
	_blend_speed = smoothed_speed(_blend_speed, _target_speed, blend_responsiveness, delta)
	if animation_tree:
		animation_tree.set(BLEND_PARAMETER, _blend_speed)
		if not _is_frozen:
			animation_tree.advance(delta * _action_speed)


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


## Plays a one-off action clip (an attack, say) from its start. Given a
## `duration`, the clip is stretched or squeezed to last that many seconds, so
## a slow weapon swings slowly; otherwise it plays at its own length.
func play_action(action: StringName, duration: float = 0.0) -> void:
	if _playback == null:
		return
	_action_speed = 1.0
	if duration > 0.0 and animation_tree.has_animation(action):
		_action_speed = animation_tree.get_animation(action).length / duration
	_playback.start(action, true)


## Jumps to the last frame of an action, as if it had played out: a body
## loaded from a save lying where it fell.
func finish_action(action: StringName) -> void:
	play_action(action)
	if animation_tree and animation_tree.has_animation(action):
		animation_tree.advance(0.0)
		animation_tree.advance(animation_tree.get_animation(action).length)


## Goes back to the locomotion blend.
func return_to_locomotion() -> void:
	_action_speed = 1.0
	if _playback:
		_playback.start(LOCOMOTION_STATE, true)


## Returns the state currently playing: LOCOMOTION_STATE or an action's name.
func get_current_state() -> StringName:
	return _playback.get_current_node() if _playback else &""


## Freezes or resumes the animation (hitstop).
func set_frozen(is_frozen: bool) -> void:
	_is_frozen = is_frozen


func is_frozen() -> bool:
	return _is_frozen


## How fast the tree plays relative to its clips: 1 except while an action is
## stretched to a duration.
func get_action_speed() -> float:
	return _action_speed
