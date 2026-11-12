## Lock-on target selection for the firearms, from the Aiming section of
## the gameplay spec: the lock is the nearest enemy that is visible, within
## weapon range and inside the 70° cone in front of the camera, and
## standing enemies are preferred over downed ones — a downed enemy is only
## locked when no standing one qualifies. `next_target` cycles through the
## valid candidates ordered by angle around the camera forward.
##
## The rule is pure data in / data out, so it is testable without a scene:
## the aiming code (a later slice) collects one LockOnCandidate per enemy —
## position, a line-of-sight result, and the standing/downed state — and
## feeds the candidates in. LockOn performs no physics queries and keeps no
## state of its own.
##
## A candidate is valid when it is visible, at most `max_range` metres from
## the camera and at most `cone_angle_deg` from the camera forward. The
## range and the cone edge are inclusive: exactly `max_range` and exactly
## `cone_angle_deg` count. A candidate closer to the camera than
## MIN_DISTANCE is ignored, because the aim direction is undefined there.

class_name LockOn
extends RefCounted

## Maximum angle, in degrees, from the camera forward for a candidate to be
## inside the aiming cone (70° in the spec).
const CONE_ANGLE_DEG: float = 70.0

## Candidates closer than this (metres) are ignored.
const MIN_DISTANCE: float = 0.001


## The index in `candidates` of the locked target, or -1 when none is
## valid: the nearest valid candidate, with standing enemies preferred over
## downed ones (a downed candidate only wins when no standing one is
## valid). Ties on distance keep the earlier candidate in the array.
static func select(
	camera_position: Vector3,
	camera_forward: Vector3,
	max_range: float,
	candidates: Array[LockOnCandidate],
	cone_angle_deg: float = CONE_ANGLE_DEG
) -> int:
	if camera_forward.is_zero_approx():
		return -1
	var forward: Vector3 = camera_forward.normalized()
	var cos_cone: float = cos(deg_to_rad(cone_angle_deg))
	var best: int = _nearest_valid(candidates, camera_position, forward, cos_cone, max_range, true)
	if best == -1:
		best = _nearest_valid(candidates, camera_position, forward, cos_cone, max_range, false)
	return best


## All the valid candidates, in ascending signed angle around the camera
## forward — from -180° (left) to +180° (right) as seen looking along the
## forward — so the `next_target` cycle is deterministic. Ties on angle
## break by distance, then by position in `candidates`. Empty when nothing
## is valid.
static func ordered(
	camera_position: Vector3,
	camera_forward: Vector3,
	max_range: float,
	candidates: Array[LockOnCandidate],
	cone_angle_deg: float = CONE_ANGLE_DEG
) -> Array[int]:
	var valid: Array[int] = []
	if camera_forward.is_zero_approx():
		return valid
	var forward: Vector3 = camera_forward.normalized()
	var right: Vector3 = _perpendicular_reference(forward)
	var cos_cone: float = cos(deg_to_rad(cone_angle_deg))
	var angles: PackedFloat64Array = PackedFloat64Array()
	var distances: PackedFloat64Array = PackedFloat64Array()
	angles.resize(candidates.size())
	distances.resize(candidates.size())
	for i: int in candidates.size():
		var candidate: LockOnCandidate = candidates[i]
		var offset: Vector3 = candidate.position - camera_position
		var distance: float = offset.length()
		distances[i] = distance
		if distance <= MIN_DISTANCE:
			continue
		angles[i] = rad_to_deg(atan2(offset.dot(right), offset.dot(forward)))
		if _is_valid(candidate, distance, offset.dot(forward) / distance, cos_cone, max_range):
			valid.append(i)
	valid.sort_custom(
		func(a: int, b: int) -> bool:
			if angles[a] != angles[b]:
				return angles[a] < angles[b]
			if distances[a] != distances[b]:
				return distances[a] < distances[b]
			return a < b
	)
	return valid


## The target to lock after `next_target`, while `current` (an index in
## `candidates`, or -1 when nothing is locked) is locked: the next valid
## candidate in angle order, wrapping around the end of the list. When
## `current` is no longer valid, or nothing is valid, the result is -1.
static func cycle(
	current: int,
	camera_position: Vector3,
	camera_forward: Vector3,
	max_range: float,
	candidates: Array[LockOnCandidate],
	cone_angle_deg: float = CONE_ANGLE_DEG
) -> int:
	var valid: Array[int] = ordered(
		camera_position, camera_forward, max_range, candidates, cone_angle_deg
	)
	if valid.is_empty():
		return -1
	var position: int = valid.find(current)
	if position == -1:
		return valid[0]
	return valid[(position + 1) % valid.size()]


## The nearest valid candidate, looking only at standing enemies when
## `standing_only` is set. Returns -1 when none is valid.
static func _nearest_valid(
	candidates: Array[LockOnCandidate],
	camera_position: Vector3,
	forward: Vector3,
	cos_cone: float,
	max_range: float,
	standing_only: bool
) -> int:
	var best: int = -1
	var best_distance: float = INF
	for i: int in candidates.size():
		var candidate: LockOnCandidate = candidates[i]
		if standing_only and not candidate.is_standing:
			continue
		var offset: Vector3 = candidate.position - camera_position
		var distance: float = offset.length()
		if distance <= MIN_DISTANCE:
			continue
		if not _is_valid(candidate, distance, offset.dot(forward) / distance, cos_cone, max_range):
			continue
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


## Whether the candidate is visible, within `max_range` and inside the
## cone. `cosine` is the dot product of the normalised offset with the
## camera forward: the higher it is, the closer the candidate is to the
## forward.
static func _is_valid(
	candidate: LockOnCandidate, distance: float, cosine: float, cos_cone: float, max_range: float
) -> bool:
	return (
		candidate.is_visible
		and distance > MIN_DISTANCE
		and distance <= max_range
		and cosine >= cos_cone
	)


## A unit vector perpendicular to `forward`, pointing to the right of it as
## seen looking along it, used as the reference for signed angles.
static func _perpendicular_reference(forward: Vector3) -> Vector3:
	var reference := Vector3.UP
	if absf(forward.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	return forward.cross(reference).normalized()
