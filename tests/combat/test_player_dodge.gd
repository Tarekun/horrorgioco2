## Tests for the dodge: distances, invulnerability window, stamina, cooldown
## and cancelling a swing's recovery, with the real player scene.

extends CombatSceneTest

var _dodge: PlayerDodge


func before_each() -> void:
	await super.before_each()
	_dodge = _player.get_node("PlayerDodge") as PlayerDodge
	# Out of the way, so the dummy neither blocks nor is hit.
	_dummy.position = Vector3(20.0, 0.0, 0.0)
	await _physics_frames(2)


func _damage_player(amount: float) -> float:
	return _player.hurtbox.receive_hit(HitData.create(amount, null))


func test_wiring() -> void:
	assert_eq(_dodge.player, _player)
	assert_not_null(_dodge.stamina_component)
	assert_not_null(_dodge.health_component)
	assert_not_null(_dodge.model)
	assert_eq(_dodge.combat, _combat)
	assert_eq(_dodge.distance, 2.5)
	assert_eq(_dodge.backstep_distance, 1.5)
	assert_eq(_dodge.duration, 0.5)
	assert_eq(_dodge.invulnerable_duration, 0.25)
	assert_eq(_dodge.stamina_cost, 20.0)
	assert_eq(_dodge.cooldown, 0.2)


func test_distance_curve_covers_the_whole_distance() -> void:
	assert_eq(PlayerDodge.distance_at(0.0, 2.5, 0.5), 0.0)
	assert_almost_eq(PlayerDodge.distance_at(0.5, 2.5, 0.5), 2.5, 0.0001)
	assert_almost_eq(PlayerDodge.distance_at(9.0, 2.5, 0.5), 2.5, 0.0001, "clamped")
	assert_gt(PlayerDodge.distance_at(0.25, 2.5, 0.5), 1.25, "fast start, easing out")


func test_dodge_in_the_input_direction() -> void:
	Input.action_press(&"move_back")
	await _physics_frames(5)
	var start: Vector3 = _player.global_position
	assert_true(_dodge.try_dodge())
	await _seconds(0.7)
	var moved: Vector3 = _player.global_position - start
	assert_gt(moved.z, 2.5, "dodge plus the run after it")
	assert_almost_eq(moved.x, 0.0, 0.05)


func test_dodge_covers_2_5_metres() -> void:
	Input.action_press(&"move_back")
	await _physics_frames(5)
	var start: Vector3 = _player.global_position
	_dodge.try_dodge()
	await _physics_frames(1)
	# Released so nothing but the dodge moves the body once it ends.
	Input.action_release(&"move_back")
	await _seconds(0.55)
	assert_almost_eq(_player.global_position.distance_to(start), 2.5, 0.3)


func test_backstep_without_input_moves_away_from_facing() -> void:
	var start: Vector3 = _player.global_position
	var facing: Vector3 = -_player.global_basis.z
	assert_true(_dodge.try_dodge())
	await _seconds(0.6)
	var moved: Vector3 = _player.global_position - start
	assert_almost_eq(moved.length(), 1.5, 0.2)
	assert_lt(moved.dot(facing), -1.0, "moved backwards")
	assert_almost_eq((-_player.global_basis.z).dot(facing), 1.0, 0.01, "facing kept")


func test_dodge_plays_clip_and_locks_movement() -> void:
	_dodge.try_dodge()
	await _physics_frames(2)
	assert_eq(_combat.model.get_current_state(), &"backstep")
	assert_true(_player.is_movement_locked)
	assert_true(_dodge.is_dodging)
	await _seconds(0.6)
	assert_false(_dodge.is_dodging)
	assert_false(_player.is_movement_locked)
	assert_eq(_combat.model.get_current_state(), &"locomotion")


func test_first_quarter_second_is_invulnerable() -> void:
	_dodge.try_dodge()
	assert_true(_player.health_component.is_invulnerable)
	await _seconds(0.15)
	assert_eq(_damage_player(30.0), 0.0, "inside the window")
	assert_eq(_player.health_component.current_health, 100.0)
	await _seconds(0.2)
	assert_false(_player.health_component.is_invulnerable)
	assert_eq(_damage_player(30.0), 30.0, "after the window, still dodging")
	assert_true(_dodge.is_dodging)


func test_dodge_costs_stamina() -> void:
	_dodge.try_dodge()
	assert_almost_eq(_stamina.current_stamina, 80.0, 0.01)


func test_cannot_dodge_without_enough_stamina() -> void:
	_stamina.current_stamina = 19.0
	assert_false(_dodge.try_dodge())
	assert_false(_dodge.is_dodging)
	assert_eq(_stamina.current_stamina, 19.0)


func test_cannot_dodge_while_exhausted() -> void:
	_stamina.is_exhausted = true
	assert_false(_dodge.try_dodge())


func test_cannot_dodge_during_a_dodge_or_the_cooldown() -> void:
	assert_true(_dodge.try_dodge())
	assert_false(_dodge.try_dodge(), "already dodging")
	await _seconds(0.55)
	assert_false(_dodge.is_dodging)
	assert_gt(_dodge.get_cooldown_left(), 0.0)
	assert_false(_dodge.try_dodge(), "cooling down")
	await _seconds(0.25)
	assert_true(_dodge.try_dodge(), "ready again")


func test_stamina_limits_spamming() -> void:
	var count: int = 0
	for i: int in 7:
		if _dodge.try_dodge():
			count += 1
		await _seconds(0.75)
	assert_eq(count, 5, "100 stamina pays for five dodges, then exhaustion")


func test_cannot_attack_while_dodging() -> void:
	_dodge.try_dodge()
	_combat.attack_pressed()
	await _physics_frames(2)
	_combat.attack_released()
	assert_eq(_combat.state, PlayerCombat.State.IDLE)


func test_dodge_from_swing_windup_is_refused() -> void:
	await _tap()
	assert_false(_combat.is_in_recovery())
	assert_false(_dodge.try_dodge())


func test_dodge_cancels_swing_recovery() -> void:
	await _tap()
	await _seconds(0.4)
	assert_true(_combat.is_in_recovery())
	assert_true(_dodge.try_dodge())
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_true(_dodge.is_dodging)


func test_interrupt_ends_the_dodge_and_invulnerability() -> void:
	_dodge.try_dodge()
	_dodge.interrupt()
	assert_false(_dodge.is_dodging)
	assert_false(_player.health_component.is_invulnerable)
	assert_false(_player.is_movement_locked)
	assert_eq(_dodge.get_cooldown_left(), 0.0)


func test_real_input_action_dodges() -> void:
	Input.action_press(&"dodge")
	await _physics_frames(3)
	Input.action_release(&"dodge")
	assert_lt(_stamina.current_stamina, 90.0)
