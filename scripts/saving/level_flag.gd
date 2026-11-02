## A saved, one-way fact about a level, such as `power_restored`: false until
## something sets it, then true for the rest of the run and in every save made
## after.
##
## Place one LevelFlag per flag in the level (the hotel keeps them under
## `LevelFlags`), with `flag_id` set to the flag's id from slice.md. The node
## is persistent (see WorldState) and its persistent id is `flag_id`.
##
## - The object that causes the fact calls set_flag(). That records the flag
##   in SaveSystem.world and emits `flag_set` with `is_loaded` false.
## - Loading a save that has the flag sets it again and emits `flag_set` with
##   `is_loaded` true, so effects can jump to their end state (no flicker, no
##   sound, no noise).
##
## A consumer (a shutter button, the lift, the porter, an examinable) takes
## the flag as an exported node reference and connects to it in _ready():
##
##     @export var power_flag: LevelFlag
##
##     func _ready() -> void:
##         power_flag.flag_set.connect(_on_power_restored)
##         if power_flag.is_set:
##             _on_power_restored(true)
##
## Loading applies the world state after the level's _ready(), so connecting
## there is enough to hear a loaded flag; checking `is_set` as well covers a
## consumer that enters the tree after the flag was set. Between the two, a
## consumer can ask `is_set` at any time, e.g. when the player interacts.
##
## Flags are never cleared: a new game instances the level fresh.

class_name LevelFlag
extends Node

## Emitted once, when the flag becomes set: `is_loaded` is false when it was
## set live with set_flag(), true when a loaded save set it.
signal flag_set(is_loaded: bool)

## The flag's id, also its persistent id in saves (e.g. `power_restored`).
@export var flag_id: StringName

## Whether the flag is set. Read it; change it only through set_flag().
var is_set: bool = false


func _ready() -> void:
	add_to_group(WorldState.GROUP)
	if flag_id.is_empty():
		flag_id = WorldState.default_id(self)


## Sets the flag live and records it in SaveSystem.world. Does nothing if it
## is already set.
func set_flag() -> void:
	if is_set:
		return
	SaveSystem.world.record(flag_id, {"is_set": true})
	_mark_set(false)


func get_persistent_id() -> StringName:
	return flag_id


## Takes back a recorded state: sets the flag if the save had it set.
func load_state(state: Dictionary) -> void:
	var saved: Variant = state.get("is_set")
	if saved is bool and saved and not is_set:
		_mark_set(true)


func _mark_set(is_loaded: bool) -> void:
	is_set = true
	flag_set.emit(is_loaded)
