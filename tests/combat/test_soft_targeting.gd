## Tests for SoftTargeting.pick and MeleeWeapon rules.

extends GutTest

const PLANK: MeleeWeapon = preload("res://assets/data/weapons/wooden_plank.tres")


func _pick(reference: Vector3, positions: Array[Vector3]) -> int:
	return SoftTargeting.pick(Vector3.ZERO, reference, positions)


func _at_angle(degrees: float, distance: float) -> Vector3:
	var radians: float = deg_to_rad(degrees)
	return Vector3(sin(radians), 0.0, -cos(radians)) * distance


func test_picks_the_nearest_in_front() -> void:
	var positions: Array[Vector3] = [Vector3(0, 0, -2.0), Vector3(0, 0, -1.0)]
	assert_eq(_pick(Vector3.FORWARD, positions), 1)


func test_ignores_enemies_beyond_range() -> void:
	var positions: Array[Vector3] = [Vector3(0, 0, -2.6)]
	assert_eq(_pick(Vector3.FORWARD, positions), -1)


func test_ignores_enemies_outside_the_cone() -> void:
	var behind: Array[Vector3] = [Vector3(0, 0, 1.5)]
	assert_eq(_pick(Vector3.FORWARD, behind), -1)
	var at_70: Array[Vector3] = [_at_angle(70.0, 1.5)]
	assert_eq(_pick(Vector3.FORWARD, at_70), -1)
	var at_50: Array[Vector3] = [_at_angle(50.0, 1.5)]
	assert_eq(_pick(Vector3.FORWARD, at_50), 0)


func test_cone_follows_the_reference_direction() -> void:
	var positions: Array[Vector3] = [Vector3(1.5, 0, 0)]
	assert_eq(_pick(Vector3.FORWARD, positions), -1)
	assert_eq(_pick(Vector3.RIGHT, positions), 0)


func test_height_is_ignored() -> void:
	var positions: Array[Vector3] = [Vector3(0, 3.0, -1.0)]
	assert_eq(_pick(Vector3.FORWARD, positions), 0)


func test_a_height_limit_skips_candidates_above_or_below() -> void:
	var positions: Array[Vector3] = [Vector3(0, -3.2, -0.5), Vector3(0, 0.2, -1.0)]
	assert_eq(SoftTargeting.pick(Vector3.ZERO, Vector3.FORWARD, positions, 2.5, 60.0, 2.0), 1)
	var only_below: Array[Vector3] = [Vector3(0, -3.2, -0.5)]
	assert_eq(SoftTargeting.pick(Vector3.ZERO, Vector3.FORWARD, only_below, 2.5, 60.0, 2.0), -1)


func test_no_candidates_or_no_direction() -> void:
	var none: Array[Vector3] = []
	assert_eq(_pick(Vector3.FORWARD, none), -1)
	var positions: Array[Vector3] = [Vector3(0, 0, -1.0)]
	assert_eq(_pick(Vector3.ZERO, positions), -1)


# --- MeleeWeapon ---


func test_plank_matches_the_spec() -> void:
	assert_eq(PLANK.light_damage, PackedFloat32Array([8.0, 8.0, 12.0]))
	assert_eq(PLANK.heavy_damage, 25.0)
	assert_eq(PLANK.light_stamina, 10.0)
	assert_eq(PLANK.heavy_stamina, 20.0)
	assert_eq(PLANK.reach, 1.6)
	assert_eq(PLANK.combo_length(), 3)
	assert_eq(PLANK.hitstop_duration, 0.05)


func test_heavy_scale_runs_from_60_to_100_percent() -> void:
	assert_almost_eq(PLANK.heavy_scale(0.35), 0.6, 0.001)
	assert_almost_eq(PLANK.heavy_scale(1.0), 1.0, 0.001)
	assert_almost_eq(PLANK.heavy_scale(5.0), 1.0, 0.001)
	assert_between(PLANK.heavy_scale(0.675), 0.75, 0.85)


func test_only_a_full_charge_knocks_down() -> void:
	assert_false(PLANK.is_fully_charged(0.99))
	assert_true(PLANK.is_fully_charged(1.0))


func test_light_duration_reuses_the_last_entry() -> void:
	assert_almost_eq(PLANK.light_duration(0), 0.45, 0.001)
	assert_almost_eq(PLANK.light_duration(2), 0.65, 0.001)
	assert_almost_eq(PLANK.light_duration(7), 0.65, 0.001)
