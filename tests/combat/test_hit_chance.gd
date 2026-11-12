## Tests for HitChance: the pure hit-chance rule of the Firearms spec.

extends GutTest

const ROLL_SEED: int = 1234

## First twelve randf() draws of a RandomNumberGenerator seeded with
## ROLL_SEED. If the engine's sequence ever changes, this test fails so
## the expected hit/miss sequences below get regenerated.
const SEED_1234: Array[float] = [
	0.10712034255266,
	0.45164075493813,
	0.02080162987113,
	0.65506416559219,
	0.57853931188583,
	0.93327957391739,
	0.96533179283142,
	0.7030456662178,
	0.23910176753998,
	0.9235874414444,
	0.68053114414215,
	0.34915998578072,
]


func after_each() -> void:
	Scarcity.use(null)


func _make_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ROLL_SEED
	return rng


## A HitChance with the pistol defaults and a seeded generator.
func _pistol() -> HitChance:
	return HitChance.new(_make_rng())


## Acquires a target and holds the aim until fully steady (steadiness 1.0).
func _steady(hit_chance: HitChance) -> void:
	hit_chance.acquire_target()
	hit_chance.update(hit_chance.steady_time * 2.0)


func test_the_recorded_seed_sequence_is_still_correct() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = ROLL_SEED
	for i: int in SEED_1234.size():
		assert_almost_eq(rng.randf(), SEED_1234[i], 0.000001)


func test_defaults_are_the_pistol_spec() -> void:
	var hit_chance: HitChance = _pistol()
	assert_almost_eq(hit_chance.near_chance, 0.90, 0.0001)
	assert_almost_eq(hit_chance.near_distance, 4.0, 0.0001)
	assert_almost_eq(hit_chance.far_chance, 0.35, 0.0001)
	assert_almost_eq(hit_chance.far_distance, 20.0, 0.0001)
	assert_almost_eq(hit_chance.max_range, 25.0, 0.0001)
	assert_almost_eq(hit_chance.steady_min, 0.75, 0.0001)
	assert_almost_eq(hit_chance.steady_time, 0.8, 0.0001)
	assert_almost_eq(hit_chance.recoil, 0.15, 0.0001)
	assert_almost_eq(hit_chance.player_moving_multiplier, 0.75, 0.0001)
	assert_almost_eq(hit_chance.target_moving_multiplier, 0.85, 0.0001)
	assert_almost_eq(hit_chance.target_impaired_multiplier, 1.15, 0.0001)
	assert_almost_eq(hit_chance.danger_health_multiplier, 0.85, 0.0001)
	assert_almost_eq(hit_chance.exhausted_multiplier, 0.85, 0.0001)


# --- base_chance ---


func test_base_chance_is_flat_at_or_inside_the_near_distance() -> void:
	var hit_chance: HitChance = _pistol()
	assert_almost_eq(hit_chance.base_chance(0.0), 0.90, 0.0001)
	assert_almost_eq(hit_chance.base_chance(2.0), 0.90, 0.0001)
	assert_almost_eq(hit_chance.base_chance(4.0), 0.90, 0.0001)


func test_base_chance_falls_linearly_to_the_far_chance_and_stays_flat() -> void:
	var hit_chance: HitChance = _pistol()
	assert_almost_eq(hit_chance.base_chance(6.0), 0.83125, 0.0001)
	assert_almost_eq(hit_chance.base_chance(12.0), 0.625, 0.0001)
	assert_almost_eq(hit_chance.base_chance(20.0), 0.35, 0.0001)
	assert_almost_eq(hit_chance.base_chance(24.0), 0.35, 0.0001)
	assert_almost_eq(hit_chance.base_chance(100.0), 0.35, 0.0001)


# --- range and clamp ---


func test_chance_cuts_off_beyond_the_maximum_range() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	assert_almost_eq(hit_chance.chance(25.0), 0.35, 0.0001)
	assert_eq(hit_chance.chance(25.001), 0.0)
	assert_eq(hit_chance.chance(100.0), 0.0)


func test_no_shot_is_certain() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	# 0.90 × 1.15 = 1.035, clamped down to 0.95.
	assert_almost_eq(hit_chance.chance(4.0, false, false, true, false, false), 0.95, 0.0001)
	# 0.90 on its own stays under the cap.
	assert_almost_eq(hit_chance.chance(4.0), 0.90, 0.0001)


func test_no_shot_is_hopeless_in_range() -> void:
	var hit_chance: HitChance = _pistol()
	hit_chance.near_chance = 0.10
	hit_chance.far_chance = 0.10
	hit_chance.acquire_target()
	# 0.10 × 0.75 × 0.75 × 0.85 × 0.85 × 0.85 ≈ 0.0345, clamped up to 0.05.
	var p: float = hit_chance.chance(20.0, true, true, false, true, true)
	assert_almost_eq(p, 0.05, 0.0001)


func test_the_clamp_bounds_come_from_the_scarcity_in_use() -> void:
	var scarcity := Scarcity.new()
	scarcity.hit_chance_min = 0.1
	scarcity.hit_chance_max = 0.8
	Scarcity.use(scarcity)
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	assert_almost_eq(hit_chance.chance(4.0, false, false, true, false, false), 0.8, 0.0001)
	var low: HitChance = _pistol()
	low.near_chance = 0.1
	low.far_chance = 0.1
	low.acquire_target()
	var p: float = low.chance(20.0, true, true, false, true, true)
	assert_almost_eq(p, 0.1, 0.0001)


# --- steadiness ---


func test_steadiness_starts_at_steady_min_and_waits_for_a_target() -> void:
	var hit_chance: HitChance = _pistol()
	assert_almost_eq(hit_chance.steadiness, hit_chance.steady_min, 0.0001)
	hit_chance.update(10.0)
	assert_almost_eq(hit_chance.steadiness, hit_chance.steady_min, 0.0001)
	hit_chance.acquire_target()
	assert_almost_eq(hit_chance.steadiness, hit_chance.steady_min, 0.0001)


func test_steadiness_rises_linearly_to_one_over_steady_time() -> void:
	var hit_chance: HitChance = _pistol()
	hit_chance.acquire_target()
	hit_chance.update(0.2)
	assert_almost_eq(hit_chance.steadiness, 0.8125, 0.0001)
	hit_chance.update(0.2)
	assert_almost_eq(hit_chance.steadiness, 0.875, 0.0001)
	hit_chance.update(0.4)
	assert_almost_eq(hit_chance.steadiness, 1.0, 0.0001)
	hit_chance.update(10.0)
	assert_almost_eq(hit_chance.steadiness, 1.0, 0.0001)


func test_a_zero_steady_time_is_fully_steady_at_once() -> void:
	var hit_chance: HitChance = _pistol()
	hit_chance.steady_time = 0.0
	hit_chance.acquire_target()
	hit_chance.update(0.001)
	assert_almost_eq(hit_chance.steadiness, 1.0, 0.0001)


func test_a_shot_subtracts_recoil_floored_at_steady_min() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	hit_chance.fire(4.0)
	assert_almost_eq(hit_chance.steadiness, 0.85, 0.0001)
	hit_chance.fire(4.0)
	assert_almost_eq(hit_chance.steadiness, 0.75, 0.0001)
	hit_chance.fire(4.0)
	assert_almost_eq(hit_chance.steadiness, 0.75, 0.0001)


func test_switching_targets_resets_the_steadiness() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	hit_chance.acquire_target()
	assert_almost_eq(hit_chance.steadiness, 0.75, 0.0001)


func test_chance_scales_with_the_steadiness() -> void:
	var hit_chance: HitChance = _pistol()
	hit_chance.acquire_target()
	assert_almost_eq(hit_chance.chance(12.0), 0.625 * 0.75, 0.0001)
	hit_chance.update(hit_chance.steady_time)
	assert_almost_eq(hit_chance.chance(12.0), 0.625, 0.0001)


# --- modifiers ---


func test_the_shot_conditions_multiply_the_chance() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	assert_almost_eq(hit_chance.chance(12.0), 0.625, 0.0001)
	assert_almost_eq(
		hit_chance.chance(12.0, true, false, false, false, false), 0.625 * 0.75, 0.0001
	)
	assert_almost_eq(
		hit_chance.chance(12.0, false, true, false, false, false), 0.625 * 0.85, 0.0001
	)
	assert_almost_eq(
		hit_chance.chance(12.0, false, false, true, false, false), 0.625 * 1.15, 0.0001
	)
	assert_almost_eq(
		hit_chance.chance(12.0, false, false, false, true, false), 0.625 * 0.85, 0.0001
	)
	assert_almost_eq(
		hit_chance.chance(12.0, false, false, false, false, true), 0.625 * 0.85, 0.0001
	)
	assert_almost_eq(
		hit_chance.chance(12.0, true, true, true, true, true),
		0.625 * 0.75 * 0.85 * 1.15 * 0.85 * 0.85,
		0.0001
	)


# --- the roll ---


func test_a_seeded_rng_makes_the_rolls_reproducible() -> void:
	var first: HitChance = _pistol()
	var second: HitChance = _pistol()
	var first_results: Array[bool] = []
	var second_results: Array[bool] = []
	for i: int in 12:
		first.acquire_target()
		second.acquire_target()
		first_results.append(first.fire(4.0))
		second_results.append(second.fire(4.0))
	assert_eq(first_results, second_results)


func test_the_seeded_roll_sequence_matches_the_spec_values() -> void:
	# Each shot re-acquires, so every roll is against p = 0.90 × 0.75 = 0.675.
	var hit_chance: HitChance = _pistol()
	var results: Array[bool] = []
	for i: int in 12:
		hit_chance.acquire_target()
		results.append(hit_chance.fire(4.0))
	assert_eq(
		results, [true, true, true, true, true, false, false, false, true, false, false, true]
	)


func test_a_burst_drops_the_steadiness_shot_by_shot() -> void:
	var hit_chance: HitChance = _pistol()
	hit_chance.acquire_target()
	hit_chance.update(hit_chance.steady_time * 2.0)
	var results: Array[bool] = []
	for i: int in 5:
		results.append(hit_chance.fire(20.0))
	# The recoil eats the steadiness, so the chance of the burst drops from
	# 0.35 × 1.0 to 0.35 × 0.85, then 0.35 × 0.75 for the rest:
	# 0.107 < 0.35 hit; 0.452 > 0.2975 miss; 0.021 < 0.2625 hit;
	# 0.655 and 0.579 above 0.2625: miss, miss.
	assert_eq(results, [true, false, true, false, false])
	assert_almost_eq(hit_chance.steadiness, 0.75, 0.0001)


func test_beyond_the_maximum_range_the_shot_is_a_miss() -> void:
	var hit_chance: HitChance = _pistol()
	_steady(hit_chance)
	assert_false(hit_chance.fire(25.5))
	assert_almost_eq(hit_chance.steadiness, 0.85, 0.0001)
