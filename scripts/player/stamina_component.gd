## Manages a stamina pool shared by sprinting and combat actions.
##
## Exposed as @export variables so designers can tune values without code changes.
## The stamina system follows the gameplay spec:
## - Regeneration starts after a delay following the last stamina use.
## - Sprinting drains stamina; when exhausted the player can't sprint until
##   stamina recovers past the exhaustion threshold.

class_name StaminaComponent
extends Node

signal stamina_changed(new_value: float)
signal exhausted

## Maximum stamina pool size.
@export var max_stamina: float = 100.0

## Stamina regenerated per second when not using stamina.
@export var regeneration_rate: float = 25.0

## Seconds of inactivity required before regeneration begins.
@export var regeneration_delay: float = 0.8

## Stamina drained per second while sprinting.
@export var sprint_drain: float = 15.0

## Stamina level below which the player is exhausted and cannot sprint.
@export var exhaustion_threshold: float = 30.0

var current_stamina: float
var is_draining: bool = false

var can_sprint: bool:
	get:
		return current_stamina > exhaustion_threshold and not _is_recovering

var _last_use_time: float = 0.0
var _is_recovering: bool = false


func _init() -> void:
	current_stamina = max_stamina


func _process(delta: float) -> void:
	if is_draining:
		_last_use_time = get_tree().get_time()
		current_stamina = max(0.0, current_stamina - sprint_drain * delta)
		if current_stamina <= 0.0:
			exhausted.emit()
	else:
		var idle_time: float = get_tree().get_time() - _last_use_time
		if idle_time >= regeneration_delay and current_stamina < max_stamina:
			current_stamina = min(max_stamina, current_stamina + regeneration_rate * delta)
			if current_stamina > exhaustion_threshold and _is_recovering:
				_is_recovering = false
		if current_stamina <= 0.0:
			_is_recovering = true

	## Emit the signal whenever stamina changes meaningfully.
	if is_draining or current_stamina < max_stamina:
		stamina_changed.emit(current_stamina)


## Returns true if the player can start sprinting.
func is_sprinting_allowed() -> bool:
	return can_sprint


## Starts sprinting. Returns true if stamina was sufficient.
func start_sprinting() -> bool:
	if not is_sprinting_allowed():
		return false
	is_draining = true
	return true


## Stops sprinting.
func stop_sprinting() -> void:
	is_draining = false
