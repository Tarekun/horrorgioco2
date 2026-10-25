## Area that can be hurt: forwards hits from Hitboxes to a HealthComponent.
##
## Passive; it is detected by Hitboxes whose mask includes this layer. The
## owner reacts to hits (stagger, hit reaction) through `hit_received`.

class_name Hurtbox
extends Area3D

## Emitted for every hit that reaches this hurtbox, with the damage dealt.
signal hit_received(hit: HitData, damage_dealt: float)

## The health this hurtbox damages.
@export var health_component: HealthComponent


## Applies a hit. Returns the damage dealt (0 when invulnerable or dead).
func receive_hit(hit: HitData) -> float:
	var dealt: float = 0.0
	if health_component:
		dealt = health_component.take_damage(hit.damage, hit.attacker)
	hit_received.emit(hit, dealt)
	return dealt
