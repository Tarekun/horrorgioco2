## The cues for the player's health state (see HealthState): the spec's Fine,
## Caution and Danger, shown only through the screen, audio and rumble.
##
## - Caution: a faint edge vignette and an occasional heavy breath.
## - Danger: a strong vignette and desaturation, a heartbeat that quickens as
##   health falls with a rumble pulse on every beat, and a limp at 0.8 times
##   every movement speed.
##
## A dead player gets no more sounds or rumble; the screen keeps its look.
## Timers advance in tick(), so tests can step them without waiting.

class_name PlayerHealthCues
extends Node

## Emitted when the health state changes.
signal state_changed(new_state: HealthState.State)
## Emitted each time the heartbeat sounds (and the gamepad pulses).
signal heartbeat_played
## Emitted each time a heavy breath sounds.
signal breath_played

## Edge vignette strength in Caution and in Danger (0 to 1).
@export_range(0.0, 1.0) var caution_vignette: float = 0.3
@export_range(0.0, 1.0) var danger_vignette: float = 0.75

## How much colour drains in Danger (0 to 1).
@export_range(0.0, 1.0) var danger_desaturation: float = 0.65

## Seconds between heartbeats just inside Danger (at 29 health) and at 1 health.
@export var slow_heartbeat_interval: float = 1.0
@export var fast_heartbeat_interval: float = 0.55

## Range of seconds between two breaths in Caution.
@export var breath_interval_min: float = 7.0
@export var breath_interval_max: float = 14.0

## Rumble pulse on a heartbeat: motor strengths and length in seconds.
@export var rumble_weak: float = 0.0
@export var rumble_strong: float = 0.35
@export var rumble_duration: float = 0.18

@export var health_component: HealthComponent
@export var player: Player
@export var model: PlayerModel
@export var overlay: HealthOverlay
@export var heartbeat_player: AudioStreamPlayer
@export var breath_player: AudioStreamPlayer

var state: HealthState.State = HealthState.State.FINE

var _heartbeat_left: float = 0.0
var _breath_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	heartbeat_player.bus = AudioBuses.SFX
	breath_player.bus = AudioBuses.SFX
	health_component.health_changed.connect(_on_health_changed)
	_update_state(health_component.current_health)


func _process(delta: float) -> void:
	tick(delta)


## Advances the heartbeat and breath timers by `delta` seconds.
func tick(delta: float) -> void:
	if health_component.is_dead:
		return
	match state:
		HealthState.State.DANGER:
			_heartbeat_left -= delta
			if _heartbeat_left <= 0.0:
				_beat()
		HealthState.State.CAUTION:
			_breath_left -= delta
			if _breath_left <= 0.0:
				_breathe()


## Seconds between heartbeats at `health` in Danger: slow at the top of the
## state, quick near death.
static func heartbeat_interval(health: float, slow: float, fast: float) -> float:
	var weight: float = clampf(health / HealthState.CAUTION_MIN, 0.0, 1.0)
	return lerpf(fast, slow, weight)


func _on_health_changed(new_health: float) -> void:
	_update_state(new_health)


func _update_state(health: float) -> void:
	var new_state: HealthState.State = HealthState.from_health(health)
	var is_changed: bool = new_state != state
	state = new_state
	match state:
		HealthState.State.FINE:
			overlay.set_targets(0.0, 0.0)
		HealthState.State.CAUTION:
			overlay.set_targets(caution_vignette, 0.0)
		HealthState.State.DANGER:
			overlay.set_targets(danger_vignette, danger_desaturation)
	player.speed_multiplier = HealthState.speed_multiplier(state)
	model.set_limp(1.0 if state == HealthState.State.DANGER else 0.0)

	if is_changed:
		# A new state starts its sounds soon, not a whole interval later.
		_heartbeat_left = 0.3
		_breath_left = _rng.randf_range(breath_interval_min, breath_interval_max)
		state_changed.emit(state)
	if state == HealthState.State.DANGER:
		# The heartbeat quickens as health drops, even within the state.
		_heartbeat_left = minf(
			_heartbeat_left,
			heartbeat_interval(health, slow_heartbeat_interval, fast_heartbeat_interval)
		)


func _beat() -> void:
	var interval: float = heartbeat_interval(
		health_component.current_health, slow_heartbeat_interval, fast_heartbeat_interval
	)
	_heartbeat_left = interval
	heartbeat_player.play()
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, rumble_weak, rumble_strong, rumble_duration)
	heartbeat_played.emit()


func _breathe() -> void:
	_breath_left = _rng.randf_range(breath_interval_min, breath_interval_max)
	breath_player.play()
	breath_played.emit()
