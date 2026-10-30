## The save slots on disk: SLOT_COUNT manual slots, one JSON file each in
## `directory` (user://saves/ in the game).
##
## A file holds the format version and the SaveData:
## `{"version": 1, "save": {...}}`. Reading never fails hard: a missing file is
## an empty slot, and a damaged file or one from another format version is
## reported as such (with a warning) so the slot screen can show it.
## Writing goes through a temporary file, so a crash mid-write leaves the old
## save intact.

class_name SaveSlots
extends RefCounted

## How many manual save slots there are.
const SLOT_COUNT: int = 8

## Format of the files written now. Bump it when SaveData changes in a way
## older files can't follow.
const FORMAT_VERSION: int = 1

const DEFAULT_DIRECTORY: String = "user://saves"

var directory: String


func _init(save_directory: String = DEFAULT_DIRECTORY) -> void:
	directory = save_directory


## The file of `slot` (from 0).
func get_slot_path(slot: int) -> String:
	return directory.path_join("slot_%d.json" % (slot + 1))


## Writes `save` to `slot`, replacing what was there.
func write(slot: int, save: SaveData) -> Error:
	if not _is_valid_slot(slot):
		return ERR_PARAMETER_RANGE_ERROR
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	var path: String = get_slot_path(slot)
	var temporary_path: String = path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var data: Dictionary = {"version": FORMAT_VERSION, "save": save.to_dict()}
	# Unsorted, so the inventory keeps its order.
	file.store_string(JSON.stringify(data, "\t", false))
	file.close()
	return DirAccess.rename_absolute(temporary_path, path)


## The save in `slot`, or null when it is empty or can't be loaded.
func read(slot: int) -> SaveData:
	return read_info(slot).save


## What `slot` holds.
func read_info(slot: int) -> SaveSlotInfo:
	var info := SaveSlotInfo.new()
	info.slot = slot
	var path: String = get_slot_path(slot)
	if not _is_valid_slot(slot) or not FileAccess.file_exists(path):
		return info
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _unreadable(info, "not a save file")
	var data: Dictionary = json.data
	var version: Variant = data.get("version")
	if not (version is float or version is int):
		return _unreadable(info, "no format version")
	if int(version) != FORMAT_VERSION:
		push_warning(
			"SaveSlots: %s is format version %d, not %d." % [path, int(version), FORMAT_VERSION]
		)
		info.status = SaveSlotInfo.Status.WRONG_VERSION
		return info
	var save_data: Variant = data.get("save")
	var save: SaveData = SaveData.from_dict(save_data) if save_data is Dictionary else null
	if save == null:
		return _unreadable(info, "no save in it")
	info.status = SaveSlotInfo.Status.OK
	info.save = save
	return info


## What every slot holds, in order.
func list() -> Array[SaveSlotInfo]:
	var infos: Array[SaveSlotInfo] = []
	for slot: int in SLOT_COUNT:
		infos.append(read_info(slot))
	return infos


## Empties `slot`.
func delete(slot: int) -> void:
	if _is_valid_slot(slot) and FileAccess.file_exists(get_slot_path(slot)):
		DirAccess.remove_absolute(get_slot_path(slot))


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT


func _unreadable(info: SaveSlotInfo, reason: String) -> SaveSlotInfo:
	push_warning("SaveSlots: can't read %s: %s." % [get_slot_path(info.slot), reason])
	info.status = SaveSlotInfo.Status.UNREADABLE
	return info
