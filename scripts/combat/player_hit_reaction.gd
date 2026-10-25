## How the player reacts to damage and death.
##
## A hit that doesn't kill staggers the player: any attack or dodge is
## interrupted, the body is locked for a moment and the hit clip plays. It also
## triggers the cues of the gameplay spec (never numbers or bars): a red flash
## at the screen edge, a short camera shake, gamepad rumble, and an audio cue
## for whoever owns the audio buses to hook up.
##
## A lethal hit kills the player instead: all input stops for good, the death
## clip plays, and after a short delay the game over screen appears.
##
## Timers advance in tick(), so tests can step them without waiting.

class_name PlayerHitReaction
extends Node

## Emitted when a hit staggers the player.
signal staggered
## Emitted once when the player dies.
signal player_died
## Emitted for each cue the audio system can hook: &"player_hit" or &"player_death".
signal audio_cue_requested(cue: StringName, intensity: float)

## Seconds the player is staggered by a hit.
@export var stagger_duration: float = 0.4

## Seconds between dying and the game over screen.
@export var game_over_delay: float = 1.5

## Camera shake: amplitude (metres) at full intensity and duration.
@export var shake_amplitude: float = 0.1
@export var shake_duration: float = 0.25

## Rumble duration in seconds at full intensity.
@export var rumble_duration: float = 0.3

@export var player: Player
@export var health_component: HealthComponent
@export var combat: PlayerCombat
@export var dodge: PlayerDodge
@export var model: PlayerModel
@export var camera_controller: CameraController
@export var damage_overlay: DamageOverlay
@export var game_over_screen: GameOverScreen

var is_staggered: bool = false
var is_dead: bool = false

var _stagger_left: float = 0.0
var _game_over_left: float = 0.0


func _ready() -> void:
	health_component.damage_taken.connect(_on_damage_taken)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	tick(delta)


## Advances the stagger and game over timers by `delta` seconds.
func tick(delta: float) -> void:
	if is_staggered:
		_stagger_left -= delta
		if _stagger_left <= 0.0:
			_end_stagger()
	if is_dead and _game_over_left > 0.0:
		_game_over_left -= delta
		if _game_over_left <= 0.0:
			game_over_screen.show_screen()


## Strength (0 to 1) of the cues for a hit of `damage` on a pool of
## `max_health`: 20 damage on 100 health is 0.7.
static func hit_intensity(damage: float, max_health: float) -> float:
	return clampf(0.3 + damage / maxf(max_health, 1.0) * 2.0, 0.0, 1.0)


func _on_damage_taken(amount: float, _attacker: Node3D) -> void:
	var intensity: float = hit_intensity(amount, health_component.max_health)
	damage_overlay.flash(intensity)
	camera_controller.shake(shake_amplitude * intensity, shake_duration)
	_rumble(intensity)
	audio_cue_requested.emit(&"player_hit", intensity)

	# Lethal hits are handled by died; the player doesn't stagger first.
	if health_component.current_health <= 0.0 or is_dead:
		return
	_interrupt_actions()
	is_staggered = true
	_stagger_left = stagger_duration
	player.is_movement_locked = true
	model.play_action(&"hit")
	staggered.emit()


func _on_died() -> void:
	is_dead = true
	is_staggered = false
	_interrupt_actions()
	# Nothing re-enables these.
	combat.is_enabled = false
	dodge.is_enabled = false
	player.is_movement_locked = true
	player.external_velocity = Vector3.ZERO
	model.play_action(&"death")
	_game_over_left = game_over_delay
	audio_cue_requested.emit(&"player_death", 1.0)
	player_died.emit()


func _interrupt_actions() -> void:
	combat.interrupt()
	dodge.interrupt()
	combat.is_enabled = false
	dodge.is_enabled = false
	player.external_velocity = Vector3.ZERO


func _end_stagger() -> void:
	is_staggered = false
	combat.is_enabled = true
	dodge.is_enabled = true
	player.is_movement_locked = false
	model.return_to_locomotion()


func _rumble(intensity: float) -> void:
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, intensity * 0.5, intensity, rumble_duration * intensity)
