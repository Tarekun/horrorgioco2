extends GutTest


func test_fine_is_60_to_100() -> void:
	assert_eq(HealthState.from_health(100.0), HealthState.State.FINE)
	assert_eq(HealthState.from_health(60.0), HealthState.State.FINE)


func test_caution_is_30_to_59() -> void:
	assert_eq(HealthState.from_health(59.0), HealthState.State.CAUTION)
	assert_eq(HealthState.from_health(59.5), HealthState.State.CAUTION)
	assert_eq(HealthState.from_health(30.0), HealthState.State.CAUTION)


func test_danger_is_below_30() -> void:
	assert_eq(HealthState.from_health(29.0), HealthState.State.DANGER)
	assert_eq(HealthState.from_health(29.9), HealthState.State.DANGER)
	assert_eq(HealthState.from_health(1.0), HealthState.State.DANGER)
	assert_eq(HealthState.from_health(0.0), HealthState.State.DANGER)


func test_danger_slows_every_speed_to_80_percent() -> void:
	assert_eq(HealthState.speed_multiplier(HealthState.State.DANGER), 0.8)
	assert_eq(HealthState.speed_multiplier(HealthState.State.CAUTION), 1.0)
	assert_eq(HealthState.speed_multiplier(HealthState.State.FINE), 1.0)


func test_each_state_has_a_name() -> void:
	assert_eq(HealthState.state_name(HealthState.State.FINE), "Fine")
	assert_eq(HealthState.state_name(HealthState.State.CAUTION), "Caution")
	assert_eq(HealthState.state_name(HealthState.State.DANGER), "Danger")
