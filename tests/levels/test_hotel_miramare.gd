## Tests for the hotel graybox: floors, collisions, spawn, doors, navmesh and
## stairs, against the layout in docs/design/slice.md.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/hotel_miramare.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const FLOORS: Array[String] = ["Basement", "GroundFloor", "FirstFloor", "SecondFloor"]

## Floor heights, from the basement up.
const BASEMENT_Y: float = -3.2
const GROUND_Y: float = 0.0
const FIRST_Y: float = 3.2
const SECOND_Y: float = 6.4

## Every door in slice.md's locks table.
const DOOR_IDS: Array[StringName] = [
	&"door_room_21",
	&"door_room_22",
	&"door_room_23",
	&"door_room_24",
	&"door_room_25",
	&"door_room_26",
	&"door_stairs_2f",
	&"door_linen_room",
	&"door_room_11",
	&"door_room_12",
	&"door_room_13",
	&"door_room_14",
	&"door_room_15",
	&"door_room_16",
	&"door_stairs_1f",
	&"door_stairs_gf",
	&"door_building_site_gf",
	&"door_kitchen",
	&"door_dining_corridor",
	&"door_dining_lobby",
	&"door_office_lobby",
	&"door_tv_room",
	&"door_front",
	&"door_basement",
	&"door_laundry",
	&"door_boiler_room",
	&"door_storage",
	&"door_pantry",
	&"door_staff_room",
	&"door_changing_room",
]

## Locked doors that open with a key item: door id -> key item id.
const DOOR_KEYS: Dictionary[StringName, StringName] = {
	&"door_stairs_2f": &"key_stairs",
	&"door_stairs_1f": &"key_stairs",
	&"door_room_16": &"key_room_16",
	&"door_basement": &"key_basement",
	&"door_front": &"key_front_door",
}

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


func _spawn() -> Vector3:
	return (_level.get_node("PlayerSpawn") as Marker3D).global_position


func _doors() -> Array[Door]:
	var doors: Array[Door] = []
	for node: Node in _level.get_node("Doors").find_children("*", "", true, false):
		if node is Door:
			doors.append(node as Door)
	return doors


func _door(door_id: StringName) -> Door:
	for door: Door in _doors():
		if door.door_id == door_id:
			return door
	return null


## Unlocks and opens a door, and lets the navigation server pick up its link.
func _open(door_id: StringName) -> void:
	var door: Door = _door(door_id)
	door.is_locked = false
	door.open(door.global_position + door.global_basis.z)
	await get_tree().physics_frame
	await get_tree().physics_frame


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
		var key: StringName = door.get_meta(&"key_id", &"")
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
