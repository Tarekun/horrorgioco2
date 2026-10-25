## Describes one hit travelling from a Hitbox to a Hurtbox.

class_name HitData
extends RefCounted

## Health removed (before invulnerability checks).
var damage: float = 0.0

## The actor that dealt the hit, if known.
var attacker: Node3D

## World-space horizontal direction from the attacker towards the victim.
var direction: Vector3 = Vector3.ZERO

## Whether the hit interrupts the victim (stagger).
var causes_stagger: bool = true

## Whether the hit knocks a standard enemy down (fully charged heavy attack).
var causes_knockdown: bool = false


static func create(
	hit_damage: float,
	hit_attacker: Node3D = null,
	hit_direction: Vector3 = Vector3.ZERO,
	hit_stagger: bool = true
) -> HitData:
	var data := HitData.new()
	data.damage = hit_damage
	data.attacker = hit_attacker
	data.direction = hit_direction
	data.causes_stagger = hit_stagger
	return data
