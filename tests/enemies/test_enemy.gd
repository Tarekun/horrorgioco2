## Scene-level tests of the enemy with the real player, on a floor with a navmesh.

extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DT: float = 1.0 / 60.0

var _enemy: Enemy
var _player: Player


func before_each() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	var region := NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array(
		[Vector3(-40, 0, -40), Vector3(40, 0, -40), Vector3(40, 0, 40), Vector3(-40, 0, 40)]
	)
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_mesh = mesh
	add_child_autofree(region)

	_player = PLAYER_SCENE.instantiate() as Player
	_player.position = Vector3(0.0, 0.0, 0.0)
	add_child_autofree(_player)
	_enemy = _spawn_enemy(Vector3(0.0, 0.0, -6.0))
	await _frames(3)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _spawn_enemy(position: Vector3) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = position
	# Face the origin, where the player stands.
	enemy.rotation.y = atan2(position.x, position.z)
	add_child_autofree(enemy)
	return enemy


func _spawn_dormant(position: Vector3) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = position
	enemy.is_dormant = true
	add_child_autofree(enemy)
	return enemy


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds / DT)))


func test_wiring() -> void:
	assert_true(_enemy.is_in_group(Enemy.ENEMY_GROUP))
	assert_true(_player.is_in_group(Enemy.PLAYER_GROUP))
	assert_not_null(_enemy.navigation_agent)
	assert_eq(_enemy.attack_hitbox.collision_mask, CombatLayers.PLAYER_HURTBOX)
	assert_eq(_enemy.hurtbox.collision_layer, CombatLayers.ENEMY_HURTBOX)


func test_idles_when_the_player_is_far() -> void:
	var far_enemy: Enemy = _spawn_enemy(Vector3(0.0, 0.0, -30.0))
	await _seconds(0.5)
	assert_eq(far_enemy.get_state(), EnemyBrain.State.IDLE)


func test_a_dormant_enemy_neither_sees_nor_hears_the_player() -> void:
	var sleeper: Enemy = _spawn_dormant(Vector3(4.0, 0.0, -4.0))
	var position: Vector3 = sleeper.global_position
	sleeper.perception.hear_noise(_player.global_position, 20.0)
	await _seconds(1.0)
	assert_eq(sleeper.get_state(), EnemyBrain.State.IDLE)
	assert_false(sleeper.perception.is_alert())
	assert_false(sleeper.is_chasing())
	assert_almost_eq(sleeper.global_position.x, position.x, 0.01)
	assert_almost_eq(sleeper.global_position.z, position.z, 0.01)


func test_waking_alerts_a_dormant_enemy_to_the_player() -> void:
	var sleeper: Enemy = _spawn_dormant(Vector3(4.0, 0.0, -4.0))
	await _frames(3)
	sleeper.wake()
	assert_false(sleeper.is_dormant)
	assert_true(sleeper.perception.is_alert())
	await _frames(3)
	assert_eq(sleeper.get_state(), EnemyBrain.State.CHASE)


func test_a_hit_wakes_a_dormant_enemy() -> void:
	var sleeper: Enemy = _spawn_dormant(Vector3(4.0, 0.0, -4.0))
	await _frames(3)
	sleeper.hurtbox.receive_hit(HitData.create(5.0, _player))
	assert_false(sleeper.is_dormant)
	assert_true(sleeper.is_chasing())


func test_wander_picks_a_point_within_its_radius() -> void:
	var spawn: Vector3 = _enemy.global_position
	for i: int in 10:
		var point: Vector3 = _enemy.pick_wander_point()
		assert_lt(point.distance_to(spawn), _enemy.wander_radius * 1.5 + 0.1)


func test_chases_the_player_along_the_navmesh() -> void:
	var start: float = _enemy.global_position.distance_to(_player.global_position)
	await _seconds(1.0)
	assert_eq(_enemy.get_state(), EnemyBrain.State.CHASE)
	assert_lt(_enemy.global_position.distance_to(_player.global_position), start - 1.0)


func test_attacks_and_damages_the_player_through_health() -> void:
	_enemy.attack_windup = 0.2
	await _seconds(4.0)
	var at_least_one_hit: float = 100.0 - Scarcity.current().enemy_damage_min
	assert_lte(_player.health_component.current_health, at_least_one_hit)


func test_a_hit_staggers_the_enemy_and_cancels_the_attack() -> void:
	_enemy.position = Vector3(0.0, 0.0, -1.0)
	await _frames(3)
	assert_eq(_enemy.get_state(), EnemyBrain.State.ATTACK)
	assert_true(_enemy.is_attacking)
	_enemy.hurtbox.receive_hit(HitData.create(5.0, _player))
	await _frames(2)
	assert_eq(_enemy.get_state(), EnemyBrain.State.STAGGER)
	assert_false(_enemy.is_attacking)
	assert_false(_enemy.attack_hitbox.is_active)


func test_falls_down_at_zero_health() -> void:
	watch_signals(_enemy)
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _frames(2)
	assert_eq(_enemy.get_state(), EnemyBrain.State.DOWNED)
	assert_true(_enemy.is_downed())
	assert_true(_enemy.is_in_group(Enemy.DOWNED_GROUP))
	assert_signal_emitted(_enemy, "downed")
	assert_signal_not_emitted(_enemy, "died")
	assert_eq(_enemy.rotation_degrees.x, 90.0)


func test_a_downed_enemy_does_not_move_or_attack() -> void:
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	var position: Vector3 = _enemy.global_position
	await _seconds(1.0)
	assert_eq(_enemy.get_state(), EnemyBrain.State.DOWNED)
	assert_almost_eq(_enemy.global_position.x, position.x, 0.01)
	assert_almost_eq(_enemy.global_position.z, position.z, 0.01)
	assert_false(_enemy.is_attacking)


func test_gets_back_up_after_the_delay_with_forty_percent_health() -> void:
	_enemy.downed_variation = 0.0
	_enemy.downed_duration = 2.0
	watch_signals(_enemy)
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _seconds(1.5)
	assert_true(_enemy.is_downed())
	await _seconds(0.7)
	assert_false(_enemy.is_downed())
	assert_signal_emitted(_enemy, "got_up")
	assert_eq(_enemy.health_component.current_health, 40.0)
	assert_false(_enemy.health_component.is_dead)
	assert_eq(_enemy.rotation_degrees.x, 0.0)
	assert_false(_enemy.is_in_group(Enemy.DOWNED_GROUP))
	assert_true(_enemy.is_in_group(Enemy.ENEMY_GROUP))


func test_down_time_is_randomised_around_eight_seconds() -> void:
	var durations: Array[float] = []
	for i: int in 20:
		durations.append(_enemy._roll_downed_duration())
	assert_gte(durations.min(), 6.0)
	assert_lte(durations.max(), 10.0)
	assert_gt(durations.max() - durations.min(), 0.1)


func test_stomp_kills_a_downed_enemy_for_good() -> void:
	watch_signals(_enemy)
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _frames(2)
	assert_true(_enemy.stomp())
	await _frames(2)
	assert_true(_enemy.is_dead())
	assert_eq(_enemy.get_state(), EnemyBrain.State.DEAD)
	assert_signal_emitted(_enemy, "died")
	assert_signal_not_emitted(_enemy, "got_up")
	assert_false(_enemy.is_in_group(Enemy.ENEMY_GROUP))
	assert_false(_enemy.is_in_group(Enemy.DOWNED_GROUP))
	assert_eq(_enemy.health_component.current_health, 0.0)


func test_a_corpse_stays_and_never_gets_up() -> void:
	_enemy.downed_variation = 0.0
	_enemy.downed_duration = 1.0
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _frames(2)
	_enemy.stomp()
	await _seconds(2.0)
	assert_true(is_instance_valid(_enemy))
	assert_true(_enemy.is_dead())
	assert_eq(_enemy.rotation_degrees.x, 90.0)
	assert_eq(_enemy.collision_layer, 0)


func test_stomp_does_nothing_to_a_standing_enemy() -> void:
	assert_false(_enemy.stomp())
	assert_false(_enemy.is_dead())


func test_a_knockdown_hit_downs_a_healthy_enemy_who_keeps_its_health() -> void:
	var hit := HitData.create(10.0, _player)
	hit.causes_knockdown = true
	_enemy.hurtbox.receive_hit(hit)
	await _frames(2)
	assert_true(_enemy.is_downed())
	assert_eq(_enemy.health_component.current_health, 90.0)
	_enemy.brain.downed_duration = 0.0
	await _frames(3)
	assert_false(_enemy.is_downed())
	assert_eq(_enemy.health_component.current_health, 90.0)


func test_hits_do_not_stagger_a_downed_enemy() -> void:
	var hit := HitData.create(10.0, _player)
	hit.causes_knockdown = true
	_enemy.hurtbox.receive_hit(hit)
	await _frames(2)
	_enemy.hurtbox.receive_hit(HitData.create(5.0, _player))
	await _frames(2)
	assert_eq(_enemy.get_state(), EnemyBrain.State.DOWNED)
