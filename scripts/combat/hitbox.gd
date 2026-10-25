## Area that deals damage to Hurtboxes it overlaps.
##
## Inactive by default. activate() opens a hit window and forgets previous
## victims; each Hurtbox is damaged at most once per window. Set the collision
## mask to the opposing hurtbox layer (see CombatLayers).

class_name Hitbox
extends Area3D

## Emitted when a hurtbox was hit, with the damage dealt.
signal hit_landed(hurtbox: Hurtbox, damage_dealt: float)

## Base damage per hit.
@export var damage: float = 10.0

## Whether hits interrupt the victim.
@export var causes_stagger: bool = true

## The actor credited with the hits (for direction and attribution).
@export var attacker: Node3D

## Scales `damage` (partly charged heavy attacks).
var damage_multiplier: float = 1.0

## Set by the attacker for hits that knock a standard enemy down.
var causes_knockdown: bool = false

var is_active: bool = false

var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)


## Opens a hit window.
func activate() -> void:
	_already_hit.clear()
	is_active = true
	set_deferred(&"monitoring", true)


## Closes the hit window.
func deactivate() -> void:
	is_active = false
	set_deferred(&"monitoring", false)


## Builds the hit this box delivers to `target`.
func make_hit(target: Node3D) -> HitData:
	var direction := Vector3.ZERO
	var origin: Node3D = attacker if attacker else self
	var offset: Vector3 = target.global_position - origin.global_position
	offset.y = 0.0
	if not offset.is_zero_approx():
		direction = offset.normalized()
	var hit := HitData.create(damage * damage_multiplier, attacker, direction, causes_stagger)
	hit.causes_knockdown = causes_knockdown
	return hit


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or not is_active or _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	var dealt: float = hurtbox.receive_hit(make_hit(hurtbox))
	hit_landed.emit(hurtbox, dealt)
