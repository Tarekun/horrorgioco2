## Builds the list of lock-on candidates from the enemy group: one
## LockOnCandidate per live enemy — its position, a line-of-sight result
## from the observer, and its standing state — for LockOn to select from.
##
## A candidate is visible when a ray from the observer to it hits nothing on
## `obstruction_mask`. The group members are excluded from the ray, so
## enemies never block each other's sight. Enemy scripts are duck-typed, so
## the scanner works with any group member: death is an `is_dead()` method,
## being downed an `is_downed()` method, being staggered an `is_staggered`
## property.
##
## The scanner keeps no state and does no selecting of its own; call scan()
## whenever fresh candidates are needed.

class_name LockOnScanner
extends Node

## Squared distance (metres) under which the observer and the candidate are
## taken to be at the same spot; the sight ray would be degenerate and is
## treated as clear.
const SAME_SPOT_DISTANCE_SQ: float = 0.0001

## The group holding the enemies to scan.
@export var enemy_group: StringName = &"enemies"

## Physics layers that block the line of sight.
@export_flags_3d_physics var obstruction_mask: int = CombatLayers.WORLD


## One LockOnCandidate per live enemy in `enemy_group`, as seen from
## `observer`. The order of the list is not meaningful; LockOn re-orders it.
func scan(observer: Node3D) -> Array[LockOnCandidate]:
	var members: Array[Node] = get_tree().get_nodes_in_group(enemy_group)
	var excluded: Array[RID] = _excluded_bodies(members)
	var candidates: Array[LockOnCandidate] = []
	for node: Node in members:
		var enemy := node as Node3D
		if enemy == null or _is_dead(enemy):
			continue
		candidates.append(
			LockOnCandidate.new(
				enemy.global_position, _can_see(observer, enemy, excluded), _is_standing(enemy)
			)
		)
	return candidates


## The physics bodies of the group members, so that none of them blocks the
## sight ray from the observer to another enemy.
func _excluded_bodies(members: Array[Node]) -> Array[RID]:
	var rids: Array[RID] = []
	for node: Node in members:
		var body := node as PhysicsBody3D
		if body != null:
			rids.append(body.get_rid())
	return rids


## Whether the ray from the observer to `enemy` hits nothing on
## `obstruction_mask`. `excluded` are the bodies that never block.
func _can_see(observer: Node3D, enemy: Node3D, excluded: Array[RID]) -> bool:
	var from: Vector3 = observer.global_position
	var to: Vector3 = enemy.global_position
	if from.distance_squared_to(to) < SAME_SPOT_DISTANCE_SQ:
		return true
	var query := PhysicsRayQueryParameters3D.create(from, to, obstruction_mask)
	query.exclude = excluded
	var result: Dictionary = observer.get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty()


## Duck-typed: the enemy is dead when it exposes an is_dead() method.
func _is_dead(node: Node) -> bool:
	if not node.has_method(&"is_dead"):
		return false
	return bool(node.call(&"is_dead"))


## Duck-typed: the enemy is standing unless it is downed (an is_downed()
## method) or staggered (an is_staggered property).
func _is_standing(node: Node) -> bool:
	var is_downed: bool = false
	if node.has_method(&"is_downed"):
		is_downed = bool(node.call(&"is_downed"))
	var is_staggered: bool = node.get("is_staggered") == true
	return not (is_downed or is_staggered)
