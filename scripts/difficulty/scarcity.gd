## Every value that sets how scarce and dangerous the game is, in one place so
## difficulty presets can scale them later: how much a pickup holds, how tough
## and hard-hitting enemies are, and the clamp on a firearm's hit chance.
##
## The game uses one default, assets/data/scarcity.tres. Scarcity.current()
## returns the one in use; use() swaps in another.

class_name Scarcity
extends Resource

const DEFAULT_PATH: String = "res://assets/data/scarcity.tres"

static var _current: Scarcity

@export_group("Pickups")
## How many of each item (by id) a standard pickup holds. Unlisted items: 1.
@export var pickup_amounts: Dictionary[StringName, int] = {}

@export_group("Enemies")
## A standard enemy's health.
@export var enemy_max_health: float = 100.0
## Each hit of a standard enemy deals a random amount in this range.
@export var enemy_damage_min: float = 15.0
@export var enemy_damage_max: float = 25.0

@export_group("Firearms")
## Bounds of a shot's hit chance: no shot is certain, none hopeless in range.
@export_range(0.0, 1.0) var hit_chance_min: float = 0.05
@export_range(0.0, 1.0) var hit_chance_max: float = 0.95


## The scarcity in use: the default unless use() replaced it.
static func current() -> Scarcity:
	if _current == null:
		_current = load(DEFAULT_PATH) as Scarcity
	return _current


## Makes `preset` the scarcity in use; null goes back to the default.
static func use(preset: Scarcity) -> void:
	_current = preset


## How many of `item` a standard pickup holds.
func pickup_amount(item: ItemData) -> int:
	if item == null:
		return 0
	return pickup_amounts.get(item.id, 1)


## The damage of one enemy hit, rolled with `rng`.
func roll_enemy_damage(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(enemy_damage_min, enemy_damage_max)


## `chance` held within the hit-chance bounds.
func clamp_hit_chance(chance: float) -> float:
	return clampf(chance, hit_chance_min, hit_chance_max)
