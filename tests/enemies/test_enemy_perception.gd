## Tests of enemy sight and hearing, with the real player and enemy scenes.

extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DT: float = 1.0 / 60.0

var _enemy: Enemy
var _player: Player
var _perception: EnemyPerception


func before_each() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_player.flashlight.set_on(false)
	_enemy = _spawn_enemy(Vector3(0.0, 0.0, -6.0), PI)
	_perception = _enemy.perception
	await _frames(2)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## An enemy at `position` looking along `yaw` (radians; 0 is towards -Z, PI towards +Z).
func _spawn_enemy(position: Vector3, yaw: float) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = position
	enemy.rotation.y = yaw
	add_child_autofree(enemy)
	return enemy


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds / DT)))


func _place_enemy(position: Vector3, yaw: float) -> void:
	_perception.lose_track()
	_enemy.global_position = position
	_enemy.rotation.y = yaw
	await _frames(2)


func test_is_in_view_checks_range_and_cone() -> void:
	var forward := Vector3.FORWARD
	assert_true(
		EnemyPerception.is_in_view(Vector3.ZERO, forward, Vector3(0, 0, -5), 10.0, 55.0, 1.5)
	)
	assert_false(
		EnemyPerception.is_in_view(Vector3.ZERO, forward, Vector3(0, 0, -11), 10.0, 55.0, 1.5)
	)
	assert_false(
		EnemyPerception.is_in_view(Vector3.ZERO, forward, Vector3(0, 0, 5), 10.0, 55.0, 1.5)
	)
	assert_true(
		EnemyPerception.is_in_view(Vector3.ZERO, forward, Vector3(4, 0, -4), 10.0, 55.0, 1.5)
	)
	assert_false(
		EnemyPerception.is_in_view(Vector3.ZERO, forward, Vector3(5, 0, -1), 10.0, 55.0, 1.5)
	)


func test_close_targets_are_noticed_all_round() -> void:
	assert_true(
		EnemyPerception.is_in_view(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 1), 10.0, 55.0, 1.5)
	)


func test_flashlight_extends_the_sight_range() -> void:
	assert_eq(EnemyPerception.effective_range(10.0, 1.8, false), 10.0)
	assert_eq(EnemyPerception.effective_range(10.0, 1.8, true), 18.0)


func test_sees_a_player_in_front() -> void:
	assert_true(_perception.can_see(_player))
	await _frames(2)
	assert_true(_perception.is_target_visible)
	assert_true(_perception.is_alert())


func test_does_not_see_a_player_behind() -> void:
	await _place_enemy(Vector3(0, 0, -6), 0.0)
	assert_false(_perception.can_see(_player))
	assert_false(_perception.is_alert())


func test_a_wall_blocks_sight() -> void:
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 3.0, 0.3)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 1.5, -3.0)
	add_child_autofree(wall)
	await _frames(2)
	assert_false(_perception.can_see(_player))


func test_the_flashlight_makes_the_player_visible_from_further() -> void:
	await _place_enemy(Vector3(0, 0, -15), PI)
	assert_false(_perception.can_see(_player))
	_player.flashlight.set_on(true)
	assert_true(_perception.can_see(_player))


func test_hearing_a_noise_alerts_the_enemy_to_its_position() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	watch_signals(_perception)
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -17), 5.0)
	assert_true(_perception.is_alert())
	assert_eq(_perception.last_known_position, Vector3(0, 0, -17))
	assert_signal_emitted(_perception, "alerted")


func test_a_noise_that_falls_short_is_not_heard() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -10), 5.0)
	assert_false(_perception.is_alert())


func test_the_enemy_loses_track_after_its_timeout() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	_perception.lose_track_time = 1.0
	watch_signals(_perception)
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -19), 3.0)
	await _seconds(0.6)
	assert_true(_perception.is_alert())
	await _seconds(0.6)
	assert_false(_perception.is_alert())
	assert_signal_emitted(_perception, "track_lost")


func test_a_noise_renews_the_alert() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	_perception.lose_track_time = 1.0
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -19), 3.0)
	await _seconds(0.7)
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -19), 3.0)
	await _seconds(0.7)
	assert_true(_perception.is_alert())


func test_an_enemy_that_lost_track_goes_back_to_wandering() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	_perception.lose_track_time = 0.5
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -19), 3.0)
	await _seconds(0.2)
	assert_eq(_enemy.get_state(), EnemyBrain.State.CHASE)
	await _seconds(0.6)
	assert_eq(_enemy.get_state(), EnemyBrain.State.WANDER)


func test_a_downed_enemy_hears_nothing() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	_enemy.hurtbox.receive_hit(HitData.create(500.0, _player))
	await _frames(2)
	NoiseEvent.emit_noise(get_tree(), Vector3(0, 0, -19), 3.0)
	assert_false(_perception.is_alert())


func test_being_hit_alerts_the_enemy_to_the_attacker() -> void:
	await _place_enemy(Vector3(0, 0, -20), PI)
	_enemy.hurtbox.receive_hit(HitData.create(5.0, _player))
	assert_true(_perception.is_alert())
	assert_eq(_perception.last_known_position, _player.global_position)
