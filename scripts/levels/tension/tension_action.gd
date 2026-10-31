## One thing a TensionEvent does when it fires: play a sound, swing a door,
## flicker the lights. Add actions as children of the event, which runs them all
## when it fires. Each starts `delay` seconds later, so an event can be
## sequenced from the inspector.

class_name TensionAction
extends Node3D

## Seconds between the event firing and the action starting.
@export var delay: float = 0.0

## Whether the action has started.
var has_started: bool = false

var _pending: Tween


## Starts the action, after `delay`.
func run() -> void:
	if delay <= 0.0:
		_begin()
		return
	_pending = create_tween()
	_pending.tween_interval(delay)
	_pending.tween_callback(_begin)


## Ends what the action is doing, or cancels it if it hasn't started yet.
func stop() -> void:
	if _pending:
		_pending.kill()
		_pending = null
	_end()


## Does the action. Subclasses override it.
func _start() -> void:
	pass


## Undoes what is still going on (a loop playing, steam rising). Subclasses
## whose action outlasts its start override it.
func _end() -> void:
	pass


func _begin() -> void:
	_pending = null
	has_started = true
	_start()
