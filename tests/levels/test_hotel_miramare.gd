## Tests for the hotel graybox's layout: floors, collisions, spawn, doors,
## navmesh, stairs and lighting, against docs/design/slice.md.

extends "res://tests/levels/hotel_level_test.gd"

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const FLOORS: Array[String] = ["Basement", "GroundFloor", "FirstFloor", "SecondFloor"]


func test_a_new_game_starts_in_the_hotel() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	GameFlow.start_new_game()
	assert_not_null(main.get_node_or_null("ScreenHost/HotelMiramare/Player"))


func test_has_four_floors_and_the_stairs() -> void:
	for floor_name: String in FLOORS:
		var floor_node: Node = _level.get_node("Structure/" + floor_name)
		assert_gt(floor_node.get_child_count(), 20, floor_name)
	assert_gt(_level.get_node("Structure/Stairs").get_child_count(), 6)
	assert_not_null(_level.get_node_or_null("Structure/Lift/LiftCore"))


func test_the_environment_is_the_shared_one() -> void:
	var world_env := _level.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(world_env.environment.resource_path, "res://assets/data/atmosphere_environment.tres")


func test_every_mesh_has_a_collider() -> void:
	var meshes: Array[Node] = []
	for name: String in ["Structure", "Props"]:
		meshes.append_array(_level.get_node(name).find_children("*", "MeshInstance3D", true, false))
	assert_gt(meshes.size(), 200)
	for node: Node in meshes:
		var body := node.get_parent() as StaticBody3D
		assert_not_null(body, "%s is not under a static body" % node.name)
		if body:
			assert_eq(body.collision_layer & CombatLayers.WORLD, CombatLayers.WORLD)
			assert_gt(body.find_children("*", "CollisionShape3D", false, false).size(), 0)


func test_the_player_spawns_in_room_22() -> void:
	var spawn: Vector3 = _spawn()
	var player := _level.get_node("Player") as Player
	assert_almost_eq(player.global_position.x, spawn.x, 0.5)
	assert_almost_eq(player.global_position.z, spawn.z, 0.5)
	# Room 22: the north-east corner room on 2F.
	assert_almost_eq(spawn.y, SECOND_Y, 0.5)
	assert_between(spawn.x, 24.0, 30.0)
	assert_between(spawn.z, -7.0, -1.0)


func test_the_doors_are_the_ones_in_the_doc() -> void:
	var ids: Array[StringName] = []
	for door: Door in _doors():
		ids.append(door.door_id)
	assert_eq(ids.size(), DOOR_IDS.size())
	for door_id: StringName in DOOR_IDS:
		assert_has(ids, door_id)


func test_locked_doors_are_marked_with_their_keys() -> void:
	for door: Door in _doors():
		var key: StringName = door.key_id
		assert_eq(key, DOOR_KEYS.get(door.door_id, &""), str(door.door_id))
		if not key.is_empty():
			assert_true(door.is_locked, "%s is locked" % door.door_id)


func test_the_ground_floor_stairs_are_blocked() -> void:
	var door: Door = _door(&"door_stairs_gf")
	assert_true(door.is_locked)
	assert_eq(door.get_meta(&"blocked_by", &""), &"obstacle_sunbeds")
	assert_not_null(_level.get_node_or_null("Props/GroundFloor/ObstacleSunbeds"))


func test_the_navmesh_covers_the_player_spawn() -> void:
	var region := _level.get_node("NavigationRegion3D") as NavigationRegion3D
	assert_gt(region.navigation_mesh.get_polygon_count(), 100)
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map(), _spawn())
	assert_lt(closest.distance_to(_spawn()), 0.5)


func test_the_closed_door_shuts_room_22_off() -> void:
	var corridor := Vector3(15, SECOND_Y, 0)
	assert_eq(_path_length(_spawn(), corridor), -1.0, "door shut")
	await _open(&"door_room_22")
	assert_gt(_path_length(_spawn(), corridor), 0.0, "door open")


func test_the_stairs_join_every_floor() -> void:
	await _open(&"door_room_22")
	var landings: Array[Vector3] = [
		Vector3(1.5, FIRST_Y, 2), Vector3(1.5, GROUND_Y, 2), Vector3(1.5, BASEMENT_Y, 2)
	]
	for landing: Vector3 in landings:
		assert_eq(_path_length(_spawn(), landing), -1.0, "stairs door shut: %s" % landing)
	await _open(&"door_stairs_2f")
	for landing: Vector3 in landings:
		assert_gt(_path_length(_spawn(), landing), 0.0, "stairs door open: %s" % landing)
	# The other floors' stairs doors are still shut.
	assert_eq(_path_length(_spawn(), Vector3(15, FIRST_Y, 0)), -1.0, "1F corridor")
	assert_eq(_path_length(_spawn(), Vector3(15, BASEMENT_Y, 0)), -1.0, "basement corridor")


func test_the_basement_shutter_closes_off_the_staff_quarters() -> void:
	await _open(&"door_room_22")
	await _open(&"door_stairs_2f")
	await _open(&"door_basement")
	assert_gt(_path_length(_spawn(), Vector3(15, BASEMENT_Y, 0)), 0.0, "basement corridor")
	assert_eq(_path_length(_spawn(), Vector3(24, BASEMENT_Y, 0)), -1.0, "staff corridor")


func test_the_lighting_follows_the_floors() -> void:
	var lights: Node = _level.get_node("Lights")
	assert_gt(lights.get_node("SecondFloor").get_child_count(), 5, "2F lit")
	assert_null(lights.get_node_or_null("FirstFloor"), "1F dark")
	assert_eq(lights.get_node("GroundFloor").get_child_count(), 1, "GF: the desk lamp")
	var boiler_room := lights.get_node("Basement/BoilerRoom") as Node3D
	assert_false(boiler_room.visible, "boiler room off until the power")


func test_the_player_uses_room_22s_door_not_the_ones_below_it() -> void:
	# Rooms 12, the TV room and the changing room have doors in the same spot.
	var player := _level.get_node("Player") as Player
	player.global_position = Vector3(27, SECOND_Y + 0.1, -1.8)
	player.rotation.y = PI
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, _door(&"door_room_22"))
	interaction.interact()
	assert_true(_door(&"door_room_22").is_open)
