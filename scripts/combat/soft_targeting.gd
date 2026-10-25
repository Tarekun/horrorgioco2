## Soft targeting for melee swings: picks the nearest enemy near the swing
## direction. There is no lock-on; the player just turns toward the pick.

class_name SoftTargeting
extends RefCounted


## Returns the index in `candidates` (world positions) of the nearest one within
## `max_distance` and `max_angle_deg` (either side) of `reference_direction`,
## measured on the ground plane from `origin`. Returns -1 when none qualifies.
static func pick(
	origin: Vector3,
	reference_direction: Vector3,
	candidates: Array[Vector3],
	max_distance: float = 2.5,
	max_angle_deg: float = 60.0
) -> int:
	var reference := Vector3(reference_direction.x, 0.0, reference_direction.z)
	if reference.is_zero_approx():
		return -1
	reference = reference.normalized()

	var best: int = -1
	var best_distance: float = INF
	for i: int in candidates.size():
		var offset: Vector3 = candidates[i] - origin
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > max_distance or distance >= best_distance:
			continue
		# An enemy on top of the player is always in reach, whatever the angle.
		if distance > 0.001:
			var angle: float = rad_to_deg(reference.angle_to(offset / distance))
			if angle > max_angle_deg:
				continue
		best = i
		best_distance = distance
	return best
