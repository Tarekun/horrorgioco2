## The state of the world's persistent objects, keyed by persistent id: which
## pickups were collected, which doors were unlocked, which enemies died and
## where their corpses lie, and later puzzles and documents.
##
## A persistent object registers itself: it joins GROUP when it enters the
## tree and implements
##
## - get_persistent_id() -> StringName: an id that stays the same between runs
##   and is unique in its level (default_id() gives its path in the level);
## - load_state(state: Dictionary) -> void: takes back a state it recorded.
##
## When its state changes in a way a save must keep, it calls record() on the
## live world state, SaveSystem.world, with a JSON-safe dictionary. Objects
## still as they were placed record nothing, so only changes are kept. Loading
## a save instances the level fresh and calls apply() on it, which hands every
## registered object under it the state it recorded. No level needs its own
## saving code.

class_name WorldState
extends RefCounted

## Group every persistent object joins.
const GROUP: StringName = &"persistent"

var _states: Dictionary[StringName, Dictionary] = {}


## Records `state` for the object `id`, replacing what it had.
func record(id: StringName, state: Dictionary) -> void:
	_states[id] = state.duplicate(true)


## The state recorded for `id`, or an empty dictionary.
func get_state(id: StringName) -> Dictionary:
	var state: Dictionary = _states.get(id, {})
	return state.duplicate(true)


func has_state(id: StringName) -> bool:
	return _states.has(id)


func is_empty() -> bool:
	return _states.is_empty()


## Forgets every recorded state.
func clear() -> void:
	_states.clear()


## A copy that changes independently of this one.
func copy() -> WorldState:
	var other := WorldState.new()
	other.from_dict(to_dict())
	return other


## Hands each persistent object in `root` (or `root` itself) its recorded
## state. Objects with nothing recorded are left as placed.
func apply(root: Node) -> void:
	for node: Node in root.get_tree().get_nodes_in_group(GROUP):
		if node != root and not root.is_ancestor_of(node):
			continue
		if not node.has_method(&"get_persistent_id") or not node.has_method(&"load_state"):
			push_warning("WorldState: %s is in the group but isn't persistent." % node.name)
			continue
		var id := StringName(node.call(&"get_persistent_id"))
		if _states.has(id):
			node.call(&"load_state", get_state(id))


## The states as plain data, ready to save as JSON.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for id: StringName in _states:
		data[String(id)] = _states[id].duplicate(true)
	return data


## Replaces the states with saved ones (see to_dict()). Entries that aren't
## dictionaries are skipped.
func from_dict(data: Dictionary) -> void:
	_states.clear()
	for key: Variant in data:
		var state: Variant = data[key]
		if state is Dictionary:
			_states[StringName(str(key))] = (state as Dictionary).duplicate(true)


## The id `node` gets when none is set: its path from the scene it was placed
## in, followed up to the outermost one (the level), so the same room scene
## placed twice still gives distinct ids. Without an owner, its name.
static func default_id(node: Node) -> StringName:
	var level: Node = node.owner
	if level == null:
		return StringName(str(node.name))
	while level.owner != null:
		level = level.owner
	return StringName(str(level.get_path_to(node)))


## `vector` as a JSON-safe array.
static func encode_vector(vector: Vector3) -> Array[float]:
	return [vector.x, vector.y, vector.z]


## The vector encode_vector() made, or `fallback` if `value` isn't one.
static func decode_vector(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if not value is Array:
		return fallback
	var array: Array = value
	if array.size() != 3:
		return fallback
	for component: Variant in array:
		if not (component is float or component is int):
			return fallback
	return Vector3(float(array[0]), float(array[1]), float(array[2]))
