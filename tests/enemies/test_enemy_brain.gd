extends GutTest

var _brain: EnemyBrain
var _senses: EnemySenses


func before_each() -> void:
	_brain = EnemyBrain.new()
	_brain.idle_duration = 2.0
	_brain.wander_timeout = 5.0
	_brain.stagger_duration = 0.5
	_senses = EnemySenses.new()


func _tick(seconds: float) -> void:
	_brain.tick(seconds, _senses)


func test_starts_idle() -> void:
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_idle_stays_until_its_duration_passes() -> void:
	_tick(1.9)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)
	_tick(0.2)
	assert_eq(_brain.state, EnemyBrain.State.WANDER)


func test_wander_returns_to_idle_on_arrival() -> void:
	_tick(2.0)
	_senses.has_arrived = true
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_wander_gives_up_after_its_timeout() -> void:
	_tick(2.0)
	_tick(4.9)
	assert_eq(_brain.state, EnemyBrain.State.WANDER)
	_tick(0.2)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_noticing_a_target_starts_a_chase_from_idle_and_wander() -> void:
	_senses.has_target = true
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)

	var other := EnemyBrain.new()
	other.tick(3.1, EnemySenses.new())
	assert_eq(other.state, EnemyBrain.State.WANDER)
	other.tick(0.1, _senses)
	assert_eq(other.state, EnemyBrain.State.CHASE)


func test_chase_attacks_when_ready_and_in_range() -> void:
	_senses.has_target = true
	_tick(0.1)
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)
	_senses.can_attack = true
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)


func test_attack_finishing_resumes_the_chase() -> void:
	_senses.has_target = true
	_senses.can_attack = true
	_tick(0.1)
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	_senses.can_attack = false
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	_senses.is_attack_finished = true
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_attack_finishing_without_a_target_wanders() -> void:
	_senses.has_target = true
	_senses.can_attack = true
	_tick(0.1)
	_tick(0.1)
	_senses.has_target = false
	_senses.is_attack_finished = true
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.WANDER)


func test_losing_the_target_ends_the_chase() -> void:
	_senses.has_target = true
	_tick(0.1)
	_senses.has_target = false
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.WANDER)


func test_stagger_interrupts_an_attack_then_resumes() -> void:
	_senses.has_target = true
	_senses.can_attack = true
	_tick(0.1)
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	_brain.stagger()
	assert_eq(_brain.state, EnemyBrain.State.STAGGER)
	_senses.can_attack = false
	_tick(0.4)
	assert_eq(_brain.state, EnemyBrain.State.STAGGER)
	_tick(0.2)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_stagger_without_a_target_goes_idle() -> void:
	_brain.stagger()
	_tick(0.6)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_death_is_final() -> void:
	_brain.kill()
	assert_true(_brain.is_dead())
	_senses.has_target = true
	_brain.stagger()
	_tick(5.0)
	assert_eq(_brain.state, EnemyBrain.State.DEAD)


func test_state_changed_reports_old_and_new_state() -> void:
	watch_signals(_brain)
	_senses.has_target = true
	_tick(0.1)
	assert_signal_emitted_with_parameters(
		_brain, "state_changed", [EnemyBrain.State.IDLE, EnemyBrain.State.CHASE]
	)


func test_knock_down_lasts_its_duration_then_resumes() -> void:
	_brain.knock_down(2.0)
	assert_eq(_brain.state, EnemyBrain.State.DOWNED)
	assert_true(_brain.is_downed())
	_tick(1.9)
	assert_eq(_brain.state, EnemyBrain.State.DOWNED)
	_senses.has_target = true
	_tick(0.2)
	assert_eq(_brain.state, EnemyBrain.State.CHASE)


func test_getting_up_without_a_target_goes_idle() -> void:
	_brain.knock_down(1.0)
	_tick(1.1)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_stagger_is_ignored_while_down() -> void:
	_brain.knock_down(2.0)
	_brain.stagger()
	assert_eq(_brain.state, EnemyBrain.State.DOWNED)


func test_a_second_knock_down_keeps_the_first_timer() -> void:
	_brain.knock_down(2.0)
	_tick(1.5)
	_brain.knock_down(10.0)
	_tick(0.6)
	assert_eq(_brain.state, EnemyBrain.State.IDLE)


func test_kill_works_on_a_downed_enemy_and_is_final() -> void:
	_brain.knock_down(1.0)
	_brain.kill()
	assert_true(_brain.is_dead())
	_tick(5.0)
	assert_true(_brain.is_dead())
	_brain.knock_down(1.0)
	assert_true(_brain.is_dead())


func test_a_knock_down_interrupts_an_attack() -> void:
	_senses.has_target = true
	_senses.can_attack = true
	_tick(0.1)
	_tick(0.1)
	assert_eq(_brain.state, EnemyBrain.State.ATTACK)
	_brain.knock_down(3.0)
	assert_eq(_brain.state, EnemyBrain.State.DOWNED)
