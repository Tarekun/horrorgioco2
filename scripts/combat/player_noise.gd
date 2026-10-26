## The noise the player makes, for enemy hearing.
##
## Footsteps are loud when running and louder when sprinting, and silent when
## walking. Every melee hit that lands is loud. Gunshots will use
## NoiseEvent.emit_noise() with the weapon's radius.

class_name PlayerNoise
extends Node

## Footstep speeds (m/s) from which a step is a run or a sprint. The sprint
## threshold sits below a sprint in Danger health (5.5 x 0.8 = 4.4) and above a
## normal run (3.5).
@export var run_speed: float = 2.5
@export var sprint_speed: float = 4.0

## Noise radii in metres.
@export var run_radius: float = NoiseEvent.RUN_FOOTSTEP_RADIUS
@export var sprint_radius: float = NoiseEvent.SPRINT_FOOTSTEP_RADIUS
@export var melee_hit_radius: float = NoiseEvent.MELEE_HIT_RADIUS

@export var player: Player
@export var model: PlayerModel
@export var combat: PlayerCombat


func _ready() -> void:
	model.footstep_taken.connect(_on_footstep_taken)
	combat.hit_landed.connect(_on_hit_landed)


## Radius of a footstep taken at `speed`: none when walking.
func footstep_radius(speed: float) -> float:
	if speed >= sprint_speed:
		return sprint_radius
	if speed >= run_speed:
		return run_radius
	return 0.0


func _on_footstep_taken(speed: float) -> void:
	NoiseEvent.emit_noise(get_tree(), player.global_position, footstep_radius(speed))


func _on_hit_landed(_hurtbox: Hurtbox, damage_dealt: float) -> void:
	if damage_dealt > 0.0:
		NoiseEvent.emit_noise(get_tree(), player.global_position, melee_hit_radius)
