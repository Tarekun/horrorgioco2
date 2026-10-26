## Screen cues for the player's health state: an edge vignette and a
## desaturation of the view. No numbers or bars.
##
## set_targets() says where the cues should be; they ease there over time, so
## a state change never pops.

class_name HealthOverlay
extends CanvasLayer

## How fast the cues move to their targets, in strength (0 to 1) per second.
@export var fade_rate: float = 1.0

## The full-screen rect drawn with the health state shader.
@export var overlay_rect: ColorRect

## Current vignette and desaturation strength (0 to 1).
var vignette: float = 0.0
var desaturation: float = 0.0

var _target_vignette: float = 0.0
var _target_desaturation: float = 0.0


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	tick(delta)


## Moves the cues towards their targets by `delta` seconds.
func tick(delta: float) -> void:
	vignette = approached(vignette, _target_vignette, fade_rate, delta)
	desaturation = approached(desaturation, _target_desaturation, fade_rate, delta)
	_apply()


## Sets the strengths (0 to 1) the cues ease towards.
func set_targets(new_vignette: float, new_desaturation: float) -> void:
	_target_vignette = clampf(new_vignette, 0.0, 1.0)
	_target_desaturation = clampf(new_desaturation, 0.0, 1.0)


## `current` moved towards `target` by at most `rate * delta`.
static func approached(current: float, target: float, rate: float, delta: float) -> float:
	return move_toward(current, target, rate * delta)


func _apply() -> void:
	if overlay_rect == null:
		return
	var shader_material := overlay_rect.material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter(&"vignette", vignette)
		shader_material.set_shader_parameter(&"desaturation", desaturation)
	overlay_rect.visible = vignette > 0.0 or desaturation > 0.0
