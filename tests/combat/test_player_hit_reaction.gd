## Scene-level tests of the player's hit reaction, death and game over, with
## the real player scene.

extends CombatSceneTest

var _reaction: PlayerHitReaction
var _dodge: PlayerDodge


func before_each() -> void:
	await super.before_each()
	_reaction = _player.get_node("PlayerHitReaction") as PlayerHitReaction
	_dodge = _player.get_node("PlayerDodge") as PlayerDodge
	_reaction.game_over_screen.is_reload_on_retry = false
	_dummy.position = Vector3(20.0, 0.0, 0.0)
	await _physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	super.after_each()


func _hit(amount: float) -> float:
	return _player.hurtbox.receive_hit(HitData.create(amount, null))


func test_wiring() -> void:
	assert_eq(_reaction.player, _player)
	assert_eq(_reaction.health_component, _player.health_component)
	assert_eq(_reaction.combat, _combat)
	assert_eq(_reaction.dodge, _dodge)
	assert_not_null(_reaction.model)
	assert_eq(_reaction.camera_controller, _player.camera_controller)
	assert_not_null(_reaction.damage_overlay)
	assert_not_null(_reaction.game_over_screen)
	assert_not_null(_reaction.damage_overlay.flash_rect)
	assert_not_null(_reaction.game_over_screen.retry_button)
	assert_not_null(_reaction.game_over_screen.panel)


func test_hit_staggers_plays_clip_and_locks() -> void:
	watch_signals(_reaction)
	_hit(20.0)
	await _physics_frames(2)
	assert_true(_reaction.is_staggered)
	assert_signal_emitted(_reaction, "staggered")
	assert_true(_player.is_movement_locked)
	assert_eq(_combat.model.get_current_state(), &"hit")
	assert_eq(_player.health_component.current_health, 80.0)


func test_stagger_ends_after_its_duration() -> void:
	_hit(20.0)
	await _seconds(0.5)
	assert_false(_reaction.is_staggered)
	assert_false(_player.is_movement_locked)
	assert_eq(_combat.model.get_current_state(), &"locomotion")


func test_cannot_attack_or_dodge_while_staggered() -> void:
	_hit(20.0)
	_combat.attack_pressed()
	_combat.attack_released()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_false(_dodge.try_dodge())
	await _seconds(0.5)
	assert_true(_dodge.try_dodge(), "free again afterwards")


func test_hit_interrupts_a_swing_and_a_dodge() -> void:
	await _tap()
	assert_true(_combat.is_acting())
	_hit(20.0)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	await _seconds(0.5)
	assert_true(_dodge.try_dodge())
	assert_true(_dodge.is_dodging)
	_hit_after_invulnerability()


func _hit_after_invulnerability() -> void:
	_player.health_component.is_invulnerable = false
	_hit(10.0)
	assert_false(_dodge.is_dodging)
	assert_false(_player.health_component.is_invulnerable)


func test_dodging_through_a_hit_does_not_stagger() -> void:
	_dodge.try_dodge()
	assert_eq(_hit(20.0), 0.0)
	assert_false(_reaction.is_staggered)


func test_hit_triggers_screen_flash_shake_and_audio_cue() -> void:
	watch_signals(_reaction)
	_hit(20.0)
	assert_almost_eq(_reaction.damage_overlay.intensity, 0.7, 0.001)
	assert_signal_emitted_with_parameters(_reaction, "audio_cue_requested", [&"player_hit", 0.7])
	var arm: SpringArm3D = _player.camera_controller.spring_arm
	var rest: Vector3 = Vector3(0.5, 1.6, 0.0)
	var moved: bool = false
	for i: int in 6:
		await _physics_frames(1)
		if not arm.position.is_equal_approx(rest):
			moved = true
	assert_true(moved, "camera shakes")
	await _seconds(0.5)
	assert_almost_eq(arm.position, rest, Vector3.ONE * 0.001)


func test_hit_intensity_scales_with_damage() -> void:
	assert_almost_eq(PlayerHitReaction.hit_intensity(15.0, 100.0), 0.6, 0.001)
	assert_almost_eq(PlayerHitReaction.hit_intensity(25.0, 100.0), 0.8, 0.001)
	assert_eq(PlayerHitReaction.hit_intensity(100.0, 100.0), 1.0)


func test_death_stops_input_and_plays_death_clip() -> void:
	watch_signals(_reaction)
	_hit(500.0)
	await _physics_frames(2)
	assert_true(_reaction.is_dead)
	assert_false(_reaction.is_staggered, "a lethal hit doesn't stagger first")
	assert_signal_emit_count(_reaction, "player_died", 1)
	assert_eq(_combat.model.get_current_state(), &"death")
	assert_true(_player.is_movement_locked)
	_combat.attack_pressed()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_false(_dodge.try_dodge())
	await _seconds(1.0)
	assert_true(_player.is_movement_locked, "stays locked")
	assert_eq(_player.velocity.x, 0.0)


func test_death_stops_movement_input() -> void:
	Input.action_press(&"move_back")
	await _seconds(0.3)
	assert_gt(_player.velocity.length(), 1.0)
	_hit(500.0)
	await _physics_frames(3)
	assert_almost_eq(Vector2(_player.velocity.x, _player.velocity.z).length(), 0.0, 0.01)


func test_game_over_screen_appears_after_the_delay_and_pauses() -> void:
	var screen: GameOverScreen = _reaction.game_over_screen
	assert_false(screen.panel.visible)
	_hit(500.0)
	_reaction.tick(1.0)
	assert_false(screen.is_showing, "still in the death animation")
	_reaction.tick(1.0)
	assert_true(screen.is_showing)
	assert_true(screen.panel.visible)
	assert_true(get_tree().paused)


func test_retry_unpauses_and_requests_a_reload() -> void:
	var screen: GameOverScreen = _reaction.game_over_screen
	watch_signals(screen)
	screen.show_screen()
	assert_true(get_tree().paused)
	screen.retry_button.pressed.emit()
	assert_false(get_tree().paused)
	assert_signal_emitted(screen, "retry_requested")
	assert_false(screen.panel.visible)
