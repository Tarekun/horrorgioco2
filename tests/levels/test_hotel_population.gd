## Tests for what is placed in the hotel: enemies, pickups and their budget,
## save spots, persistent ids, the documents and the puzzle, against
## docs/design/slice.md.

extends "res://tests/levels/hotel_level_test.gd"

## slice.md's Items table: pickup id -> item id.
const PICKUPS: Dictionary[StringName, StringName] = {
	&"pickup_drink_room22": &"health_drink",
	&"blockade_room_28": &"wooden_plank",
	&"pickup_key_stairs": &"key_stairs",
	&"pickup_drink_linen": &"health_drink",
	&"pickup_pipe_site": &"steel_pipe",
	&"pickup_key_room16": &"key_room_16",
	&"pickup_aid_office": &"first_aid_kit",
	&"pickup_key_front_door": &"key_front_door",
}

## The healing budget: 2 health drinks and a first aid kit.
const HEALING_TOTAL: float = 130.0

## Enemy id -> whether it starts dormant (E1 waits for the power).
const ENEMIES: Dictionary[StringName, bool] = {
	&"enemy_boiler_room": true,
	&"enemy_staff_corridor": false,
	&"enemy_staff_room": false,
}

## Save spot id -> the floor it is on.
const SAVE_SPOTS: Dictionary[StringName, float] = {
	&"save_2f_corridor": SECOND_Y,
	&"save_gf_lobby": GROUND_Y,
	&"save_basement_stairs": BASEMENT_Y,
}

## slice.md's saved level flags.
const LEVEL_FLAGS: Array[StringName] = [&"power_restored", &"doc_porter_log_read"]

## Other persistent objects, by their ids in slice.md.
const MECHANISMS: Array[StringName] = [&"obstacle_sunbeds", &"shutter_staff"]

const DOCUMENT_IDS: Array[StringName] = [
	&"doc_registration_card", &"doc_lost_property", &"doc_porter_log", &"doc_postcard"
]

const PUZZLE_IDS: Array[StringName] = [&"puzzle_key_cabinet"]

## How far from where the player can stand something may be and still be used.
const REACH: float = 1.5


func test_the_pickups_are_the_ones_in_the_doc() -> void:
	var placed: Dictionary[StringName, StringName] = {}
	for pickup: Pickup in _pickups():
		placed[pickup.pickup_id] = pickup.item.id
	assert_eq(placed, PICKUPS)


func test_the_pickups_hold_the_budget() -> void:
	var healing: float = 0.0
	var weapons: Array[StringName] = []
	var max_health: float = 100.0
	for pickup: Pickup in _pickups():
		var item: ItemData = pickup.item
		assert_ne(item.category, ItemData.Category.AMMO, "no ammo in the slice")
		if item.category == ItemData.Category.HEALING:
			healing += item.get_healing(max_health) * pickup.get_amount()
			assert_gt(pickup.global_position.y, GROUND_Y - 0.1, "no healing in the basement")
		elif item.category == ItemData.Category.WEAPON:
			weapons.append(item.id)
	assert_eq(healing, HEALING_TOTAL)
	# StringNames sort by address, not by text.
	weapons.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	assert_eq(weapons, [&"steel_pipe", &"wooden_plank"] as Array[StringName])


func test_the_key_items_exist() -> void:
	for key: StringName in DOOR_KEYS.values():
		var item: ItemData = ItemCatalog.find(key)
		assert_not_null(item, str(key))
		if item:
			assert_eq(item.category, ItemData.Category.KEY_ITEM)


func test_taking_the_plank_opens_room_28() -> void:
	var space: PhysicsDirectSpaceState3D = _level.get_world_3d().direct_space_state
	var through_doorway := PhysicsRayQueryParameters3D.create(
		Vector3(3, SECOND_Y + 1.2, 0), Vector3(3, SECOND_Y + 1.2, -2.5), CombatLayers.WORLD
	)
	assert_false(space.intersect_ray(through_doorway).is_empty(), "the plank is across it")
	var player := _level.get_node("Player") as Player
	var blockade := _level.get_node("Pickups/BlockadeRoom28") as Pickup
	var planks: int = player.inventory.count(blockade.item)
	blockade.interact(player)
	assert_eq(player.inventory.count(blockade.item), planks + 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(space.intersect_ray(through_doorway).is_empty(), "the doorway is clear")


func test_the_enemies_are_in_the_basement() -> void:
	var placed: Dictionary[StringName, bool] = {}
	for enemy: Enemy in _enemies():
		placed[enemy.enemy_id] = enemy.is_dormant
		assert_almost_eq(_floor_of(enemy.global_position), BASEMENT_Y, 0.01, str(enemy.enemy_id))
		assert_lt(_distance_from_floor(enemy.global_position), 0.5, str(enemy.enemy_id))
	assert_eq(placed, ENEMIES)


func test_e1_waits_unseen_behind_the_boilers() -> void:
	var enemy := _level.get_node("Enemies/EnemyBoilerRoom") as Enemy
	var eyes: Vector3 = enemy.global_position + Vector3.UP * 1.0
	var space: PhysicsDirectSpaceState3D = _level.get_world_3d().direct_space_state
	# Standing in the doorway, and at the switchboard.
	for spot: Vector3 in [Vector3(15, BASEMENT_Y, -1.2), Vector3(14.2, BASEMENT_Y, -6.2)]:
		var sight := PhysicsRayQueryParameters3D.create(
			spot + Vector3.UP * 1.6, eyes, CombatLayers.WORLD
		)
		assert_false(space.intersect_ray(sight).is_empty(), "hidden from %s" % spot)
	await _open(&"door_boiler_room")
	assert_gt(_path_length(enemy.global_position, Vector3(15, BASEMENT_Y, 0)), 0.0, "can come out")


func test_the_staff_room_enemy_can_come_out() -> void:
	var staff_room := _level.get_node("Enemies/EnemyStaffRoom") as Enemy
	var staff_corridor := Vector3(24, BASEMENT_Y, 0)
	assert_gt(_path_length(staff_room.global_position, staff_corridor), 0.0)


func test_the_save_spots_are_the_ones_in_the_doc() -> void:
	var placed: Dictionary[StringName, float] = {}
	for node: Node in get_tree().get_nodes_in_group(SaveSpot.SAVE_SPOT_GROUP):
		var spot := node as SaveSpot
		placed[spot.spot_id] = _floor_of(spot.global_position)
		assert_false(spot.area_name.is_empty())
		assert_lt(_distance_from_floor(spot.spawn_point.global_position), 0.5, str(spot.spot_id))
	assert_eq(placed, SAVE_SPOTS)


func test_the_documents_are_the_ones_in_the_doc() -> void:
	var ids: Array[StringName] = []
	for pickup: DocumentPickup in _documents():
		assert_not_null(pickup.item, pickup.name)
		if pickup.item:
			assert_true(pickup.item.is_document(), pickup.name)
			assert_false(pickup.item.pages.is_empty(), pickup.name)
			assert_eq(pickup.pickup_id, pickup.item.id, pickup.name)
			ids.append(pickup.item.id)
	assert_eq(ids, DOCUMENT_IDS)


func test_the_key_cabinet_gives_the_basement_key() -> void:
	var cabinet := _level.get_node("Puzzles/PuzzleKeyCabinet") as CombinationLockPuzzle
	assert_eq(cabinet.puzzle_id, &"puzzle_key_cabinet")
	assert_eq(cabinet.wheel_count(), 4)
	assert_eq(cabinet.reward_item.id, DOOR_KEYS[&"door_basement"])
	var prop := _level.get_node("Props/FirstFloor/KeyCabinet") as Node3D
	assert_lt(cabinet.global_position.distance_to(prop.global_position), 1.0)


func test_everything_placed_can_be_reached() -> void:
	var placed: Array[Node3D] = []
	placed.append_array(_pickups())
	placed.append_array(_documents())
	placed.append(_level.get_node("Puzzles/PuzzleKeyCabinet") as Node3D)
	for node: Node3D in placed:
		assert_lt(_distance_from_floor(node.global_position), REACH, node.name)
		assert_lt(node.global_position.y - _floor_of(node.global_position), 2.0, node.name)


func test_every_persistent_object_has_its_own_id() -> void:
	var ids: Dictionary[StringName, Node] = {}
	var nodes: Array[Node] = get_tree().get_nodes_in_group(WorldState.GROUP)
	nodes.append_array(get_tree().get_nodes_in_group(SaveSpot.SAVE_SPOT_GROUP))
	for node: Node in nodes:
		var id: StringName = node.get(&"spot_id") if node is SaveSpot else node.get_persistent_id()
		assert_false(ids.has(id), "%s is used twice" % id)
		# A path-based default id would break as soon as the level is rearranged.
		assert_false(String(id).contains("/"), "%s has no explicit id" % node.name)
		ids[id] = node
	for flag: StringName in LEVEL_FLAGS:
		assert_true(ids.has(flag), "%s is placed" % flag)
	for id: StringName in MECHANISMS:
		assert_has(ids, id)
	assert_eq(
		ids.size(),
		(
			DOOR_IDS.size()
			+ PICKUPS.size()
			+ DOCUMENT_IDS.size()
			+ PUZZLE_IDS.size()
			+ ENEMIES.size()
			+ SAVE_SPOTS.size()
			+ LEVEL_FLAGS.size()
			+ MECHANISMS.size()
		)
	)


func _documents() -> Array[DocumentPickup]:
	var documents: Array[DocumentPickup] = []
	for node: Node in _level.get_node("Documents").get_children():
		documents.append(node as DocumentPickup)
	return documents
