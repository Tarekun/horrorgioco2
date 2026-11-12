## The hit-chance rule of the lock-on firearms, from the Firearms section of
## the gameplay spec. Every shot rolls
##
##     p = base_chance(distance) × steadiness × modifiers
##
## clamped to the hit-chance bounds of the Scarcity in use, and p = 0 beyond
## the maximum range: no shot is certain, none is hopeless in range. No aim
## skill is involved; the only randomness is the injected
## RandomNumberGenerator, which tests seed for deterministic rolls.
##
## The steadiness is state: it starts at steady_min when a target is
## acquired, climbs to 1.0 over steady_time while the aim is held, drops by
## recoil on every shot (floored at steady_min), and a target switch
## re-acquires it.
##
## All the weapon values are data on the instance (defaults: the pistol of
## the spec table), so the pistol and shotgun resources feed the same rule.

class_name HitChance
extends RefCounted

## Hit chance at or inside the near distance, and at the far distance;
## base_chance() falls linearly between the two and stays flat beyond.
var near_chance: float = 0.90
var near_distance: float = 4.0
var far_chance: float = 0.35
var far_distance: float = 20.0

## No shot is possible beyond this distance (metres).
var max_range: float = 25.0

## Steadiness floor, seconds to climb from the floor to 1.0, and the drop
## of each shot.
var steady_min: float = 0.75
var steady_time: float = 0.8
var recoil: float = 0.15

## Multipliers of the shot conditions, multiplied together.
var player_moving_multiplier: float = 0.75
var target_moving_multiplier: float = 0.85
## Multiplier while the target is staggered or downed.
var target_impaired_multiplier: float = 1.15
## Multiplier while the player is in Danger health.
var danger_health_multiplier: float = 0.85
## Multiplier while the player is exhausted (stamina).
var exhausted_multiplier: float = 0.85

## The steadiness of the aim, 0 to 1. Before the first target it is
## steady_min.
var steadiness: float:
	get:
		return _steadiness if _acquired else steady_min

var _rng: RandomNumberGenerator
var _steadiness: float = 0.0
var _acquired: bool = false


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Called when the lock-on acquires a target, or when it switches to
## another one: the steadiness starts again from steady_min.
func acquire_target() -> void:
	_acquired = true
	_steadiness = steady_min


## Advances the steadiness toward 1.0 over steady_time. Call it every frame
## while aiming; nothing changes before a target is acquired.
func update(delta: float) -> void:
	if not _acquired or delta <= 0.0:
		return
	if steady_time <= 0.0:
		_steadiness = 1.0
		return
	var climb: float = (1.0 - steady_min) / steady_time
	_steadiness = minf(_steadiness + climb * delta, 1.0)


## The chance before steadiness and modifiers, from the target's distance:
## near_chance at or inside near_distance, falling linearly to far_chance
## at far_distance, and flat beyond.
func base_chance(distance: float) -> float:
	var span: float = maxf(far_distance - near_distance, 0.001)
	var t: float = clampf((distance - near_distance) / span, 0.0, 1.0)
	return lerpf(near_chance, far_chance, t)


## The hit chance of a shot at `distance` metres with the given shot
## conditions. Beyond the maximum range it is 0; otherwise
## base_chance × steadiness × the condition multipliers, held within the
## hit-chance bounds of the Scarcity in use.
func chance(
	distance: float,
	is_player_moving: bool = false,
	is_target_moving: bool = false,
	is_target_impaired: bool = false,
	is_in_danger: bool = false,
	is_exhausted: bool = false
) -> float:
	if distance > max_range:
		return 0.0
	var p: float = (
		base_chance(distance)
		* steadiness
		* _condition_multiplier(
			is_player_moving, is_target_moving, is_target_impaired, is_in_danger, is_exhausted
		)
	)
	return Scarcity.current().clamp_hit_chance(p)


## Rolls a shot at `distance` metres with the given conditions, consuming
## one randf() of the injected generator. The shot rolls with the
## steadiness before the recoil, and the recoil then drops the steadiness
## for the next shot.
func fire(
	distance: float,
	is_player_moving: bool = false,
	is_target_moving: bool = false,
	is_target_impaired: bool = false,
	is_in_danger: bool = false,
	is_exhausted: bool = false
) -> bool:
	var hit: bool = (
		_rng.randf()
		< chance(
			distance,
			is_player_moving,
			is_target_moving,
			is_target_impaired,
			is_in_danger,
			is_exhausted
		)
	)
	_steadiness = maxf(steady_min, _steadiness - recoil)
	return hit


## The product of the multipliers of the conditions that apply to the shot.
func _condition_multiplier(
	is_player_moving: bool,
	is_target_moving: bool,
	is_target_impaired: bool,
	is_in_danger: bool,
	is_exhausted: bool
) -> float:
	var multiplier: float = 1.0
	if is_player_moving:
		multiplier *= player_moving_multiplier
	if is_target_moving:
		multiplier *= target_moving_multiplier
	if is_target_impaired:
		multiplier *= target_impaired_multiplier
	if is_in_danger:
		multiplier *= danger_health_multiplier
	if is_exhausted:
		multiplier *= exhausted_multiplier
	return multiplier
