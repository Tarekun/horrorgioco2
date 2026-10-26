## Scene-level tests of the health state cues, with the real player scene.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _cues: PlayerHealthCues
var _health: HealthComponent


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_cues = _player.get_node("PlayerHealthCues") as PlayerHealthCues
	_health = _player.health_component
	_cues.breath_interval_min = 1.0
	_cues.breath_interval_max = 1.0


func _set_health(value: float) -> void:
	_health.current_health = value
	_health.health_changed.emit(value)


func _settle() -> void:
	_cues.overlay.tick(10.0)


func test_wiring() -> void:
	assert_eq(_cues.health_component, _health)
	assert_eq(_cues.player, _player)
	assert_not_null(_cues.model)
	assert_not_null(_cues.overlay)
	assert_not_null(_cues.heartbeat_player.stream)
	assert_not_null(_cues.breath_player.stream)
	assert_eq(_cues.heartbeat_player.bus, AudioBuses.SFX)
	assert_eq(_cues.breath_player.bus, AudioBuses.SFX)
	assert_not_null(_cues.model.limp_pivot)


func test_fine_has_no_cues() -> void:
	_set_health(100.0)
	_settle()
	assert_eq(_cues.state, HealthState.State.FINE)
	assert_eq(_cues.overlay.vignette, 0.0)
	assert_eq(_cues.overlay.desaturation, 0.0)
	assert_eq(_player.speed_multiplier, 1.0)
	watch_signals(_cues)
	_cues.tick(60.0)
	assert_signal_not_emitted(_cues, "heartbeat_played")
	assert_signal_not_emitted(_cues, "breath_played")


func test_caution_has_a_faint_vignette_and_occasional_breaths() -> void:
	_set_health(45.0)
	_settle()
	assert_eq(_cues.state, HealthState.State.CAUTION)
	assert_almost_eq(_cues.overlay.vignette, _cues.caution_vignette, 0.001)
	assert_eq(_cues.overlay.desaturation, 0.0)
	assert_lt(_cues.caution_vignette, _cues.danger_vignette)
	assert_eq(_player.speed_multiplier, 1.0)
	watch_signals(_cues)
	_cues.tick(0.5)
	assert_signal_not_emitted(_cues, "breath_played")
	_cues.tick(0.6)
	assert_signal_emit_count(_cues, "breath_played", 1)
	assert_signal_not_emitted(_cues, "heartbeat_played")


func test_danger_has_a_strong_vignette_and_desaturation() -> void:
	_set_health(20.0)
	_settle()
	assert_eq(_cues.state, HealthState.State.DANGER)
	assert_almost_eq(_cues.overlay.vignette, _cues.danger_vignette, 0.001)
	assert_almost_eq(_cues.overlay.desaturation, _cues.danger_desaturation, 0.001)


func test_danger_beats_and_pulses_the_gamepad() -> void:
	_set_health(20.0)
	watch_signals(_cues)
	_cues.tick(0.4)
	assert_signal_emit_count(_cues, "heartbeat_played", 1)
	assert_true(_cues.heartbeat_player.playing)
	_cues.tick(0.3)
	assert_signal_emit_count(_cues, "heartbeat_played", 1, "waits for the next beat")
	_cues.tick(1.0)
	assert_signal_emit_count(_cues, "heartbeat_played", 2)


func test_the_heartbeat_quickens_as_health_falls() -> void:
	var slow := PlayerHealthCues.heartbeat_interval(29.0, 1.0, 0.55)
	var fast := PlayerHealthCues.heartbeat_interval(1.0, 1.0, 0.55)
	assert_lt(fast, slow)
	assert_almost_eq(slow, 1.0, 0.05)
	assert_almost_eq(fast, 0.55, 0.05)


func test_danger_slows_movement_and_limps() -> void:
	_set_health(20.0)
	assert_eq(_player.speed_multiplier, 0.8)
	assert_almost_eq(_player.get_node("Model").get_limp(), 0.0, 0.001, "eases in")
	for i in 120:
		_player.model._process(1.0 / 60.0)
	assert_gt(_player.model.get_limp(), 0.9)


func test_healing_out_of_danger_restores_speed_and_clears_the_screen() -> void:
	_set_health(20.0)
	_settle()
	_set_health(80.0)
	_settle()
	assert_eq(_cues.state, HealthState.State.FINE)
	assert_eq(_player.speed_multiplier, 1.0)
	assert_eq(_cues.overlay.vignette, 0.0)
	assert_eq(_cues.overlay.desaturation, 0.0)


func test_state_changes_are_announced_once() -> void:
	watch_signals(_cues)
	_set_health(50.0)
	_set_health(45.0)
	_set_health(10.0)
	assert_signal_emit_count(_cues, "state_changed", 2)


func test_no_sounds_after_death() -> void:
	_health.take_damage(95.0)
	_health.take_damage(10.0)
	assert_true(_health.is_dead)
	watch_signals(_cues)
	_cues.tick(5.0)
	assert_signal_not_emitted(_cues, "heartbeat_played")


func test_the_overlay_eases_instead_of_popping() -> void:
	_set_health(20.0)
	_cues.overlay.tick(0.1)
	assert_gt(_cues.overlay.vignette, 0.0)
	assert_lt(_cues.overlay.vignette, _cues.danger_vignette)


func test_the_multiplier_scales_the_speed() -> void:
	# With no input the player is at walking pace.
	assert_almost_eq(_player._get_current_speed(), _player.walk_speed, 0.001)
	_set_health(20.0)
	assert_almost_eq(_player._get_current_speed(), _player.walk_speed * 0.8, 0.001)
