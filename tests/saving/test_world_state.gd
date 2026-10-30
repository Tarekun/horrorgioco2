## Tests for the world state: recording, copies, JSON round trips, ids and
## handing states back to persistent objects.

extends GutTest

const PersistentDouble := preload("res://tests/saving/persistent_double.gd")

var _world: WorldState


func before_each() -> void:
	_world = WorldState.new()


func _make_double(id: StringName, parent: Node) -> PersistentDouble:
	var double := PersistentDouble.new()
	double.name = String(id).replace("/", "_")
	double.persistent_id = id
	parent.add_child(double)
	return double


func test_starts_empty() -> void:
	assert_true(_world.is_empty())
	assert_false(_world.has_state(&"door"))
	assert_eq(_world.get_state(&"door"), {})


func test_records_a_state_by_id() -> void:
	_world.record(&"door", {"is_locked": false})
	assert_true(_world.has_state(&"door"))
	assert_eq(_world.get_state(&"door"), {"is_locked": false})


func test_a_new_record_replaces_the_old_one() -> void:
	_world.record(&"door", {"is_locked": true})
	_world.record(&"door", {"is_locked": false})
	assert_eq(_world.get_state(&"door"), {"is_locked": false})


func test_recorded_states_cant_be_changed_from_outside() -> void:
	var state: Dictionary = {"position": [1.0, 2.0, 3.0]}
	_world.record(&"enemy", state)
	(state["position"] as Array)[0] = 9.0
	var read: Dictionary = _world.get_state(&"enemy")
	read["position"] = []
	assert_eq(_world.get_state(&"enemy"), {"position": [1.0, 2.0, 3.0]})


func test_clear_forgets_everything() -> void:
	_world.record(&"door", {"is_locked": false})
	_world.clear()
	assert_true(_world.is_empty())


func test_a_copy_is_independent() -> void:
	_world.record(&"door", {"is_locked": false})
	var copy: WorldState = _world.copy()
	copy.record(&"pickup", {"is_collected": true})
	_world.record(&"door", {"is_locked": true})
	assert_eq(copy.get_state(&"door"), {"is_locked": false})
	assert_false(_world.has_state(&"pickup"))


func test_round_trips_through_json() -> void:
	_world.record(&"Pickups/Ammo", {"is_collected": true})
	_world.record(&"Doors/Office", {"is_locked": false})
	_world.record(
		&"Enemies/Yard",
		{"is_dead": true, "position": WorldState.encode_vector(Vector3(1.5, 0.0, -4.0))}
	)
	var parsed: Variant = JSON.parse_string(JSON.stringify(_world.to_dict()))
	var loaded := WorldState.new()
	loaded.from_dict(parsed)
	assert_eq(loaded.get_state(&"Pickups/Ammo"), {"is_collected": true})
	assert_eq(loaded.get_state(&"Doors/Office"), {"is_locked": false})
	var enemy: Dictionary = loaded.get_state(&"Enemies/Yard")
	assert_eq(WorldState.decode_vector(enemy["position"]), Vector3(1.5, 0.0, -4.0))


func test_from_dict_replaces_the_states_and_skips_bad_entries() -> void:
	_world.record(&"old", {"is_collected": true})
	_world.from_dict({"door": {"is_locked": false}, "junk": 3, "more_junk": "text"})
	assert_false(_world.has_state(&"old"))
	assert_true(_world.has_state(&"door"))
	assert_false(_world.has_state(&"junk"))
	assert_false(_world.has_state(&"more_junk"))


func test_vectors_encode_and_decode() -> void:
	var vector := Vector3(1.25, -2.0, 3.5)
	assert_eq(WorldState.decode_vector(WorldState.encode_vector(vector)), vector)


func test_decoding_something_else_gives_the_fallback() -> void:
	var fallback := Vector3(7.0, 8.0, 9.0)
	assert_eq(WorldState.decode_vector(null, fallback), fallback)
	assert_eq(WorldState.decode_vector([1.0, 2.0], fallback), fallback)
	assert_eq(WorldState.decode_vector([1.0, "a", 2.0], fallback), fallback)
	assert_eq(WorldState.decode_vector("(1, 2, 3)", fallback), fallback)


func test_apply_hands_recorded_states_to_registered_objects() -> void:
	var level := Node3D.new()
	add_child_autofree(level)
	var changed := _make_double(&"changed", level)
	var untouched := _make_double(&"untouched", level)
	_world.record(&"changed", {"is_collected": true})
	_world.apply(level)
	assert_eq(changed.loaded, [{"is_collected": true}] as Array[Dictionary])
	assert_eq(untouched.loaded.size(), 0)


func test_apply_only_reaches_objects_inside_the_root() -> void:
	var level := Node3D.new()
	add_child_autofree(level)
	var other_level := Node3D.new()
	add_child_autofree(other_level)
	var inside := _make_double(&"thing", level)
	var outside := _make_double(&"thing", other_level)
	_world.record(&"thing", {"is_collected": true})
	_world.apply(level)
	assert_eq(inside.loaded.size(), 1)
	assert_eq(outside.loaded.size(), 0)


func test_the_default_id_is_the_path_in_the_level() -> void:
	var level := Node3D.new()
	var room := Node3D.new()
	room.name = "Room"
	level.add_child(room)
	room.owner = level
	var thing := Node3D.new()
	thing.name = "Thing"
	room.add_child(thing)
	thing.owner = level
	add_child_autofree(level)
	assert_eq(WorldState.default_id(thing), &"Room/Thing")


func test_the_default_id_follows_nested_scenes_up_to_the_level() -> void:
	# A room scene placed in a level: the thing's owner is the room, whose
	# owner is the level. Two rooms of the same scene must not share ids.
	var level := Node3D.new()
	var rooms: Array[Node3D] = []
	for room_name: String in ["RoomA", "RoomB"]:
		var room := Node3D.new()
		room.name = room_name
		level.add_child(room)
		room.owner = level
		var thing := Node3D.new()
		thing.name = "Thing"
		room.add_child(thing)
		thing.owner = room
		rooms.append(room)
	add_child_autofree(level)
	var first: StringName = WorldState.default_id(rooms[0].get_node("Thing"))
	var second: StringName = WorldState.default_id(rooms[1].get_node("Thing"))
	assert_eq(first, &"RoomA/Thing")
	assert_eq(second, &"RoomB/Thing")


func test_without_an_owner_the_id_is_the_name() -> void:
	var thing := Node3D.new()
	thing.name = "Loose"
	add_child_autofree(thing)
	assert_eq(WorldState.default_id(thing), &"Loose")
