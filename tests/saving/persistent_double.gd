## A persistent object that keeps the last state it was given. Helper for the
## world state tests.

extends Node3D

var persistent_id: StringName = &""
var loaded: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(WorldState.GROUP)


func get_persistent_id() -> StringName:
	return persistent_id


func load_state(state: Dictionary) -> void:
	loaded.append(state)
