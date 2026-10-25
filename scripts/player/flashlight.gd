## A toggleable shadow-casting flashlight carried by the player.
##
## Mounted under the camera, it points where the camera looks but lags behind
## and sways slightly, as if held in a hand. The `flashlight` action toggles
## it; `toggled` is the hook for the on/off click sound (#19).

class_name Flashlight
extends Node3D

## Emitted after the light switches on or off.
signal toggled(is_on: bool)

## How quickly the beam catches up with the camera aim (higher is snappier).
@export var follow_responsiveness: float = 9.0

## Peak sway rotation in degrees.
@export var sway_amplitude: float = 0.6

## Sway speed in radians per second.
@export var sway_speed: float = 1.7

## Whether the light starts on.
@export var starts_on: bool = true

## The spotlight node (child).
@export var light: SpotLight3D

var _time: float = 0.0
var _beam_basis: Basis = Basis.IDENTITY


func _ready() -> void:
	_beam_basis = global_basis
	set_on(starts_on)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"flashlight"):
		toggle()


func _process(delta: float) -> void:
	_time += delta
	var parent := get_parent() as Node3D
	if parent == null:
		return
	_beam_basis = lagged_basis(_beam_basis, parent.global_basis, follow_responsiveness, delta)
	var sway: Vector3 = sway_offset(_time, deg_to_rad(sway_amplitude), sway_speed)
	global_basis = _beam_basis * Basis.from_euler(sway)


## Exponentially turns `current` toward `target`, frame-rate independent.
static func lagged_basis(
	current: Basis, target: Basis, responsiveness: float, delta: float
) -> Basis:
	var weight: float = 1.0 - exp(-responsiveness * delta)
	return current.orthonormalized().slerp(target.orthonormalized(), weight)


## Small smooth pitch and yaw offset (radians) for a handheld feel.
static func sway_offset(time: float, amplitude: float, speed: float) -> Vector3:
	return Vector3(sin(time * speed), cos(time * speed * 0.73), 0.0) * amplitude


## Returns whether the light is on.
func is_on() -> bool:
	return light != null and light.visible


## Switches the light on or off and emits `toggled` if the state changed.
func set_on(value: bool) -> void:
	if light == null:
		return
	var is_changed: bool = light.visible != value
	light.visible = value
	if is_changed:
		toggled.emit(value)


## Flips the light.
func toggle() -> void:
	set_on(not is_on())
