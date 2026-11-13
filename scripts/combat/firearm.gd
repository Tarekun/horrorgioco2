## Stats of a lock-on firearm, from the Weapon stats table of the gameplay
## spec. The defaults are the pistol; the shotgun is the same resource with
## its own numbers.
##
## The chance-related values (near/far chance, range, steadiness) are what a
## HitChance rolls with: apply_to() copies them over. The magazine and
## reloading are the PlayerFirearm's bookkeeping, and the noise radius feeds
## the NoiseEvent of each shot.

class_name Firearm
extends Resource

@export var display_name: String = "Pistol"

## Pellets per shot; a single-round firearm is one. The shotgun's spread
## rolls each pellet separately and does `damage` per pellet that hits.
@export var pellets: int = 1

## Pellets that must hit one standard enemy for it to be knocked down;
## 0 for none (the pistol).
@export var knockdown_pellets: int = 0

## Damage of each pellet that hits.
@export var damage: float = 20.0

## Hit chance at or inside the near distance, and at the far distance.
@export_range(0.0, 1.0) var near_chance: float = 0.90
@export var near_distance: float = 4.0
@export_range(0.0, 1.0) var far_chance: float = 0.35
@export var far_distance: float = 20.0

## No shot is possible beyond this (metres).
@export var max_range: float = 25.0

## Steadiness floor, seconds to climb from the floor to 1.0, and the drop of
## each shot.
@export_range(0.0, 1.0) var steady_min: float = 0.75
@export var steady_time: float = 0.8
@export_range(0.0, 1.0) var recoil: float = 0.15

## Seconds between shots.
@export var shot_interval: float = 0.35

## Rounds per magazine, and seconds a reload takes. With
## `per_shell_reload` (the shotgun) it is one shell at a time, interruptible
## by firing; otherwise (the pistol) it is the whole magazine in one fixed
## time.
@export var magazine_size: int = 10
@export var reload_time: float = 1.4
@export var per_shell_reload: bool = false

## Radius of the noise event each shot makes (25 m for the pistol,
## NoiseEvent.PISTOL_SHOT_RADIUS).
@export var noise_radius: float = 25.0

## The ammo item one magazine is reloaded from (pistol rounds, shotgun
## shells); unset on a bare resource, set on the data resources.
@export var ammo_item: ItemData


## Copies the chance values of this firearm into `hit_chance`, so the same
## HitChance rule serves every firearm.
func apply_to(hit_chance: HitChance) -> void:
	hit_chance.near_chance = near_chance
	hit_chance.near_distance = near_distance
	hit_chance.far_chance = far_chance
	hit_chance.far_distance = far_distance
	hit_chance.max_range = max_range
	hit_chance.steady_min = steady_min
	hit_chance.steady_time = steady_time
	hit_chance.recoil = recoil
