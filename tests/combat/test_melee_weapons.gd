## Tests for the three melee weapons: their spec values, the fire axe's short
## combo and the damage, stamina and timing of each when swung.

extends CombatSceneTest

const PLANK: MeleeWeapon = preload("res://assets/data/weapons/wooden_plank.tres")
const PIPE: MeleeWeapon = preload("res://assets/data/weapons/steel_pipe.tres")
const AXE: MeleeWeapon = preload("res://assets/data/weapons/fire_axe.tres")


func _wait_for_progress(fraction: float) -> void:
	for i: int in 180:
		if _combat.get_swing_progress() >= fraction:
			return
		await _physics_frames(1)


func _wait_until_idle() -> void:
	for i: int in 240:
		if _combat.state == PlayerCombat.State.IDLE:
			return
		await _physics_frames(1)


func test_steel_pipe_has_the_spec_values() -> void:
	assert_eq(PIPE.light_damage, PackedFloat32Array([12.0, 12.0, 18.0]))
	assert_eq(PIPE.heavy_damage, 35.0)
	assert_eq(PIPE.light_stamina, 12.0)
	assert_eq(PIPE.heavy_stamina, 25.0)
	assert_eq(PIPE.reach, 1.8)


func test_fire_axe_has_the_spec_values() -> void:
	assert_eq(AXE.light_damage, PackedFloat32Array([18.0, 26.0]))
	assert_eq(AXE.heavy_damage, 50.0)
	assert_eq(AXE.light_stamina, 18.0)
	assert_eq(AXE.heavy_stamina, 35.0)
	assert_eq(AXE.reach, 1.9)


func test_the_fire_axe_has_a_two_hit_combo() -> void:
	assert_eq(AXE.combo_length(), 2)
	assert_eq(PIPE.combo_length(), 3)
	assert_eq(PLANK.combo_length(), 3)


func test_plank_is_fast_pipe_medium_and_axe_slow() -> void:
	for index: int in 2:
		assert_lt(PLANK.light_duration(index), PIPE.light_duration(index))
		assert_lt(PIPE.light_duration(index), AXE.light_duration(index))
	assert_lt(PLANK.heavy_duration, PIPE.heavy_duration)
	assert_lt(PIPE.heavy_duration, AXE.heavy_duration)


func test_each_weapon_deals_its_own_damage() -> void:
	var expected: Dictionary[MeleeWeapon, float] = {PLANK: 8.0, PIPE: 12.0, AXE: 18.0}
	for weapon: MeleeWeapon in expected:
		_combat.equip(weapon)
		var before: float = _dummy.health_component.current_health
		_stamina.current_stamina = _stamina.max_stamina
		await _tap()
		await _wait_until_idle()
		assert_almost_eq(
			before - _dummy.health_component.current_health,
			expected[weapon],
			0.01,
			weapon.display_name
		)


func test_each_weapon_costs_its_own_stamina() -> void:
	for weapon: MeleeWeapon in [PLANK, PIPE, AXE]:
		_combat.equip(weapon)
		_stamina.current_stamina = _stamina.max_stamina
		await _tap()
		assert_almost_eq(
			_stamina.current_stamina,
			_stamina.max_stamina - weapon.light_stamina,
			0.5,
			weapon.display_name
		)
		await _wait_until_idle()


func test_the_axe_combo_ends_after_two_hits() -> void:
	_combat.equip(AXE)
	watch_signals(_combat)
	await _tap()
	await _wait_for_progress(0.7)
	_combat.attack_pressed()
	_combat.attack_released()
	await wait_for_signal(_combat.swing_started, 2.0)
	await _wait_for_progress(0.7)
	# Past the second hit's hitstop, its clip still plays.
	assert_eq(_combat.model.get_current_state(), &"attack_light_2")
	# In the queue window, but there is no third hit.
	_combat.attack_pressed()
	_combat.attack_released()
	await _wait_until_idle()
	assert_signal_emit_count(_combat, "swing_started", 2)
	assert_almost_eq(_dummy.health_component.current_health, 100.0 - 18.0 - 26.0, 0.01)


func test_a_full_charge_with_the_axe_deals_its_heavy_damage() -> void:
	_combat.equip(AXE)
	_combat.attack_pressed()
	await _seconds(1.1)
	_combat.attack_released()
	await _wait_until_idle()
	assert_almost_eq(_dummy.health_component.current_health, 50.0, 0.01)


func test_equip_moves_the_hitbox_to_the_new_reach() -> void:
	_combat.equip(AXE)
	var shape := _combat.hitbox.get_child(0) as CollisionShape3D
	assert_almost_eq((shape.shape as BoxShape3D).size.z, 1.9, 0.001)


func test_equip_ends_a_swing_in_progress() -> void:
	await _tap()
	assert_eq(_combat.state, PlayerCombat.State.SWING_LIGHT)
	watch_signals(_combat)
	_combat.equip(PIPE)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_false(_player.is_movement_locked)
	assert_signal_emitted_with_parameters(_combat, "weapon_changed", [PIPE])


func test_slower_swings_stretch_their_clips() -> void:
	_combat.equip(AXE)
	await _tap()
	var clip: Animation = _combat.model.animation_tree.get_animation(&"attack_light_1")
	assert_almost_eq(_combat.model.get_action_speed(), clip.length / AXE.light_duration(0), 0.001)
	await _wait_until_idle()
	assert_eq(_combat.model.get_action_speed(), 1.0)
