## Tests for the hotel's examinables (slice.md, "Examinables"): every object in
## the table is placed with its lines, and the player can stand where it is
## the one picked, without hiding the doors, pickups and switches next to it.

extends "res://tests/levels/hotel_level_test.gd"

## slice.md's Examinables table: node under Examinables -> the object.
const EXAMINABLES: Dictionary[String, String] = {
	"SecondFloor/PhoneRoom22": "Room 22: phone",
	"SecondFloor/WristbandRoom22": "Room 22: wristband",
	"SecondFloor/NightstandRoom22": "Room 22: nightstand",
	"SecondFloor/BedsRoom22": "Room 22: beds",
	"SecondFloor/LiftSecondFloor": "2F lift hall: lift",
	"FirstFloor/LiftFirstFloor": "1F lift hall: lift",
	"GroundFloor/LiftGroundFloor": "Lobby: lift",
	"SecondFloor/DoorRoom24": "2F: room 24's door",
	"SecondFloor/ChairRoom28": "Room 28: chair",
	"FirstFloor/BedsRoom12": "Room 12: beds",
	"FirstFloor/BuildingSiteRoom15": "Room 15: building work",
	"GroundFloor/BuildingSiteGroundFloor": "GF building site: building work",
	"Basement/BasementDoor": "Stairs, below GF: basement door",
	"GroundFloor/DiningTable": "Dining room: a table",
	"GroundFloor/ClockWall": "Lobby: clock wall",
	"GroundFloor/KeyBoard": "Lobby: key board",
	"Basement/RollerShutter": "Basement corridor: roller shutter",
	"Basement/Switchboard": "Boiler room: switchboard",
	"Basement/PorterLocker": "Changing room: the porter's locker",
	"GroundFloor/ReceptionDesk": "Lobby, after the power: the desk",
}

## Examinables whose text changes, with the lines they need after the change.
const CHANGING: Array[String] = [
	"SecondFloor/NightstandRoom22",
	"SecondFloor/LiftSecondFloor",
	"FirstFloor/LiftFirstFloor",
	"GroundFloor/LiftGroundFloor",
	"Basement/BasementDoor",
	"Basement/Switchboard",
]

## How close another interactable must be to count as a neighbour that must
## stay reachable.
const NEIGHBOUR_DISTANCE: float = 2.0

## The share of its standing spots a neighbour must keep with the examinables
## placed.
const KEPT_SPOTS: float = 0.5

## Interactables right next to an examinable, which the player still has to
## be able to use.
const NEIGHBOURS: Array[String] = [
	"Mechanisms/SwitchboardBasement",
	"Doors/SecondFloor/DoorRoom24",
	"Doors/Basement/DoorBasement",
	"Pickups/PickupKeyStairs",
	"Pickups/PickupKeyRoom16",
	"Pickups/PickupKeyFrontDoor",
]

## Rings of standing spots tried around a target, and the spots per ring.
const RING_STEP: float = 0.1
const RING_SPOTS: int = 36

## How far a standing spot may be from the navmesh and still count as on it.
const ON_NAVMESH: float = 0.05

## The player's eyes above the floor, and how far short of a target a wall
## may stop the line of sight (the prop the target sits on or in).
const EYE_HEIGHT: float = 1.6
const SIGHT_SLACK: float = 0.3

var _interaction: PlayerInteraction


func before_each() -> void:
	SaveSystem.reset()
	await super.before_each()
	_interaction = _level.get_node("Player/PlayerInteraction") as PlayerInteraction


func after_each() -> void:
	super.after_each()
	SaveSystem.reset()


func test_every_examinable_in_the_doc_is_placed_with_its_lines() -> void:
	var placed: Array[String] = []
	for node: Node in _level.get_node("Examinables").find_children("*", "Examinable", true, false):
		placed.append(str(_level.get_node("Examinables").get_path_to(node)))
	placed.sort()
	var expected: Array[String] = EXAMINABLES.keys()
	expected.sort()
	assert_eq(placed, expected)
	for path: String in EXAMINABLES:
		var examinable: Examinable = _examinable(path)
		assert_false(examinable.lines.is_empty(), EXAMINABLES[path])
		for line: String in examinable.lines:
			assert_false(line.strip_edges().is_empty(), EXAMINABLES[path])


func test_the_ones_that_change_have_lines_for_after() -> void:
	for path: String in CHANGING:
		var examinable := _examinable(path) as StateExaminable
		assert_not_null(examinable, path)
		if examinable:
			assert_false(examinable.lines_after.is_empty(), EXAMINABLES[path])
			assert_ne(examinable.lines_after, examinable.lines, EXAMINABLES[path])


func test_each_examinable_is_within_reach_of_the_navmesh() -> void:
	for path: String in EXAMINABLES:
		var examinable: Examinable = _examinable(path)
		var position: Vector3 = examinable.global_position
		assert_lt(_distance_from_floor(position), _interaction.interact_range, EXAMINABLES[path])
		assert_lt(
			position.y - _floor_of(position), _interaction.interact_height, EXAMINABLES[path]
		)


func test_each_examinable_is_picked_from_somewhere_before_the_power() -> void:
	for path: String in EXAMINABLES:
		if _examinable(path).is_in_group(Interactable.GROUP):
			assert_true(_has_spot_picking(_examinable(path)), EXAMINABLES[path])


func test_each_examinable_is_picked_from_somewhere_after_the_power() -> void:
	_set_flag(&"PowerRestored")
	_set_flag(&"PorterLogRead")
	for path: String in EXAMINABLES:
		if _examinable(path).is_in_group(Interactable.GROUP):
			assert_true(_has_spot_picking(_examinable(path)), EXAMINABLES[path])


func test_a_spot_nobody_can_stand_near_is_not_picked() -> void:
	var inside_the_shaft := Examinable.new()
	_level.add_child(inside_the_shaft)
	inside_the_shaft.global_position = Vector3(21.0, GROUND_Y + 1.0, -6.6)
	assert_false(_has_spot_picking(inside_the_shaft))


func test_the_neighbours_stay_reachable_before_the_power() -> void:
	var neighbours: Array[Interactable] = _neighbours()
	for path: String in NEIGHBOURS:
		assert_true(_level.get_node(path) in neighbours, path)
	_assert_neighbours_keep_their_spots(neighbours)


func test_the_neighbours_stay_reachable_after_the_power() -> void:
	_set_flag(&"PowerRestored")
	_assert_neighbours_keep_their_spots(_neighbours())


func test_the_switchboard_wins_where_the_player_throws_it() -> void:
	var switchboard := _level.get_node("Mechanisms/SwitchboardBasement") as Interactable
	# The spot test_hotel_power uses, and coming in from the boiler room door.
	for spot: Vector3 in [Vector3(14.5, BASEMENT_Y, -5.9), Vector3(14.8, BASEMENT_Y, -5.7)]:
		assert_eq(_pick_from(spot, switchboard.global_position), switchboard, str(spot))


## Each neighbour can still be picked from most of the spots it could be
## picked from without the examinables.
func _assert_neighbours_keep_their_spots(neighbours: Array[Interactable]) -> void:
	var examinables: Array[Node] = get_tree().get_nodes_in_group(Interactable.GROUP).filter(
		func(node: Node) -> bool: return node is Examinable
	)
	var kept: Dictionary[Interactable, int] = {}
	for neighbour: Interactable in neighbours:
		kept[neighbour] = _count_spots_picking(neighbour)
	for examinable: Node in examinables:
		examinable.remove_from_group(Interactable.GROUP)
	for neighbour: Interactable in neighbours:
		var alone: int = _count_spots_picking(neighbour)
		var name: String = str(_level.get_path_to(neighbour))
		assert_gt(kept[neighbour], 0, name)
		assert_gte(kept[neighbour], ceili(alone * KEPT_SPOTS), "%s: %d of %d spots" % [name, kept[neighbour], alone])
	for examinable: Node in examinables:
		examinable.add_to_group(Interactable.GROUP)


func _examinable(path: String) -> Examinable:
	return _level.get_node("Examinables/" + path) as Examinable


func _set_flag(flag_name: StringName) -> void:
	(_level.get_node("LevelFlags/" + flag_name) as LevelFlag).set_flag()


## Interactables placed near an examinable, other than examinables.
func _neighbours() -> Array[Interactable]:
	var neighbours: Array[Interactable] = []
	var examinables: Array[Node] = _level.get_node("Examinables").find_children(
		"*", "Examinable", true, false
	)
	for node: Node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if interactable is Examinable or interactable in neighbours:
			continue
		for examinable: Node in examinables:
			var offset: Vector3 = (examinable as Node3D).global_position - interactable.global_position
			if absf(offset.y) < 2.5 and Vector2(offset.x, offset.z).length() < NEIGHBOUR_DISTANCE:
				neighbours.append(interactable)
				break
	return neighbours


## Whether there is a spot on the navmesh, on the target's floor, from which
## the player facing the target picks it.
func _has_spot_picking(target: Interactable) -> bool:
	return _count_spots_picking(target, 1) > 0


## How many spots on the navmesh within reach of `target`, with nothing solid
## between them and it, pick it. Stops at `enough`.
func _count_spots_picking(target: Interactable, enough: int = 100000) -> int:
	var center: Vector3 = target.global_position
	var floor_y: float = _floor_of(center)
	var space: PhysicsDirectSpaceState3D = _level.get_world_3d().direct_space_state
	var count: int = 0
	var radius: float = RING_STEP
	while radius <= _interaction.interact_range and count < enough:
		for i: int in RING_SPOTS:
			var angle: float = TAU * i / RING_SPOTS
			var spot := Vector3(
				center.x + cos(angle) * radius, floor_y, center.z + sin(angle) * radius
			)
			var closest: Vector3 = NavigationServer3D.map_get_closest_point(_map(), spot)
			var off_mesh: float = Vector2(closest.x - spot.x, closest.z - spot.z).length()
			if off_mesh > ON_NAVMESH or absf(closest.y - floor_y) > 0.5:
				continue
			if _pick_from(spot, center) != target:
				continue
			var sight := PhysicsRayQueryParameters3D.create(
				spot + Vector3.UP * EYE_HEIGHT, center, CombatLayers.WORLD
			)
			var hit: Dictionary = space.intersect_ray(sight)
			if hit.is_empty() or (hit[&"position"] as Vector3).distance_to(center) < SIGHT_SLACK:
				count += 1
		radius += RING_STEP
	return count


## The interactable PlayerInteraction picks for a player standing at `spot`
## and facing `toward`.
func _pick_from(spot: Vector3, toward: Vector3) -> Interactable:
	var candidates: Array[Interactable] = []
	var positions: Array[Vector3] = []
	for node: Node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if interactable:
			candidates.append(interactable)
			positions.append(interactable.global_position)
	var index: int = SoftTargeting.pick(
		spot,
		toward - spot,
		positions,
		_interaction.interact_range,
		_interaction.interact_angle,
		_interaction.interact_height
	)
	return candidates[index] if index >= 0 else null

