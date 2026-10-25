## Scene-level tests: the real player and training dummy scenes exchanging
## hits through hitboxes and hurtboxes on the combat layers.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/enemies/training_dummy.tscn")

var _player: Player
var _dummy: TrainingDummy


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
	# The dummy stands in front of the player (towards -Z), facing the player.
	_dummy = DUMMY_SCENE.instantiate() as TrainingDummy
	_dummy.position = Vector3(0.0, 0.0, 1.0)
	add_child_autofree(_dummy)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func test_scenes_wire_combat_nodes() -> void:
	assert_not_null(_player.health_component)
	assert_not_null(_player.hurtbox)
	assert_eq(_player.hurtbox.health_component, _player.health_component)
	assert_not_null(_dummy.health_component)
	assert_not_null(_dummy.hurtbox)
	assert_not_null(_dummy.attack_hitbox)
	assert_eq(_dummy.hurtbox.health_component, _dummy.health_component)


func test_layers_follow_the_convention() -> void:
	assert_eq(_player.collision_layer, CombatLayers.PLAYER)
	assert_eq(_dummy.collision_layer, CombatLayers.ENEMY)
	assert_eq(_player.hurtbox.collision_layer, CombatLayers.PLAYER_HURTBOX)
	assert_eq(_dummy.hurtbox.collision_layer, CombatLayers.ENEMY_HURTBOX)
	assert_eq(_dummy.attack_hitbox.collision_layer, CombatLayers.ENEMY_HITBOX)
	assert_eq(_dummy.attack_hitbox.collision_mask, CombatLayers.PLAYER_HURTBOX)


func test_inactive_hitbox_does_no_damage() -> void:
	await _physics_frames(5)
	assert_eq(_player.health_component.current_health, 100.0)


func test_dummy_attack_damages_player_once_per_window() -> void:
	await _physics_frames(2)
	assert_true(_dummy.attack())
	await _physics_frames(6)
	assert_eq(_player.health_component.current_health, 80.0, "hit once despite staying inside")


func test_new_window_can_hit_again() -> void:
	await _physics_frames(2)
	_dummy.attack()
	await _physics_frames(30)
	assert_false(_dummy.is_attacking)
	_dummy.attack()
	await _physics_frames(6)
	assert_eq(_player.health_component.current_health, 60.0)


func test_invulnerable_player_takes_no_damage() -> void:
	_player.health_component.is_invulnerable = true
	await _physics_frames(2)
	_dummy.attack()
	await _physics_frames(6)
	assert_eq(_player.health_component.current_health, 100.0)


func test_hit_staggers_dummy_and_cancels_its_attack() -> void:
	await _physics_frames(2)
	_dummy.attack()
	var hit := HitData.create(10.0, _player, Vector3.FORWARD)
	_dummy.hurtbox.receive_hit(hit)
	assert_true(_dummy.is_staggered)
	assert_false(_dummy.is_attacking)
	assert_eq(_dummy.health_component.current_health, 90.0)


func test_dummy_dies_and_stops_attacking() -> void:
	watch_signals(_dummy)
	_dummy.hurtbox.receive_hit(HitData.create(500.0, _player))
	assert_signal_emitted(_dummy, "died")
	assert_false(_dummy.attack())


func test_hit_direction_points_from_attacker_to_victim() -> void:
	var hitbox: Hitbox = _dummy.attack_hitbox
	var hit: HitData = hitbox.make_hit(_player)
	assert_almost_eq(hit.direction, Vector3.FORWARD, Vector3.ONE * 0.001)
	assert_eq(hit.damage, 20.0)
