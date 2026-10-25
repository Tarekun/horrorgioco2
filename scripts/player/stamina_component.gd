## Manages a stamina pool shared by sprinting and combat actions.
##
## Exposed as @export variables so designers can tune values without code changes.
## The stamina system follows the gameplay spec:
## - Regeneration starts after a delay following the last stamina use.
## - Sprinting drains stamina. At 0 the player is exhausted and can't sprint
##   until stamina recovers past the exhaustion threshold.

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

## Stamina level the player must get back above after hitting 0 to sprint again.
@export var exhaustion_threshold: float = 30.0

var current_stamina: float = 0.0
var is_draining: bool = false
var is_exhausted: bool = false

var _idle_time: float = 0.0


func _ready() -> void:
	refill()


func _process(delta: float) -> void:
	var previous: float = current_stamina

	if is_draining:
		_idle_time = 0.0
		current_stamina = maxf(0.0, current_stamina - sprint_drain * delta)
		if current_stamina <= 0.0 and not is_exhausted:
			is_exhausted = true
			is_draining = false
			exhausted.emit()
	else:
		_idle_time += delta
		if _idle_time >= regeneration_delay:
			current_stamina = minf(max_stamina, current_stamina + regeneration_rate * delta)
			if is_exhausted and current_stamina > exhaustion_threshold:
				is_exhausted = false

	if not is_equal_approx(previous, current_stamina):
		stamina_changed.emit(current_stamina)


## Returns true if the player can start sprinting.
func can_sprint() -> bool:
	return not is_exhausted and current_stamina > 0.0


## Starts sprinting. Returns true if stamina was sufficient.
func start_sprinting() -> bool:
	if not can_sprint():
		return false
	is_draining = true
	return true


## Stops sprinting.
func stop_sprinting() -> void:
	is_draining = false


## Fills the pool to `max_stamina` and clears exhaustion.
func refill() -> void:
	current_stamina = max_stamina
	is_exhausted = false
	is_draining = false
	_idle_time = 0.0
