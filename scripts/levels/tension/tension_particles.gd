## A tension action that starts a particle effect set up in the scene: steam from
## a shower or a pot, fog drifting in at a window, a draught under a door.

class_name TensionParticles
extends TensionAction

## The effect, left with `emitting` off until the event fires.
@export var particles: CPUParticles3D

## Seconds it keeps emitting; 0 is until stop().
@export var duration: float = 0.0

var _timer: Tween


func _start() -> void:
	if particles == null:
		return
	particles.emitting = true
	if duration > 0.0:
		_timer = create_tween()
		_timer.tween_interval(duration)
		_timer.tween_callback(_end)


func _end() -> void:
	if _timer:
		_timer.kill()
		_timer = null
	if particles:
		particles.emitting = false
