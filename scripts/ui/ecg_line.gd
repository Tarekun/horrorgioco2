## A scrolling ECG trace for the inventory screen's status readout.
##
## Its rhythm, colour and strength follow the health state: a calm green beat
## when Fine, a quicker amber one in Caution and a fast, weak red one in Danger.
## It never shows a number. It keeps running while the game is paused, as the
## inventory screen pauses it.

class_name EcgLine
extends Control

## Beats per minute in Fine, Caution and Danger (indexed by HealthState.State).
@export var beats_per_minute: PackedFloat32Array = PackedFloat32Array([66.0, 96.0, 138.0])

## Trace colour in Fine, Caution and Danger.
@export var colors: PackedColorArray = PackedColorArray(
	[Color(0.45, 0.85, 0.5), Color(0.95, 0.75, 0.3), Color(0.9, 0.22, 0.18)]
)

## Height of the beat (1 fills half the control) in Fine, Caution and Danger.
@export var amplitudes: PackedFloat32Array = PackedFloat32Array([0.85, 0.8, 0.55])

## Seconds of trace visible across the width.
@export var window_seconds: float = 2.0

@export var line_width: float = 2.0

var state: HealthState.State = HealthState.State.FINE:
	set(value):
		state = value
		queue_redraw()

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var steps: int = maxi(int(size.x), 2)
	var beats_per_second: float = get_beats_per_minute() / 60.0
	var half_height: float = size.y * 0.5
	var height: float = half_height * amplitudes[state]
	var points := PackedVector2Array()
	for i: int in steps + 1:
		var fraction: float = float(i) / steps
		# The right edge is now; the trace scrolls to the left.
		var time: float = _time - window_seconds * (1.0 - fraction)
		var phase: float = fposmod(time * beats_per_second, 1.0)
		points.append(Vector2(size.x * fraction, half_height - sample(phase) * height))
	draw_polyline(points, get_color(), line_width, true)


## Beats per minute for the current state.
func get_beats_per_minute() -> float:
	return beats_per_minute[state]


## Trace colour for the current state.
func get_color() -> Color:
	return colors[state]


## Height of the trace (about -0.3 to 1) at `phase` (0 to 1) through a beat: a
## small P wave, the QRS spike and a T wave, flat in between.
static func sample(phase: float) -> float:
	return (
		0.12 * _bump(phase, 0.12, 0.035)
		- 0.15 * _bump(phase, 0.25, 0.012)
		+ 1.0 * _bump(phase, 0.29, 0.018)
		- 0.3 * _bump(phase, 0.33, 0.014)
		+ 0.25 * _bump(phase, 0.52, 0.05)
	)


static func _bump(x: float, center: float, width: float) -> float:
	var t: float = (x - center) / width
	return exp(-t * t)
