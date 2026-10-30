## The cues for the player's stamina, which has no bar.
##
## - Breathing gets heavier (louder and faster) as stamina drops, and stays
##   silent while it is high.
## - Reaching 0 plays a short winded animation: the player doubles over,
##   unable to move for a moment, with a gasp.
## - Breathing calms as stamina regenerates: it eases off more slowly than it
##   built up, so a hard sprint leaves a few calming breaths.
##
## An exhaustion that comes while another action drives the body (the end of a
## dodge or an attack, a stagger) skips the winded animation: that action's
## own animation is already playing. Timers advance in tick(), so tests can
## step them without waiting.

class_name PlayerStaminaCues
extends Node

## Emitted when the winded animation starts.
signal winded

## The animation state played when winded (see tools/generate_player_model.gd).
const WINDED_ACTION: StringName = &"winded"

## Stamina (as a fraction of the maximum) above which breathing is silent.
@export_range(0.0, 1.0) var quiet_above: float = 0.7

## Volume (dB) and speed of the breathing at a full effort. Quiet effort sits
## at `quiet_volume_db` and `quiet_pitch`.
@export var heavy_volume_db: float = -3.0
@export var quiet_volume_db: float = -24.0
@export var heavy_pitch: float = 1.5
@export var quiet_pitch: float = 0.85

## How fast the breathing effort builds and calms, in effort (0 to 1) per second.
@export var build_rate: float = 3.0
@export var calm_rate: float = 0.5

## Seconds the player is winded for, unable to move.
@export var winded_duration: float = 0.9

@export var stamina_component: StaminaComponent
@export var player: Player
@export var model: PlayerModel
@export var breathing_player: AudioStreamPlayer
@export var gasp_player: AudioStreamPlayer

## How hard the player is breathing now (0 to 1).
var effort: float = 0.0

var is_winded: bool = false

var _winded_left: float = 0.0


func _ready() -> void:
	breathing_player.bus = AudioBuses.SFX
	gasp_player.bus = AudioBuses.SFX
	breathing_player.finished.connect(_on_breath_finished)
	stamina_component.exhausted.connect(_on_exhausted)


func _process(delta: float) -> void:
	tick(delta)


## Advances the breathing and the winded timer by `delta` seconds.
func tick(delta: float) -> void:
	var target: float = breathing_effort(
		stamina_component.current_stamina / maxf(stamina_component.max_stamina, 0.001), quiet_above
	)
	var rate: float = build_rate if target > effort else calm_rate
	effort = move_toward(effort, target, rate * delta)
	_update_breathing()

	if is_winded:
		_winded_left -= delta
		if _winded_left <= 0.0:
			_end_winded()


## How hard breathing is (0 to 1) at a stamina `ratio` (0 to 1): none at or
## above `quiet_above`, full at 0.
static func breathing_effort(ratio: float, quiet_limit: float) -> float:
	if quiet_limit <= 0.0:
		return 0.0
	return clampf((quiet_limit - ratio) / quiet_limit, 0.0, 1.0)


func _update_breathing() -> void:
	if effort <= 0.0:
		breathing_player.stop()
		return
	breathing_player.volume_db = lerpf(quiet_volume_db, heavy_volume_db, effort)
	breathing_player.pitch_scale = lerpf(quiet_pitch, heavy_pitch, effort)
	if not breathing_player.playing:
		breathing_player.play()


# A breath is one cycle of the sample; the next starts when it ends, if the
# player is still out of breath.
func _on_breath_finished() -> void:
	if effort > 0.0:
		breathing_player.play()


func _on_exhausted() -> void:
	if is_winded or player.is_movement_locked:
		return
	is_winded = true
	_winded_left = winded_duration
	player.is_movement_locked = true
	player.external_velocity = Vector3.ZERO
	model.play_action(WINDED_ACTION)
	gasp_player.play()
	winded.emit()


func _end_winded() -> void:
	is_winded = false
	# If something else took over the body meanwhile (a hit, death), leave it.
	if model.get_current_state() != WINDED_ACTION:
		return
	player.is_movement_locked = false
	model.return_to_locomotion()
