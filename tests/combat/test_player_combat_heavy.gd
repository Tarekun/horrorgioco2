## Scene-level tests of the charged heavy attack.

extends CombatSceneTest


func test_hold_charges_a_heavy_attack() -> void:
	watch_signals(_combat)
	_combat.attack_pressed()
	await _seconds(0.5)
	assert_eq(_combat.state, PlayerCombat.State.CHARGING)
	assert_eq(_combat.model.get_current_state(), &"attack_heavy_charge")
	assert_almost_eq(_stamina.current_stamina, 80.0, 2.5, "heavy costs 20")
	_combat.attack_released()
	assert_eq(_combat.state, PlayerCombat.State.SWING_HEAVY)
	assert_signal_emitted_with_parameters(_combat, "swing_started", [&"heavy", 0])
	await _seconds(1.0)
	var damage_dealt: float = 100.0 - _dummy.health_component.current_health
	assert_between(damage_dealt, 15.0, 25.0, "partial charge scales 60-100%")


func test_full_charge_deals_full_damage_and_knocks_down() -> void:
	_combat.attack_pressed()
	await _seconds(1.1)
	_combat.attack_released()
	assert_true(_combat.hitbox.causes_knockdown)
	await _seconds(1.0)
	assert_almost_eq(_dummy.health_component.current_health, 75.0, 0.01)


func test_heavy_without_stamina_does_nothing() -> void:
	_stamina.current_stamina = 15.0
	_combat.attack_pressed()
	await _seconds(0.5)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_almost_eq(_stamina.current_stamina, 15.0, 2.5, "nothing spent")
	_combat.attack_released()
	assert_eq(_combat.state, PlayerCombat.State.IDLE, "release does not swing")
