## Tests for enemies as persistent objects: recording and loading corpses.

extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DT: float = 1.0 / 60.0

var _enemy: Enemy
var _player: Player


func before_each() -> void:
	SaveSystem.reset()
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
	SaveSystem.reset()


func _spawn_enemy(position: Vector3) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = position
	# Face the origin, where the player stands.
	enemy.rotation.y = atan2(position.x, position.z)
	add_child_autofree(enemy)
	return enemy


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await _frames(int(ceil(seconds / DT)))


func test_is_persistent() -> void:
	assert_true(_enemy.is_in_group(WorldState.GROUP))
	assert_eq(_enemy.get_persistent_id(), WorldState.default_id(_enemy))


func test_a_living_enemy_records_nothing_even_when_downed() -> void:
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _frames(2)
	assert_true(_enemy.is_downed())
	assert_false(SaveSystem.world.has_state(_enemy.enemy_id))


func test_dying_records_the_corpse_position() -> void:
	_enemy.hurtbox.receive_hit(HitData.create(100.0, _player))
	await _frames(2)
	_enemy.stomp()
	await _frames(1)
	var state: Dictionary = SaveSystem.world.get_state(_enemy.enemy_id)
	assert_eq(state.get("is_dead"), true)
	assert_eq(WorldState.decode_vector(state.get("position")), _enemy.global_position)
	assert_eq(WorldState.decode_vector(state.get("rotation")), _enemy.rotation)


func test_loading_a_dead_state_lays_the_corpse_where_it_was() -> void:
	var corpse_position := Vector3(4.0, 0.0, -3.0)
	var corpse_rotation := Vector3(deg_to_rad(-90.0), 1.0, 0.0)
	var state: Dictionary = {
		"is_dead": true,
		"position": WorldState.encode_vector(corpse_position),
		"rotation": WorldState.encode_vector(corpse_rotation),
	}
	_enemy.load_state(state)
	assert_true(_enemy.is_dead())
	assert_false(_enemy.is_in_group(Enemy.ENEMY_GROUP))
	assert_almost_eq(_enemy.global_position, corpse_position, Vector3.ONE * 0.001)
	assert_almost_eq(_enemy.rotation, corpse_rotation, Vector3.ONE * 0.001)
	await _seconds(0.5)
	assert_true(_enemy.is_dead())


func test_loading_another_state_leaves_it_alive() -> void:
	_enemy.load_state({})
	_enemy.load_state({"is_dead": false})
	assert_false(_enemy.is_dead())
