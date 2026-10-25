## Health pool with damage, healing and death, reusable by any actor.
##
## Values are floats so scaled damage (a partly charged heavy swing) is exact.
## Death is reported once; a dead actor takes no further damage or healing
## until revive() is called. While `is_invulnerable` is set (a dodge window),
## incoming damage is ignored.

class_name HealthComponent
extends Node

## Emitted whenever current health changes.
signal health_changed(new_value: float)
## Emitted when damage was actually applied.
signal damage_taken(amount: float, attacker: Node3D)
## Emitted when healing was actually applied.
signal healed(amount: float)
## Emitted once when health reaches 0.
signal died

## Maximum health.
@export var max_health: float = 100.0

## Ignore incoming damage while true.
var is_invulnerable: bool = false

var current_health: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


## Applies `amount` damage. Returns the damage actually dealt (0 when dead,
## invulnerable or `amount` is not positive).
func take_damage(amount: float, attacker: Node3D = null) -> float:
	if is_dead or is_invulnerable or amount <= 0.0:
		return 0.0

	var dealt: float = minf(amount, current_health)
	current_health -= dealt
	damage_taken.emit(dealt, attacker)
	health_changed.emit(current_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()
	return dealt


## Restores up to `amount` health. Returns the amount actually restored.
func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0

	var restored: float = minf(amount, max_health - current_health)
	if restored <= 0.0:
		return 0.0
	current_health += restored
	healed.emit(restored)
	health_changed.emit(current_health)
	return restored


## Brings a dead actor back with `health` (default: full health).
func revive(health: float = -1.0) -> void:
	is_dead = false
	current_health = max_health if health < 0.0 else clampf(health, 1.0, max_health)
	health_changed.emit(current_health)


## Health as a fraction of the maximum (0 to 1).
func get_ratio() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0
