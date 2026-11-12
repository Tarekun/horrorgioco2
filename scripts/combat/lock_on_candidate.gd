## One enemy observed from the player at a given moment, as a candidate for
## the lock-on: where it is, whether the player can see it, and whether it
## is standing or downed. The aiming code builds one per enemy (for example
## from a PhysicsRayQuery3D line-of-sight check and the enemy's downed
## state); LockOn itself does no physics queries.

class_name LockOnCandidate
extends RefCounted

## The enemy's position in world space.
var position: Vector3
## Whether the player has a clear line of sight to the enemy.
var is_visible: bool
## Whether the enemy is standing; a downed enemy can still be locked and
## shot, it just is not preferred.
var is_standing: bool
## The enemy node the candidate was built from, or null when it was built
## without one: it is what the lock-on code locks on to.
var node: Node3D


func _init(position: Vector3, is_visible: bool, is_standing: bool, node: Node3D = null) -> void:
	self.position = position
	self.is_visible = is_visible
	self.is_standing = is_standing
	self.node = node
