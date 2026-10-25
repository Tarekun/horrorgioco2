## The player's dodge: a quick step in the input direction, or a backstep with
## no input.
##
## Per the gameplay spec the dodge covers 2.5 m (backstep 1.5 m) in 0.5 s, the
## first 0.25 s of which the player is invulnerable. It costs 20 stamina, paid
## in full up front, and after it ends there is a 0.2 s cooldown. It can start
## from idle or cancel the recovery of a melee swing (not a swing's windup or
## active window).

class_name PlayerDodge
extends Node

## Emitted when a dodge starts, with its world-space direction.
signal dodge_started(direction: Vector3)
## Emitted when a dodge ends (finished or interrupted).
signal dodge_finished

## Distance covered by a dodge and by a backstep (metres).
@export var distance: float = 2.5
@export var backstep_distance: float = 1.5

## Total seconds of a dodge, and how many of them are invulnerable.
@export var duration: float = 0.5
@export var invulnerable_duration: float = 0.25

## Stamina paid up front.
@export var stamina_cost: float = 20.0

## Seconds after a dodge ends before the next one can start.
@export var cooldown: float = 0.2

@export var player: Player
@export var stamina_component: StaminaComponent
@export var health_component: HealthComponent
@export var model: PlayerModel
@export var combat: PlayerCombat

## While false, no dodge can start (set during a hit stagger and after death).
var is_enabled: bool = true

var is_dodging: bool = false

var _elapsed: float = 0.0
var _cooldown_left: float = 0.0
var _direction: Vector3 = Vector3.ZERO
var _travel: float = 0.0


func _ready() -> void:
	# Run before the player so the velocity set here is used the same frame.
	process_physics_priority = -1


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"dodge"):
		try_dodge()
	tick(delta)


## Advances the dodge and its cooldown by `delta` seconds.
func tick(delta: float) -> void:
	if not is_dodging:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
		return

	var previous: float = _elapsed
	_elapsed = minf(_elapsed + delta, duration)
	var step: float = (
		distance_at(_elapsed, _travel, duration) - distance_at(previous, _travel, duration)
	)
	player.external_velocity = _direction * (step / delta)

	if _elapsed >= invulnerable_duration:
		health_component.is_invulnerable = false
	if _elapsed >= duration:
		_finish()


## Starts a dodge if allowed. Returns whether it started.
func try_dodge() -> bool:
	if not can_dodge():
		return false
	if not stamina_component.try_spend(stamina_cost):
		return false

	if combat.is_acting():
		combat.interrupt()

	var input_direction: Vector3 = player.get_movement_direction()
	var is_backstep: bool = input_direction.is_zero_approx()
	if is_backstep:
		# Away from where the player faces; facing is kept.
		_direction = player.global_basis.z
		_direction.y = 0.0
		_direction = _direction.normalized()
		_travel = backstep_distance
	else:
		_direction = input_direction
		_travel = distance
		player.rotation.y = atan2(-_direction.x, -_direction.z)

	is_dodging = true
	combat.is_enabled = false
	_elapsed = 0.0
	health_component.is_invulnerable = true
	player.is_movement_locked = true
	player.external_velocity = Vector3.ZERO
	model.play_action(&"backstep" if is_backstep else &"dodge")
	dodge_started.emit(_direction)
	return true


## Whether a dodge could start now, ignoring stamina: not already dodging, not
## cooling down, not dead, and not in the middle of a swing's windup or hit.
func can_dodge() -> bool:
	if not is_enabled or is_dodging or _cooldown_left > 0.0 or health_component.is_dead:
		return false
	var is_swinging: bool = (
		combat.state == PlayerCombat.State.SWING_LIGHT
		or combat.state == PlayerCombat.State.SWING_HEAVY
	)
	return not is_swinging or combat.is_in_recovery()


## Seconds of cooldown left (0 when ready).
func get_cooldown_left() -> float:
	return _cooldown_left


## Ends a dodge early without starting the cooldown (hit reaction, death).
func interrupt() -> void:
	if not is_dodging:
		return
	_finish()
	_cooldown_left = 0.0


## Distance covered `elapsed` seconds into a dodge of `total` metres lasting
## `duration`: a fast start easing out, so the speed falls linearly to zero.
static func distance_at(elapsed: float, total: float, dodge_duration: float) -> float:
	var t: float = clampf(elapsed / dodge_duration, 0.0, 1.0)
	return total * (2.0 * t - t * t)


func _finish() -> void:
	is_dodging = false
	combat.is_enabled = true
	health_component.is_invulnerable = false
	player.is_movement_locked = false
	player.external_velocity = Vector3.ZERO
	_cooldown_left = cooldown
	model.return_to_locomotion()
	dodge_finished.emit()
