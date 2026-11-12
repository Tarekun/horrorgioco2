## Tests for the LockOn target-selection rule of the lock-on firearms.
##
## The camera sits at the origin looking along Vector3.FORWARD, which in
## Godot 4 points to -Z. _at_angle(degrees, distance) places a candidate
## `degrees` to the right of the forward, so its signed angle in LockOn's
## convention (right reference = forward x up) is exactly +degrees.

extends GutTest


func _candidates(
	positions: Array[Vector3], visible: bool = true, standing: bool = true
) -> Array[LockOnCandidate]:
	var candidates: Array[LockOnCandidate] = []
	for position in positions:
		candidates.append(LockOnCandidate.new(position, visible, standing))
	return candidates


func _at_angle(degrees: float, distance: float) -> Vector3:
	var radians: float = deg_to_rad(degrees)
	return Vector3(sin(radians), 0.0, -cos(radians)) * distance


func _select(candidates: Array[LockOnCandidate], max_range: float = 25.0) -> int:
	return LockOn.select(Vector3.ZERO, Vector3.FORWARD, max_range, candidates)


func test_no_candidates_is_no_target() -> void:
	assert_eq(_select(_candidates([])), -1)


func test_a_zero_forward_is_no_target() -> void:
	var candidates := _candidates([Vector3(0, 0, -1.0)])
	assert_eq(LockOn.select(Vector3.ZERO, Vector3.ZERO, 25.0, candidates), -1)


func test_ignores_candidates_beyond_range() -> void:
	var beyond := _candidates([Vector3(0, 0, -25.5)])
	assert_eq(_select(beyond, 25.0), -1)


func test_ignores_candidates_outside_the_cone() -> void:
	var behind := _candidates([Vector3(0, 0, 2.0)])
	assert_eq(_select(behind), -1)
	assert_eq(_select(_candidates([_at_angle(80.0, 2.0)])), -1)
	assert_eq(_select(_candidates([_at_angle(50.0, 2.0)])), 0)


func test_ignores_candidates_the_player_cannot_see() -> void:
	var hidden := _candidates([Vector3(0, 0, -2.0)], false)
	assert_eq(_select(hidden), -1)


func test_the_range_and_cone_edges_count() -> void:
	# A candidate exactly 25 m ahead is in range; the cone boundary is
	# checked at angles clearly on either side of the 70° edge.
	var at_range := _candidates([Vector3(0, 0, -25.0)])
	assert_eq(_select(at_range, 25.0), 0)
	var at_edge := _candidates([_at_angle(69.0, 2.0)])
	assert_eq(_select(at_edge, 25.0), 0)
	var just_out := _candidates([_at_angle(71.0, 2.0)])
	assert_eq(_select(just_out, 25.0), -1)


func test_picks_the_nearest_valid_candidate() -> void:
	var candidates := _candidates([Vector3(0, 0, -8.0), _at_angle(30.0, 4.0), Vector3(0, 0, -2.0)])
	assert_eq(_select(candidates), 2)


func test_standing_candidates_beat_nearer_downed_ones() -> void:
	var candidates := _candidates([_at_angle(20.0, 3.0)], true, false)
	candidates.append(LockOnCandidate.new(_at_angle(-20.0, 6.0), true, true))
	assert_eq(_select(candidates), 1)


func test_a_downed_candidate_locks_when_no_standing_one_qualifies() -> void:
	var candidates := _candidates([Vector3(0, 0, -30.0), Vector3(0, 0, -2.0)], true, false)
	assert_eq(_select(candidates, 25.0), 1)
	var hidden_only := _candidates([Vector3(0, 0, -2.0), _at_angle(40.0, 4.0)], false, true)
	hidden_only[1].is_visible = true
	assert_eq(_select(hidden_only), 1)


func test_ordered_list_is_by_signed_angle_then_distance() -> void:
	var positions: Array[Vector3] = [
		_at_angle(-40.0, 6.0),
		_at_angle(20.0, 4.0),
		_at_angle(-40.0, 3.0),
		Vector3(0, 0, -5.0),
		_at_angle(40.0, 7.0),
	]
	var order := LockOn.ordered(Vector3.ZERO, Vector3.FORWARD, 25.0, _candidates(positions))
	# Signed angles: idx0 and idx2 sit at -40°, idx1 at +20°, idx3 at 0°,
	# idx4 at +40°. The -40° tie breaks by distance: the 3 m idx2 before
	# the 6 m idx0.
	assert_eq(order, [2, 0, 3, 1, 4])


func test_ordered_list_skips_invalid_candidates() -> void:
	var candidates := _candidates(
		[
			Vector3(0, 0, -30.0),  # out of range
			_at_angle(80.0, 3.0),  # outside the cone
			Vector3(0, 0, -3.0),
		]
	)
	assert_eq(LockOn.ordered(Vector3.ZERO, Vector3.FORWARD, 25.0, candidates), [2])


func test_cycle_walks_the_ordered_list_and_wraps() -> void:
	var candidates := _candidates(
		[
			_at_angle(40.0, 5.0),  # cycle angle +40
			_at_angle(-40.0, 5.0),  # cycle angle -40
		]
	)
	var first: int = LockOn.select(Vector3.ZERO, Vector3.FORWARD, 25.0, candidates)
	assert_eq(first, 0)
	var second: int = LockOn.cycle(first, Vector3.ZERO, Vector3.FORWARD, 25.0, candidates)
	assert_eq(second, 1)
	var wrapped: int = LockOn.cycle(second, Vector3.ZERO, Vector3.FORWARD, 25.0, candidates)
	assert_eq(wrapped, 0)


func test_cycle_falls_back_to_the_first_when_current_stops_validating() -> void:
	var candidates := _candidates(
		[
			_at_angle(40.0, 5.0),
			_at_angle(-40.0, 5.0),
		]
	)
	# The current target walked out of range: the cycle starts over at the
	# first valid candidate.
	candidates[0].position = Vector3(0, 0, -40.0)
	var result: int = LockOn.cycle(0, Vector3.ZERO, Vector3.FORWARD, 25.0, candidates)
	assert_eq(result, 1)


func test_cycle_is_no_target_when_nothing_is_valid() -> void:
	assert_eq(LockOn.cycle(0, Vector3.ZERO, Vector3.FORWARD, 25.0, _candidates([])), -1)
