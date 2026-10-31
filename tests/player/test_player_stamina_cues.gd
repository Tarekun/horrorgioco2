## Scene-level tests of the stamina cues, with the real player scene.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _cues: PlayerStaminaCues
var _stamina: StaminaComponent


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_cues = _player.get_node("PlayerStaminaCues") as PlayerStaminaCues
	_stamina = _player.stamina_component


func _set_stamina(value: float) -> void:
	_stamina.current_stamina = value
	_cues.tick(10.0)


func test_wiring() -> void:
	assert_eq(_cues.stamina_component, _stamina)
	assert_eq(_cues.player, _player)
	assert_not_null(_cues.model)
	assert_not_null(_cues.breathing_player.stream)
	assert_not_null(_cues.gasp_player.stream)
	assert_eq(_cues.breathing_player.bus, AudioBuses.SFX)
	assert_eq(_cues.gasp_player.bus, AudioBuses.SFX)


func test_effort_is_none_when_stamina_is_high_and_full_at_zero() -> void:
	assert_eq(PlayerStaminaCues.breathing_effort(1.0, 0.7), 0.0)
	assert_eq(PlayerStaminaCues.breathing_effort(0.7, 0.7), 0.0)
	assert_almost_eq(PlayerStaminaCues.breathing_effort(0.35, 0.7), 0.5, 0.001)
	assert_eq(PlayerStaminaCues.breathing_effort(0.0, 0.7), 1.0)


func test_breathing_is_silent_with_full_stamina() -> void:
	_cues.tick(1.0)
	assert_eq(_cues.effort, 0.0)
	assert_false(_cues.breathing_player.playing)


func test_breathing_gets_heavier_as_stamina_drops() -> void:
	_set_stamina(50.0)
	var light_volume: float = _cues.breathing_player.volume_db
	var light_pitch: float = _cues.breathing_player.pitch_scale
	var light_effort: float = _cues.effort
	assert_true(_cues.breathing_player.playing)
	_set_stamina(10.0)
	assert_gt(_cues.effort, light_effort)
	assert_gt(_cues.breathing_player.volume_db, light_volume)
	assert_gt(_cues.breathing_player.pitch_scale, light_pitch)


func test_effort_builds_over_time_instead_of_jumping() -> void:
	_stamina.current_stamina = 0.0
	_cues.tick(0.1)
	assert_gt(_cues.effort, 0.0)
	assert_lt(_cues.effort, 1.0)


func test_breathing_calms_slowly_as_stamina_regenerates() -> void:
	_set_stamina(0.0)
	assert_eq(_cues.effort, 1.0)
	_stamina.current_stamina = 100.0
	_cues.tick(0.5)
	assert_lt(_cues.effort, 1.0, "starts to calm")
	assert_gt(_cues.effort, 0.0, "but not at once")
	assert_true(_cues.breathing_player.playing)
	_cues.tick(5.0)
	assert_eq(_cues.effort, 0.0)
	assert_false(_cues.breathing_player.playing)


func test_a_breath_that_ends_starts_the_next_while_out_of_breath() -> void:
	_set_stamina(10.0)
	_cues.breathing_player.stop()
	_cues.breathing_player.finished.emit()
	assert_true(_cues.breathing_player.playing)


func test_exhaustion_plays_the_winded_animation() -> void:
	watch_signals(_cues)
	_stamina.exhausted.emit()
	await wait_process_frames(2)
	assert_true(_cues.is_winded)
	assert_signal_emitted(_cues, "winded")
	assert_eq(_player.model.get_current_state(), PlayerStaminaCues.WINDED_ACTION)
	assert_true(_player.is_movement_locked)
	assert_true(_cues.gasp_player.playing)


func test_the_winded_animation_ends_and_returns_control() -> void:
	_stamina.exhausted.emit()
	await wait_process_frames(2)
	_cues.tick(_cues.winded_duration * 0.5)
	assert_true(_cues.is_winded)
	_cues.tick(_cues.winded_duration)
	assert_false(_cues.is_winded)
	assert_false(_player.is_movement_locked)
	await wait_process_frames(2)
	assert_eq(_player.model.get_current_state(), PlayerModel.LOCOMOTION_STATE)


func test_sprinting_to_zero_gets_the_player_winded() -> void:
	_stamina.current_stamina = 0.05
	assert_true(_stamina.start_sprinting())
	_stamina._process(0.1)
	assert_true(_stamina.is_exhausted)
	assert_true(_cues.is_winded)


func test_the_animation_clip_exists() -> void:
	var player := _player.model.get_node("AnimationPlayer") as AnimationPlayer
	assert_true(player.has_animation(PlayerStaminaCues.WINDED_ACTION))
	var animation: Animation = player.get_animation(PlayerStaminaCues.WINDED_ACTION)
	# It loops, so it holds for however long the player stays winded.
	assert_eq(animation.loop_mode, Animation.LOOP_LINEAR, "loops")


func test_no_winded_animation_over_another_action() -> void:
	_player.is_movement_locked = true
	_stamina.exhausted.emit()
	assert_false(_cues.is_winded)
	assert_ne(_player.model.get_current_state(), PlayerStaminaCues.WINDED_ACTION)


func test_a_hit_during_winded_keeps_its_own_animation_and_lock() -> void:
	_stamina.exhausted.emit()
	await wait_process_frames(2)
	_player.model.play_action(&"hit")
	await wait_process_frames(2)
	_cues.tick(_cues.winded_duration * 2.0)
	assert_false(_cues.is_winded)
	assert_eq(_player.model.get_current_state(), &"hit")
	assert_true(_player.is_movement_locked, "the hit's stagger owns the lock")
