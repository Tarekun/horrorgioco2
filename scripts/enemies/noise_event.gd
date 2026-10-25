## Noise the player makes, which enemies may hear.
##
## A noise is a position and a radius. Emitters call emit_noise(); every
## EnemyPerception in the `hearing` group within the radius reacts. There is no
## global state to reset: it is a call to the group.

class_name NoiseEvent
extends RefCounted

## Group of the nodes that hear noises. They implement `hear_noise(position, radius)`.
const HEARING_GROUP: StringName = &"hearing"

## Noise radii (metres) of the gameplay spec.
const MELEE_HIT_RADIUS: float = 8.0
const SPRINT_FOOTSTEP_RADIUS: float = 6.0
const RUN_FOOTSTEP_RADIUS: float = 3.0
const PISTOL_SHOT_RADIUS: float = 25.0
const SHOTGUN_SHOT_RADIUS: float = 30.0


## Makes a noise at `position` that carries `radius` metres.
static func emit_noise(tree: SceneTree, position: Vector3, radius: float) -> void:
	if radius <= 0.0:
		return
	tree.call_group(HEARING_GROUP, &"hear_noise", position, radius)


## Whether a noise of `radius` at `source` reaches a listener at `listener`.
static func is_audible(listener: Vector3, source: Vector3, radius: float) -> bool:
	return radius > 0.0 and listener.distance_to(source) <= radius
