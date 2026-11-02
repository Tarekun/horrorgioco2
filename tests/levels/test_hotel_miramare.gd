## Tests for the hotel's layout: floors, collisions, spawn, doors, navmesh,
## stairs, lighting and budget, against docs/design/slice.md and visual-style.md.

extends "res://tests/levels/hotel_level_test.gd"

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const FLOORS: Array[String] = ["Basement", "GroundFloor", "FirstFloor", "SecondFloor"]
## Kit pieces nobody walks into: ceilings, window frames in their walls, pipes overhead.
const KIT_WITHOUT_COLLIDERS: Array[String] = ["ceiling", "window_frame", "ceiling_pipes"]
## The top of visual-style.md's guideline for the whole scene on screen. The hotel is held
## to it all at once, so no view can go over.
const MAX_TRIANGLES: int = 100000


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
	var lift_doors: Array[Node] = _level.get_node("Structure/Lift").find_children("LiftDoors*")
	assert_eq(lift_doors.size(), 3, "the lift doors on GF, 1F and 2F")


func test_the_environment_is_the_shared_one() -> void:
	var world_env := _level.get_node("WorldEnvironment") as WorldEnvironment
	assert_eq(world_env.environment.resource_path, "res://assets/data/atmosphere_environment.tres")


func test_the_kit_collides() -> void:
	var pieces: Array[Node3D] = _models("Structure")
	assert_gt(pieces.size(), 1000)
	for piece: Node3D in pieces:
		var kind: String = piece.scene_file_path.get_base_dir().get_file()
		if kind not in KIT_WITHOUT_COLLIDERS:
			assert_true(_collides(piece), "%s collides" % piece.get_path())


func test_furniture_standing_on_the_floor_collides() -> void:
	var checked: int = 0
	for model: Node3D in _models("Props"):
		var box: AABB = _bounds(model)
		var on_floor: bool = absf(box.position.y - _floor_of(box.get_center())) < 0.1
		if on_floor and box.size.y > 0.5 and box.size.x * box.size.z > 0.2:
			assert_true(_collides(model), "%s collides" % model.get_path())
			checked += 1
	assert_gt(checked, 80)


func test_the_hotel_stays_within_its_triangle_budget() -> void:
	var triangles: int = 0
	for group_name: String in ["Structure", "Props"]:
		for node: Node in _level.get_node(group_name).find_children("*", "MeshInstance3D"):
			var mesh: Mesh = (node as MeshInstance3D).mesh
			for surface in mesh.get_surface_count():
				triangles += _surface_triangles(mesh.surface_get_arrays(surface))
	assert_between(triangles, 1, MAX_TRIANGLES)


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
	var obstacle := _level.get_node_or_null("Doors/GroundFloor/ObstacleSunbeds") as SunbedsObstacle
	assert_not_null(obstacle)
	assert_lt(obstacle.global_position.distance_to(door.global_position), 1.0, "against the door")


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


## The models placed under a group: the instances of glTF scenes.
func _models(group_name: String) -> Array[Node3D]:
	var models: Array[Node3D] = []
	for node: Node in _level.get_node(group_name).find_children("*", "Node3D"):
		if node.scene_file_path.ends_with(".gltf"):
			models.append(node as Node3D)
	return models


## Whether a model has a body on the world layer, as the kit's *-convcolonly nodes give.
func _collides(model: Node3D) -> bool:
	for node: Node in model.find_children("*", "StaticBody3D"):
		var body := node as StaticBody3D
		if body.collision_layer & CombatLayers.WORLD and body.get_child_count() > 0:
			return true
	return false


func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for node: Node in model.find_children("*", "MeshInstance3D"):
		var mesh := node as MeshInstance3D
		var part: AABB = mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


func _surface_triangles(arrays: Array) -> int:
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	return (indices.size() if not indices.is_empty() else vertices.size()) / 3
