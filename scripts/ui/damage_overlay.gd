## Red flash at the screen edge when the player is hurt. No numbers or bars:
## the spec's only on-screen cue for a hit.
##
## flash() sets the strength (0 to 1); it then fades out.

class_name DamageOverlay
extends CanvasLayer

## Strength lost per second.
@export var fade_rate: float = 2.5

## The full-screen rect drawn with the edge flash shader.
@export var flash_rect: ColorRect

## Current strength (0 to 1).
var intensity: float = 0.0


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	if intensity <= 0.0:
		return
	intensity = faded(intensity, fade_rate, delta)
	_apply()


## Starts a flash of the given strength. A weaker flash never cuts a stronger one short.
func flash(strength: float) -> void:
	intensity = maxf(intensity, clampf(strength, 0.0, 1.0))
	_apply()


## Strength after `delta` seconds of fading at `rate` per second.
static func faded(current: float, rate: float, delta: float) -> float:
	return maxf(current - rate * delta, 0.0)


func _apply() -> void:
	if flash_rect == null:
		return
	var shader_material := flash_rect.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter(&"intensity", intensity)
	flash_rect.visible = intensity > 0.0
