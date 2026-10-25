## Scene-level tests of the stomp finisher, with the real player and enemy scenes.

extends CombatSceneTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")

var _enemy: Enemy


func before_each() -> void:
	await super.before_each()
	_dummy.position = Vector3(20.0, 0.0, 0.0)
	_enemy = ENEMY_SCENE.instantiate() as Enemy
	_enemy.position = Vector3(0.0, 0.0, -1.0)
	_enemy.rotation.y = PI
	_enemy.downed_variation = 0.0
	_enemy.downed_duration = 30.0
	add_child_autofree(_enemy)
	await _physics_frames(2)


func _down_enemy() -> void:
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _physics_frames(2)


func test_attack_stomps_a_downed_enemy_instead_of_swinging() -> void:
	await _down_enemy()
	watch_signals(_combat)
	var stamina: float = _stamina.current_stamina
	_combat.attack_pressed()
	assert_eq(_combat.state, PlayerCombat.State.STOMP)
	assert_signal_emitted(_combat, "stomp_started")
	assert_signal_not_emitted(_combat, "swing_started")
	assert_eq(_stamina.current_stamina, stamina)


func test_stomp_costs_no_stamina_even_when_exhausted() -> void:
	await _down_enemy()
	_stamina.try_spend(100.0)
	_combat.attack_pressed()
	assert_eq(_combat.state, PlayerCombat.State.STOMP)


func test_stomp_kills_the_enemy_partway_and_takes_the_full_duration() -> void:
	await _down_enemy()
	watch_signals(_combat)
	_combat.attack_pressed()
	await _seconds(0.3)
	assert_true(_enemy.is_downed())
	await _seconds(0.3)
	assert_true(_enemy.is_dead())
	assert_signal_emitted(_combat, "stomp_landed")
	assert_eq(_combat.state, PlayerCombat.State.STOMP)
	await _seconds(0.3)
	assert_eq(_combat.state, PlayerCombat.State.IDLE)
	assert_false(_player.is_movement_locked)


func test_the_player_is_locked_and_faces_the_enemy_during_a_stomp() -> void:
	await _down_enemy()
	_player.rotation.y = 1.0
	_combat.attack_pressed()
	assert_true(_player.is_movement_locked)
	assert_almost_eq(_player.rotation.y, 0.0, 0.01)


func test_a_downed_enemy_out_of_range_is_not_stomped() -> void:
	_enemy.position = Vector3(0.0, 0.0, -3.0)
	await _down_enemy()
	_combat.attack_pressed()
	assert_ne(_combat.state, PlayerCombat.State.STOMP)


func test_a_standing_enemy_is_not_stomped() -> void:
	_combat.attack_pressed()
	assert_ne(_combat.state, PlayerCombat.State.STOMP)


func test_a_hit_interrupts_the_stomp_before_it_lands() -> void:
	await _down_enemy()
	_combat.attack_pressed()
	await _seconds(0.1)
	_player.hurtbox.receive_hit(HitData.create(10.0, null))
	await _seconds(1.0)
	assert_true(_enemy.is_downed())
	assert_ne(_combat.state, PlayerCombat.State.STOMP)


func test_dodge_cannot_cancel_a_stomp() -> void:
	await _down_enemy()
	var dodge := _player.get_node("PlayerDodge") as PlayerDodge
	_combat.attack_pressed()
	assert_false(dodge.can_dodge())


func test_the_enemy_getting_up_during_the_stomp_survives_it() -> void:
	await _down_enemy()
	_combat.attack_pressed()
	_enemy.brain.downed_duration = 0.0
	await _seconds(1.0)
	assert_false(_enemy.is_dead())


func test_the_nearest_downed_enemy_is_chosen() -> void:
	await _down_enemy()
	var other: Enemy = ENEMY_SCENE.instantiate() as Enemy
	other.position = Vector3(0.0, 0.0, 0.6)
	add_child_autofree(other)
	await _physics_frames(2)
	other.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _physics_frames(2)
	assert_eq(_combat.find_stompable_enemy(), other)
