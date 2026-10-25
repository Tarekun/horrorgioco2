## Tests for HealthComponent: damage, death, healing, invulnerability.

extends GutTest

var _health: HealthComponent


func before_each() -> void:
	_health = HealthComponent.new()
	add_child_autofree(_health)


func test_starts_at_max_health() -> void:
	assert_eq(_health.current_health, 100.0)
	assert_false(_health.is_dead)


func test_damage_reduces_health_and_emits() -> void:
	watch_signals(_health)
	var dealt: float = _health.take_damage(30.0)
	assert_eq(dealt, 30.0)
	assert_eq(_health.current_health, 70.0)
	assert_signal_emitted_with_parameters(_health, "damage_taken", [30.0, null])
	assert_signal_emitted_with_parameters(_health, "health_changed", [70.0])
	assert_signal_not_emitted(_health, "died")


func test_lethal_damage_kills_once() -> void:
	watch_signals(_health)
	var dealt: float = _health.take_damage(250.0)
	assert_eq(dealt, 100.0, "overkill is not counted as dealt")
	assert_eq(_health.current_health, 0.0)
	assert_true(_health.is_dead)
	assert_signal_emit_count(_health, "died", 1)
	_health.take_damage(10.0)
	assert_signal_emit_count(_health, "died", 1)


func test_non_positive_damage_is_ignored() -> void:
	assert_eq(_health.take_damage(0.0), 0.0)
	assert_eq(_health.take_damage(-5.0), 0.0)
	assert_eq(_health.current_health, 100.0)


func test_invulnerable_ignores_damage() -> void:
	watch_signals(_health)
	_health.is_invulnerable = true
	assert_eq(_health.take_damage(50.0), 0.0)
	assert_eq(_health.current_health, 100.0)
	assert_signal_not_emitted(_health, "damage_taken")


func test_heal_restores_up_to_max() -> void:
	_health.take_damage(40.0)
	watch_signals(_health)
	assert_eq(_health.heal(30.0), 30.0)
	assert_eq(_health.current_health, 90.0)
	assert_eq(_health.heal(30.0), 10.0, "capped at max")
	assert_eq(_health.current_health, 100.0)
	assert_signal_emit_count(_health, "healed", 2)


func test_heal_at_full_health_does_nothing() -> void:
	watch_signals(_health)
	assert_eq(_health.heal(10.0), 0.0)
	assert_signal_not_emitted(_health, "healed")


func test_dead_actor_cannot_be_healed_until_revived() -> void:
	_health.take_damage(500.0)
	assert_eq(_health.heal(50.0), 0.0)
	assert_true(_health.is_dead)
	_health.revive(40.0)
	assert_false(_health.is_dead)
	assert_eq(_health.current_health, 40.0)


func test_ratio() -> void:
	_health.take_damage(25.0)
	assert_eq(_health.get_ratio(), 0.75)


func test_custom_max_health() -> void:
	var other := HealthComponent.new()
	other.max_health = 40.0
	add_child_autofree(other)
	assert_eq(other.current_health, 40.0)
