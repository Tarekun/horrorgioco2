## A main switchboard (the hotel's is `switchboard_basement`, in the boiler
## room): a big lever that brings the power back. It works once.
##
## Throwing it sets its `power_flag`, and the switchboard then reacts to that
## flag like any other consumer (see LevelFlag): a clunk plays, the `lights`
## stutter on and stay on, and once they settle the `enemy` waiting in the dark
## wakes, already alerted to the player. A moment later the lift machinery
## groans awake behind the wall. The other effects of the power (the shutter's
## button, the lift, the porter leaving) read the same flag themselves.
##
## When a loaded save sets the flag, the lights are simply on and the enemy is
## awake at its placed position, not alerted (a dead one stays a corpse), with
## no stutter and no sound. Either way the switchboard then stops being an
## interactable, so its prompt doesn't show again.
##
## The switchboard records nothing itself: the flag is its saved state.

class_name Switchboard
extends Interactable

## Emitted when the lights have stopped stuttering and stay on, after a live
## throw.
signal lights_settled

const PROMPT: String = "Throw the main switch."

## The flag the switch sets (the hotel's `power_restored`).
@export var power_flag: LevelFlag

## The lights the power brings back, shown by toggling this node's visibility.
@export var lights: Node3D

## The enemy that wakes when the lights come on. Optional.
@export var enemy: Enemy

## Seconds of the stutter, alternating on and off from the first flash. The
## lights stay on after the last step.
@export var stutter: PackedFloat32Array = [0.08, 0.15, 0.06, 0.4, 0.12, 0.12]

@export_group("Sound")
## Played at the lever when it is thrown.
@export var switch_sound: AudioStreamPlayer3D
## The lift machinery waking up behind the wall. Optional.
@export var machinery_sound: AudioStreamPlayer3D
## Seconds after the throw before the machinery groans.
@export var machinery_delay: float = 1.2

var _tween: Tween


func _ready() -> void:
	super._ready()
	prompt = PROMPT
	if power_flag == null:
		push_warning("Switchboard %s has no power flag." % name)
		return
	power_flag.flag_set.connect(_on_power_flag_set)
	if power_flag.is_set:
		_on_power_flag_set(true)


## Throws the switch, if it hasn't been thrown yet.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if power_flag and not power_flag.is_set:
		power_flag.set_flag()
	return ""


## Whether the power is back.
func is_thrown() -> bool:
	return power_flag != null and power_flag.is_set


## Seconds from the throw until the lights stay on.
func get_stutter_duration() -> float:
	var total: float = 0.0
	for seconds: float in stutter:
		total += seconds
	return total


func _on_power_flag_set(is_loaded: bool) -> void:
	remove_from_group(Interactable.GROUP)
	if is_loaded:
		_show_lights(true)
		if enemy:
			enemy.wake(false)
		return
	if switch_sound:
		switch_sound.play()
	if machinery_sound:
		var groan: Tween = create_tween()
		groan.tween_interval(machinery_delay)
		groan.tween_callback(machinery_sound.play)
	_stutter_lights()


func _stutter_lights() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var is_on: bool = true
	for seconds: float in stutter:
		_tween.tween_callback(_show_lights.bind(is_on))
		_tween.tween_interval(seconds)
		is_on = not is_on
	_tween.tween_callback(_show_lights.bind(true))
	_tween.tween_callback(_on_lights_settled)


func _show_lights(is_on: bool) -> void:
	if lights:
		lights.visible = is_on


func _on_lights_settled() -> void:
	if enemy:
		enemy.wake()
	lights_settled.emit()
