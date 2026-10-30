## Stats of a melee weapon. Melee weapons never break. Defaults are the wooden
## plank from the gameplay spec, the fast weapon: its swing timings equal the
## placeholder clips' lengths. Slower weapons set longer timings, and the clips
## are stretched to match.

class_name MeleeWeapon
extends Resource

@export var display_name: String = "Wooden plank"

## Damage of each hit in the light combo; its size is the combo length.
@export var light_damage: PackedFloat32Array = PackedFloat32Array([8.0, 8.0, 12.0])

## Seconds each light swing lasts, one per hit (the last one reused if short).
@export var light_durations: PackedFloat32Array = PackedFloat32Array([0.45, 0.45, 0.65])

## Damage of a fully charged heavy attack.
@export var heavy_damage: float = 25.0

## Seconds the heavy swing lasts after release.
@export var heavy_duration: float = 0.8

## Stamina paid by a light swing and by a heavy attack.
@export var light_stamina: float = 10.0
@export var heavy_stamina: float = 20.0

## How far in front of the player the hitbox reaches (metres).
@export var reach: float = 1.6

## Fraction of a swing at which its hitbox opens and closes.
@export_range(0.0, 1.0) var active_start: float = 0.3
@export_range(0.0, 1.0) var active_end: float = 0.6

## Fraction at the end of a light swing during which a press queues the next hit.
@export_range(0.0, 1.0) var queue_window: float = 0.4

## Seconds of heavy charge before the attack starts charging, and until full.
@export var charge_start_time: float = 0.35
@export var charge_full_time: float = 1.0

## Heavy damage scale when released as soon as charging starts.
@export_range(0.0, 1.0) var charge_min_scale: float = 0.6

## Seconds the attacker freezes on contact.
@export var hitstop_duration: float = 0.05


## Number of hits in the light combo.
func combo_length() -> int:
	return light_damage.size()


## Duration of the light swing at `index` (0-based).
func light_duration(index: int) -> float:
	return light_durations[mini(index, light_durations.size() - 1)]


## Heavy damage scale (min to 1.0) for a button held `held` seconds in total.
func heavy_scale(held: float) -> float:
	var span: float = maxf(charge_full_time - charge_start_time, 0.001)
	var t: float = clampf((held - charge_start_time) / span, 0.0, 1.0)
	return lerpf(charge_min_scale, 1.0, t)


## Whether a button held `held` seconds is a full charge (knocks down).
func is_fully_charged(held: float) -> bool:
	return held >= charge_full_time
