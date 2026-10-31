## Shared setup for the hotel's level tests: the level, its floors and doors
## from docs/design/slice.md, and navmesh helpers.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/hotel_miramare.tscn")
const NavigationSync: GDScript = preload("res://tests/levels/navigation_sync.gd")

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
	await NavigationSync.wait_for_region(
		_level.get_node("NavigationRegion3D") as NavigationRegion3D
	)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _map() -> RID:
	return (_level.get_node("NavigationRegion3D") as NavigationRegion3D).get_navigation_map()


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


func _pickups() -> Array[Pickup]:
	var pickups: Array[Pickup] = []
	for node: Node in _level.get_node("Pickups").get_children():
		pickups.append(node as Pickup)
	return pickups


func _enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for node: Node in _level.get_node("Enemies").get_children():
		enemies.append(node as Enemy)
	return enemies


## The floor height `point` is on.
func _floor_of(point: Vector3) -> float:
	var floor_y: float = BASEMENT_Y
	for y: float in [GROUND_Y, FIRST_Y, SECOND_Y]:
		if point.y >= y - 0.01:
			floor_y = y
	return floor_y


## How far `point` is from the nearest walkable spot on its own floor.
func _distance_from_floor(point: Vector3) -> float:
	var on_floor := Vector3(point.x, _floor_of(point), point.z)
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map(), on_floor)
	if absf(closest.y - on_floor.y) > 0.5:
		return INF
	return Vector2(closest.x - point.x, closest.z - point.z).length()


## Unlocks and opens a door, and lets the navigation server pick up its link.
func _open(door_id: StringName) -> void:
	var door: Door = _door(door_id)
	door.is_locked = false
	door.open(door.global_position + door.global_basis.z)
	await NavigationSync.wait_for_map_update(get_tree(), _map())
