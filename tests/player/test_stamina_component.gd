## Unit tests for StaminaComponent drain, regeneration, and exhaustion logic.

extends GutTest


func _make_stamina() -> StaminaComponent:
	var stamina := StaminaComponent.new()
	add_child_autofree(stamina)
	return stamina


## Calls _process in small steps so the total elapsed time is `total_delta`.
func _simulate(stamina: StaminaComponent, total_delta: float) -> void:
	var steps: int = roundi(total_delta / 0.01)
	for i: int in steps:
		stamina._process(0.01)


# --- Initial state ---


func test_starts_at_max_stamina() -> void:
	var stamina := _make_stamina()
	assert_eq(stamina.current_stamina, 100.0)
	assert_true(stamina.can_sprint())


func test_refill_uses_tuned_max_stamina() -> void:
	var stamina := _make_stamina()
	stamina.max_stamina = 50.0
	stamina.refill()
	assert_eq(stamina.current_stamina, 50.0)


# --- Drain ---


func test_drains_while_sprinting() -> void:
	var stamina := _make_stamina()
	stamina.start_sprinting()
	_simulate(stamina, 2.0)
	assert_almost_eq(stamina.current_stamina, 70.0, 0.1, "15/s for 2 s")
	assert_true(stamina.is_draining)


func test_does_not_drain_when_not_sprinting() -> void:
	var stamina := _make_stamina()
	_simulate(stamina, 2.0)
	assert_eq(stamina.current_stamina, 100.0)


func test_drain_stops_at_zero_and_exhausts() -> void:
	var stamina := _make_stamina()
	stamina.max_stamina = 10.0
	stamina.refill()
	watch_signals(stamina)
	stamina.start_sprinting()
	_simulate(stamina, 1.0)

	assert_eq(stamina.current_stamina, 0.0)
	assert_true(stamina.is_exhausted)
	assert_false(stamina.is_draining, "sprint ends at 0")
	assert_signal_emit_count(stamina, "exhausted", 1)


func test_cannot_start_sprinting_when_exhausted() -> void:
	var stamina := _make_stamina()
	stamina.max_stamina = 10.0
	stamina.refill()
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	assert_false(stamina.start_sprinting())


# --- Regeneration ---


func test_regenerates_after_delay() -> void:
	var stamina := _make_stamina()
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	stamina.stop_sprinting()

	# 1.0 s idle: 0.8 s delay, then 0.2 s at 25/s = 5 gained, from 85.
	_simulate(stamina, 1.0)
	assert_almost_eq(stamina.current_stamina, 90.0, 0.6)


func test_no_regeneration_during_delay() -> void:
	var stamina := _make_stamina()
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	stamina.stop_sprinting()

	_simulate(stamina, 0.5)
	assert_almost_eq(stamina.current_stamina, 85.0, 0.1)


func test_regenerates_to_max_and_no_further() -> void:
	var stamina := _make_stamina()
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	stamina.stop_sprinting()
	_simulate(stamina, 5.0)
	assert_eq(stamina.current_stamina, 100.0)


# --- Exhaustion threshold ---


func test_can_sprint_below_threshold_when_not_exhausted() -> void:
	# The spec blocks sprinting below the threshold only after hitting 0.
	var stamina := _make_stamina()
	stamina.current_stamina = 20.0
	assert_true(stamina.can_sprint())


func test_exhaustion_lasts_until_above_threshold() -> void:
	var stamina := _make_stamina()
	stamina.max_stamina = 10.0
	stamina.refill()
	stamina.max_stamina = 100.0
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	assert_true(stamina.is_exhausted)

	# 0.8 s delay, then 25/s: after 1.5 s total stamina is ~17.5, still exhausted.
	_simulate(stamina, 1.5)
	assert_true(stamina.is_exhausted, "still below 30")
	assert_false(stamina.can_sprint())

	# 1 more second: ~42.5, recovered.
	_simulate(stamina, 1.0)
	assert_false(stamina.is_exhausted)
	assert_true(stamina.can_sprint())


# --- Signals and reuse ---


func test_stamina_changed_only_when_value_changes() -> void:
	var stamina := _make_stamina()
	watch_signals(stamina)
	_simulate(stamina, 1.0)
	assert_signal_not_emitted(stamina, "stamina_changed")
	stamina.start_sprinting()
	_simulate(stamina, 0.1)
	assert_signal_emitted(stamina, "stamina_changed")


func test_instances_are_independent() -> void:
	var a := _make_stamina()
	var b := _make_stamina()
	a.start_sprinting()
	_simulate(a, 1.0)
	_simulate(b, 1.0)
	assert_almost_eq(a.current_stamina, 85.0, 0.1)
	assert_eq(b.current_stamina, 100.0)
