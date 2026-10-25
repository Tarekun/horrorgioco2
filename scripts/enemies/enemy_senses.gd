## What an enemy observed in one frame, the input of EnemyBrain.tick().

class_name EnemySenses
extends RefCounted

## The enemy is aware of the player (or of where they were last seen).
var has_target: bool = false

## Close enough to the target to strike, and the attack is off cooldown.
var can_attack: bool = false

## The walk to the current wander point is over.
var has_arrived: bool = false

## The attack swing has finished.
var is_attack_finished: bool = false
