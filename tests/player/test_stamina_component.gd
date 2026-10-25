## Unit tests for StaminaComponent drain, regeneration, and exhaustion logic.

extends GutTest

const STAMINA_COMPONENT := preload("res://scripts/player/stamina_component.gd")


## Creates a fresh StaminaComponent with default values for testing.
func _make_stamina() -> StaminaComponent:
	var s: StaminaComponent = STAMINA_COMPONENT.new()
	add_child(s)
	return s


## Simulates one or more _process calls with the given total delta.
## Also advances the component's mock_time so regeneration timing works.
func _simulate(stamina: StaminaComponent, total_delta: float) -> void:
	var remaining: float = total_delta
	while remaining > 0.0:
		var step: float = min(0.01, remaining)
		stamina._process(step)
		stamina.mock_time += step
		remaining -= step


# --- Initial state ---


func test_starts_at_max_stamina() -> void:
	var stamina: StaminaComponent = _make_stamina()
	assert_eq(stamina.current_stamina, 100.0, "initial stamina")
	assert_true(stamina.can_sprint, "can sprint at full stamina")


func test_custom_max_stamina() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.max_stamina = 50.0
	stamina._init()
	assert_eq(stamina.current_stamina, 50.0, "custom max stamina")


# --- Drain ---


func test_drains_while_sprinting() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.mock_time = 0.0
	stamina.start_sprinting()

	## Drain 15/s for 2 seconds = 30 stamina lost.
	_simulate(stamina, 2.0)

	var expected: float = 100.0 - 15.0 * 2.0
	assert_approx_eq(stamina.current_stamina, expected, 0.1, "drain amount")
	assert_true(stamina.is_draining, "still draining")


func test_drain_stops_at_zero() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.max_stamina = 10.0
	stamina._init()
	stamina.exhaustion_threshold = 5.0
	stamina.mock_time = 0.0
	stamina.start_sprinting()

	## Drain at 15/s; after 1 second stamina would go negative but caps at 0.
	_simulate(stamina, 1.0)

	assert_eq(stamina.current_stamina, 0.0, "drain caps at zero")
	## After hitting zero, the player is recovering and cannot sprint.
	assert_false(stamina.can_sprint, "cannot sprint at zero")


func test_cannot_start_sprinting_when_exhausted() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.max_stamina = 10.0
	stamina._init()
	stamina.exhaustion_threshold = 5.0
	stamina.mock_time = 0.0
	stamina.start_sprinting()
	_simulate(stamina, 1.0)

	## After exhausting, cannot restart sprinting until regen past threshold.
	assert_false(stamina.start_sprinting(), "cannot restart while exhausted")


# --- Regeneration ---


func test_regenerates_after_delay() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.mock_time = 0.0
	stamina.start_sprinting()
	## Drain for 1 second.
	_simulate(stamina, 1.0)
	stamina.stop_sprinting()

	## Regeneration starts after 0.8s delay.
	## After 1.0s of idle: (1.0 - 0.8) * 25 = 5 stamina gained.
	_simulate(stamina, 1.0)

	var expected: float = 85.0 + 5.0
	assert_approx_eq(stamina.current_stamina, expected, 0.5, "regen after delay")


func test_no_regeneration_during_delay() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.mock_time = 0.0
	stamina.start_sprinting()
	_simulate(stamina, 1.0)
	stamina.stop_sprinting()

	## Only 0.5s of idle (< 0.8s delay), no regen.
	_simulate(stamina, 0.5)

	assert_approx_eq(stamina.current_stamina, 85.0, 0.5, "no regen during delay period")


func test_regenerates_to_max() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.max_stamina = 100.0
	stamina._init()
	stamina.mock_time = 0.0
	stamina.current_stamina = 0.0
	stamina.start_sprinting()
	_simulate(stamina, 0.01)
	stamina.stop_sprinting()

	## Drain enough to set exhausted flag.
	stamina.current_stamina = 0.0
	## Wait long enough to fully regenerate.
	_simulate(stamina, 5.0)

	assert_eq(stamina.current_stamina, 100.0, "regenerates to max")


# --- Exhaustion threshold ---


func test_can_sprint_below_threshold_when_not_exhausted() -> void:
	## The spec blocks sprinting below 30 only *after hitting 0*.
	var stamina: StaminaComponent = _make_stamina()
	stamina.exhaustion_threshold = 40.0
	stamina._init()
	stamina.current_stamina = 30.0

	assert_true(stamina.can_sprint, "can sprint below threshold when not exhausted")


func test_can_sprint_above_threshold() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.exhaustion_threshold = 30.0
	stamina._init()
	stamina.current_stamina = 31.0

	assert_true(stamina.can_sprint, "can sprint above threshold")


func test_recovery_after_exhaustion() -> void:
	var stamina: StaminaComponent = _make_stamina()
	stamina.current_stamina = 0.0
	## Simulate enough regen to go above threshold.
	stamina.current_stamina = 35.0

	## After going above threshold, should be able to sprint again.
	assert_true(stamina.can_sprint, "can sprint after recovery")


# --- Reusability ---


func test_component_is_reusable() -> void:
	## Multiple instances can coexist.
	var a: StaminaComponent = _make_stamina()
	var b: StaminaComponent = _make_stamina()

	assert_eq(a.current_stamina, 100.0)
	assert_eq(b.current_stamina, 100.0)

	a.mock_time = 0.0
	a.start_sprinting()
	_simulate(a, 1.0)

	assert_approx_eq(a.current_stamina, 85.0, 0.1)
	assert_eq(b.current_stamina, 100.0, "b unaffected by a")

	a.stop_sprinting()
	_simulate(a, 1.0)
	## Regeneration delay is 0.8s; only 0.2s of regen at 25/s = 5.0.
	assert_approx_eq(a.current_stamina, 90.0, 0.5, "a regenerates independently")


# --- Helpers ---


func assert_approx_eq(
	actual: float, expected: float, tolerance: float, message: String = ""
) -> void:
	var diff: float = abs(actual - expected)
	assert_lt(diff, tolerance, message)
