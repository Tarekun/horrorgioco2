## Screen-space film grain and vignette over the whole game view.
##
## A CanvasLayer holding a full-screen ColorRect with a shader. The intensity
## values are exported here and pushed into the shader, so they can be tuned
## in the inspector or from settings code.

class_name PostProcess
extends CanvasLayer

## Grain strength, 0 = none.
@export_range(0.0, 0.5) var grain_intensity: float = 0.06:
	set(value):
		grain_intensity = value
		_apply_parameters()

## Vignette strength, 0 = none, 1 = black corners.
@export_range(0.0, 1.0) var vignette_intensity: float = 0.55:
	set(value):
		vignette_intensity = value
		_apply_parameters()

## Distance from the centre (0 centre, 1 corner) where the vignette begins.
@export_range(0.0, 1.5) var vignette_radius: float = 0.55:
	set(value):
		vignette_radius = value
		_apply_parameters()

## Width of the vignette falloff.
@export_range(0.01, 1.5) var vignette_softness: float = 0.6:
	set(value):
		vignette_softness = value
		_apply_parameters()

## The full-screen rect carrying the shader material.
@export var screen_rect: ColorRect


func _ready() -> void:
	_apply_parameters()


## The shader parameters for the current settings.
func get_shader_parameters() -> Dictionary[StringName, float]:
	return {
		&"grain_intensity": grain_intensity,
		&"vignette_intensity": vignette_intensity,
		&"vignette_radius": vignette_radius,
		&"vignette_softness": vignette_softness,
	}


func _apply_parameters() -> void:
	if screen_rect == null:
		return
	var shader_material := screen_rect.material as ShaderMaterial
	if shader_material == null:
		return
	var parameters: Dictionary[StringName, float] = get_shader_parameters()
	for key: StringName in parameters:
		shader_material.set_shader_parameter(key, parameters[key])
