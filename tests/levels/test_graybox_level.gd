## Tests for the graybox level: layout, collisions, navmesh, spawn and enemies.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/graybox_level.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _level: Node3D


func before_each() -> void:
	_level = LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(_level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Let the navigation map take in the region.
	_map()
	await get_tree().physics_frame


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _map() -> RID:
	var map: RID = (
		(_level.get_node("NavigationRegion3D") as NavigationRegion3D).get_navigation_map()
	)
	NavigationServer3D.map_force_update(map)
	return map


## Distance along the navmesh path from `from` to `to`, or -1 if `to` can't be reached.
func _path_length(from: Vector3, to: Vector3) -> float:
	var path: PackedVector3Array = NavigationServer3D.map_get_path(_map(), from, to, true)
	if path.size() < 2 or path[path.size() - 1].distance_to(to) > 1.0:
		return -1.0
	var length: float = 0.0
	for i: int in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


func test_a_new_game_starts_in_the_graybox_level() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/main.tscn")
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	GameFlow.start_new_game()
	assert_not_null(main.get_node_or_null("ScreenHost/GrayboxLevel/Player"))


func test_has_a_foggy_street_and_interior() -> void:
	assert_eq(_level.get_node("Street").find_children("*", "FogVolume", true, false).size(), 1)
	assert_gt(_level.get_node("Building").get_child_count(), 10)
	assert_not_null(_level.get_node_or_null("Building/Ceiling"))


func test_the_environment_is_the_shared_one() -> void:
	var world_env := _level.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(world_env.environment.resource_path, "res://assets/data/atmosphere_environment.tres")


func test_every_mesh_has_a_collider() -> void:
	var meshes: Array[Node] = []
	for name: String in ["Floor", "Building", "Street"]:
		meshes.append_array(_level.get_node(name).find_children("*", "MeshInstance3D", true, false))
	assert_gt(meshes.size(), 20)
	for node: Node in meshes:
		var body := node.get_parent() as StaticBody3D
		assert_not_null(body, "%s is not under a static body" % node.name)
		if body:
			assert_eq(body.collision_layer & CombatLayers.WORLD, CombatLayers.WORLD)
			assert_gt(body.find_children("*", "CollisionShape3D", false, false).size(), 0)


func test_player_spawns_at_the_spawn_point() -> void:
	var spawn := _level.get_node("PlayerSpawn") as Marker3D
	var player := _level.get_node("Player") as Player
	assert_not_null(spawn)
	assert_almost_eq(player.global_position.x, spawn.global_position.x, 0.5)
	assert_almost_eq(player.global_position.z, spawn.global_position.z, 0.5)


func test_at_least_two_enemies_are_placed() -> void:
	assert_gte(_level.get_node("Enemies").get_child_count(), 2)
	assert_gte(get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP).size(), 2)


func test_the_navmesh_is_baked_and_covers_the_player_spawn() -> void:
	var region := _level.get_node("NavigationRegion3D") as NavigationRegion3D
	assert_gt(region.navigation_mesh.get_polygon_count(), 50)
	var spawn: Vector3 = (_level.get_node("PlayerSpawn") as Marker3D).global_position
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map(), spawn)
	assert_lt(closest.distance_to(spawn), 0.5)


func _door(door_name: String) -> Door:
	return _level.get_node("Doors/%s" % door_name) as Door


func test_has_doors_between_the_rooms() -> void:
	assert_gte(_level.get_node("Doors").get_child_count(), 6)
	assert_true(_door("DoorStorageEast").is_locked)
	assert_true(_door("DoorRoomB").is_locked)
	assert_false(_door("DoorFront").is_locked)


## Opens a door and lets the navigation server pick up its link.
func _open(door_name: String, from: Vector3) -> void:
	_door(door_name).open(from)
	await get_tree().physics_frame
	await get_tree().physics_frame


func test_closed_doors_cut_the_rooms_off_from_the_street() -> void:
	var spawn: Vector3 = (_level.get_node("PlayerSpawn") as Marker3D).global_position
	assert_eq(_path_length(spawn, Vector3(3, 0, 4)), -1.0, "lobby")
	assert_eq(_path_length(spawn, Vector3(0, 0, 0)), -1.0, "corridor")


func test_opening_doors_opens_the_path() -> void:
	var spawn: Vector3 = (_level.get_node("PlayerSpawn") as Marker3D).global_position
	await _open("DoorFront", Vector3(0, 0, 14))
	assert_gt(_path_length(spawn, Vector3(3, 0, 4)), 0.0, "lobby")
	assert_eq(_path_length(spawn, Vector3(0, 0, 0)), -1.0, "corridor is still shut off")
	await _open("DoorLobby", Vector3(0, 0, 5))
	assert_gt(_path_length(spawn, Vector3(0, 0, 0)), 0.0, "corridor")


func test_closing_a_door_shuts_the_path_again() -> void:
	var spawn: Vector3 = (_level.get_node("PlayerSpawn") as Marker3D).global_position
	await _open("DoorFront", Vector3(0, 0, 14))
	_door("DoorFront").close()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_path_length(spawn, Vector3(3, 0, 4)), -1.0)


func test_locked_doors_never_open() -> void:
	var door: Door = _door("DoorRoomB")
	door.open(Vector3(8, 0, 0))
	assert_false(door.is_open)
