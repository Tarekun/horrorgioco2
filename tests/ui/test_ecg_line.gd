## Tests for the status readout's ECG trace.

extends GutTest

var _line: EcgLine


func before_each() -> void:
	_line = EcgLine.new()
	_line.size = Vector2(240, 56)
	add_child_autofree(_line)


func test_the_spike_is_the_highest_point_of_a_beat() -> void:
	var peak_phase: float = 0.0
	var peak: float = -INF
	for step: int in 1000:
		var phase: float = step / 1000.0
		if EcgLine.sample(phase) > peak:
			peak = EcgLine.sample(phase)
			peak_phase = phase
	assert_almost_eq(peak, 1.0, 0.05)
	assert_almost_eq(peak_phase, 0.29, 0.01)


func test_the_line_is_flat_between_beats() -> void:
	assert_almost_eq(EcgLine.sample(0.0), 0.0, 0.01)
	assert_almost_eq(EcgLine.sample(0.8), 0.0, 0.01)
	assert_almost_eq(EcgLine.sample(0.99), 0.0, 0.01)


func test_the_beat_quickens_with_worse_health() -> void:
	_line.state = HealthState.State.FINE
	var fine: float = _line.get_beats_per_minute()
	_line.state = HealthState.State.CAUTION
	var caution: float = _line.get_beats_per_minute()
	_line.state = HealthState.State.DANGER
	var danger: float = _line.get_beats_per_minute()
	assert_lt(fine, caution)
	assert_lt(caution, danger)


func test_each_state_has_its_own_colour() -> void:
	var colors: Array[Color] = []
	for state: HealthState.State in [
		HealthState.State.FINE, HealthState.State.CAUTION, HealthState.State.DANGER
	]:
		_line.state = state
		assert_false(colors.has(_line.get_color()))
		colors.append(_line.get_color())
