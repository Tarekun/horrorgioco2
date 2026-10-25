## Scene-level tests of the melee attack with the real player and dummy scenes.

extends CombatSceneTest


func test_wiring() -> void:
	assert_not_null(_combat.weapon)
	assert_eq(_combat.player, _player)
	assert_not_null(_combat.hitbox)
	assert_not_null(_combat.model)
	assert_eq(_combat.hitbox.collision_mask, CombatLayers.ENEMY_HURTBOX)
	assert_eq(_combat.hitbox.collision_layer, CombatLayers.PLAYER_HITBOX)
	assert_eq(_combat.hitbox.attacker, _player)


func test_tap_swings_and_plays_the_clip() -> void:
	watch_signals(_combat)
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.SWING_LIGHT)
	assert_signal_emitted_with_parameters(_combat, "swing_started", [&"light", 0])
	assert_eq(_combat.model.get_current_state(), &"attack_light_1")
	assert_true(_player.is_movement_locked)
	await _seconds(0.6)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_eq(_combat.model.get_current_state(), &"locomotion")
	assert_false(_player.is_movement_locked)


func test_light_swing_damages_and_staggers_once() -> void:
	await _tap()
	await _seconds(0.6)
	assert_eq(_dummy.health_component.current_health, 92.0, "8 damage, once")
	assert_eq(_dummy.stagger_count, 1)


func test_swing_costs_stamina() -> void:
	await _tap()
	assert_almost_eq(_stamina.current_stamina, 90.0, 2.5)


func test_cannot_attack_without_enough_stamina() -> void:
	_stamina.current_stamina = 5.0
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_eq(_dummy.health_component.current_health, 100.0)


func test_cannot_attack_while_exhausted() -> void:
	_stamina.current_stamina = 50.0
	_stamina.is_exhausted = true
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)


func test_no_hit_when_the_dummy_is_out_of_reach() -> void:
	_dummy.position = Vector3(0.0, 0.0, -4.0)
	await _tap()
	await _seconds(0.6)
	assert_eq(_dummy.health_component.current_health, 100.0)


func test_hitbox_reach_follows_the_weapon() -> void:
	var shape_node := _combat.hitbox.get_child(0) as CollisionShape3D
	var box := shape_node.shape as BoxShape3D
	assert_almost_eq(box.size.z, 1.6, 0.001)


func test_press_too_early_does_not_queue_the_combo() -> void:
	watch_signals(_combat)
	await _tap()
	await _seconds(0.1)
	_combat.attack_pressed()
	_combat.attack_released()
	await _seconds(0.5)
	assert_signal_emit_count(_combat, "swing_started", 1)


func _wait_for_progress(fraction: float) -> void:
	for i: int in 120:
		if _combat.get_swing_progress() >= fraction:
			return
		await _physics_frames(1)


func test_combo_chains_three_hits() -> void:
	watch_signals(_combat)
	await _tap()
	await _wait_for_progress(0.7)
	_combat.attack_pressed()
	_combat.attack_released()
	await _seconds(0.25)
	assert_eq(_combat.model.get_current_state(), &"attack_light_2")
	await _wait_for_progress(0.7)
	_combat.attack_pressed()
	_combat.attack_released()
	await _seconds(0.25)
	assert_eq(_combat.model.get_current_state(), &"attack_light_3")
	await _seconds(1.2)
	assert_signal_emit_count(_combat, "swing_started", 3)
	assert_eq(_combat.state, PlayerCombat.State.IDLE, "combo ends after the third hit")
	assert_almost_eq(_dummy.health_component.current_health, 72.0, 0.01, "8 + 8 + 12")


func test_combo_stops_when_stamina_runs_out() -> void:
	watch_signals(_combat)
	await _tap()
	_stamina.current_stamina = 5.0
	await _seconds(0.3)
	_combat.attack_pressed()
	await _seconds(0.5)
	assert_signal_emit_count(_combat, "swing_started", 1)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)


func test_hit_causes_hitstop() -> void:
	watch_signals(_combat)
	await _tap()
	await _seconds(0.4)
	assert_signal_emitted(_combat, "hitstop_started")
	assert_signal_emitted(_combat, "hit_landed")


func test_soft_targeting_turns_toward_the_enemy() -> void:
	_dummy.position = Vector3(-0.85, 0.0, -0.85)
	await _physics_frames(2)
	_combat.attack_pressed()
	await _physics_frames(2)
	_combat.attack_released()
	var forward: Vector3 = -_player.global_basis.z
	assert_almost_eq(forward, Vector3(-1.0, 0.0, -1.0).normalized(), Vector3.ONE * 0.05)


func test_dead_enemies_are_not_targeted() -> void:
	_dummy.hurtbox.receive_hit(HitData.create(500.0, _player))
	_dummy.position = Vector3(-0.85, 0.0, -0.85)
	await _tap()
	var forward: Vector3 = -_player.global_basis.z
	assert_almost_eq(forward, Vector3.FORWARD, Vector3.ONE * 0.05)


func test_swing_locks_movement() -> void:
	Input.action_press(&"move_back")
	await _seconds(0.3)
	assert_gt(_player.velocity.length(), 1.0)
	await _tap()
	await _physics_frames(3)
	assert_almost_eq(Vector2(_player.velocity.x, _player.velocity.z).length(), 0.0, 0.01)


func test_interrupt_ends_the_swing_without_hits() -> void:
	_combat.attack_pressed()
	_combat.attack_released()
	await _physics_frames(1)
	_combat.interrupt()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_false(_player.is_movement_locked)
	await _seconds(0.6)
	assert_eq(_dummy.health_component.current_health, 100.0)


func test_recovery_starts_after_the_hit_window() -> void:
	await _tap()
	assert_false(_combat.is_in_recovery())
	await _seconds(0.4)
	assert_true(_combat.is_in_recovery())


func test_real_input_attack() -> void:
	Input.action_press(&"attack")
	await _physics_frames(3)
	Input.action_release(&"attack")
	await _seconds(0.7)
	assert_eq(_dummy.health_component.current_health, 92.0)
