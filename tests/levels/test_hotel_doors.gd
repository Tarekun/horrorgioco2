## Tests for the hotel's two special doors from docs/design/slice.md: the
## self-closing fire door to the basement and the glass double doors between
## the dining room and the lobby.

extends "res://tests/levels/hotel_level_test.gd"

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const DOUBLE_DOOR_PATH: String = "res://scenes/levels/double_door.tscn"
## The basement stairs: the landing in front of door_basement, the half landing
## of the flight down to it, and the corridor beyond the door.
const LANDING: Vector3 = Vector3(3, BASEMENT_Y, 2.2)
const HALF_LANDING: Vector3 = Vector3(1.5, BASEMENT_Y + 1.6, 6.2)
const BASEMENT_CORRIDOR: Vector3 = Vector3(6.5, BASEMENT_Y, 0)
## How long the chase in the basement runs, in physics frames (4 s).
const CHASE_FRAMES: int = 240

## The closest the enemy came to door_basement in the last chase.
var _closest_to_door: float = INF


func test_the_basement_door_closes_by_itself() -> void:
	var door: Door = _door(&"door_basement")
	assert_true(door.is_self_closing)
	assert_true(door.is_locked, "chained shut until K3")
	for other: Door in _doors():
		if other != door:
			assert_false(other.is_self_closing, "%s isn't self-closing" % other.door_id)


func test_a_chasing_enemy_cant_follow_the_player_through_the_basement_door() -> void:
	var door: Door = _door(&"door_basement")
	var enemy: Enemy = await _chase_through_basement_door()
	assert_false(door.is_open, "the door shut by itself")
	assert_false(door.navigation_link.enabled)
	assert_lt(_closest_to_door, 2.5, "the enemy came down to the door")
	assert_gt(enemy.global_position.z, door.global_position.z, "the enemy stayed on the stairs")
	var player := _level.get_node("Player") as Node3D
	assert_eq(_path_length(enemy.global_position, player.global_position), -1.0, "no way through")


func test_held_open_the_basement_door_lets_the_enemy_through() -> void:
	# The same chase, with the door kept open: the enemy only stays out
	# because the door shuts in time.
	var door: Door = _door(&"door_basement")
	door.close_delay = INF
	var enemy: Enemy = await _chase_through_basement_door()
	assert_true(door.is_open)
	assert_lt(enemy.global_position.z, door.global_position.z, "the enemy came through")


func test_the_dining_room_has_double_doors_to_the_lobby() -> void:
	var door: Door = _door(&"door_dining_lobby")
	assert_eq(door.scene_file_path, DOUBLE_DOOR_PATH)
	assert_not_null(door.second_hinge)
	assert_false(door.is_locked)


func test_the_double_doors_fit_their_doorway() -> void:
	var door: Door = _door(&"door_dining_lobby")
	var space: PhysicsDirectSpaceState3D = _level.get_world_3d().direct_space_state
	# Rays through the doorway, across the frame's 1.4 m clear width.
	var rays: Array[PhysicsRayQueryParameters3D] = []
	for across: float in [-0.5, 0.0, 0.5]:
		var at: Vector3 = door.global_position + door.global_basis.x * across + Vector3.UP * 1.2
		var through: Vector3 = door.global_basis.z * 0.8
		var ray := PhysicsRayQueryParameters3D.create(
			at - through, at + through, CombatLayers.WORLD
		)
		rays.append(ray)
	for ray: PhysicsRayQueryParameters3D in rays:
		assert_false(space.intersect_ray(ray).is_empty(), "shut: %s" % ray.from)
	door.open(door.global_position + door.global_basis.z)
	await get_tree().create_timer(door.swing_time + 0.2).timeout
	for ray: PhysicsRayQueryParameters3D in rays:
		assert_true(space.intersect_ray(ray).is_empty(), "open: %s" % ray.from)


func test_the_double_doors_join_the_dining_room_and_the_lobby() -> void:
	var dining := Vector3(14, GROUND_Y, -4)
	var lobby := Vector3(20, GROUND_Y, -3)
	assert_eq(_path_length(dining, lobby), -1.0, "doors shut")
	await _open(&"door_dining_lobby")
	assert_gt(_path_length(dining, lobby), 0.0, "doors open")


## An enemy comes down the basement stairs after the player, who opens
## door_basement and goes through into the corridor. The enemy always knows
## where the player is, as if it could see him. Returns the enemy after the chase.
func _chase_through_basement_door() -> Enemy:
	var door: Door = _door(&"door_basement")
	door.is_locked = false
	var player := _level.get_node("Player") as Player
	player.global_position = LANDING
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.is_dormant = true
	_level.add_child(enemy)
	enemy.global_position = NavigationServer3D.map_get_closest_point(_map(), HALF_LANDING)
	enemy.wake()
	door.interact(player)
	assert_true(door.is_open)
	player.global_position = BASEMENT_CORRIDOR
	_closest_to_door = INF
	for frame: int in CHASE_FRAMES:
		enemy.perception.alert_to(player.global_position)
		await get_tree().physics_frame
		var distance: float = enemy.global_position.distance_to(door.global_position)
		_closest_to_door = minf(_closest_to_door, distance)
	return enemy
