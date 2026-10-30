## Tests for the save slots on disk: writing, reading, overwriting, and files
## that can't be loaded.

extends GutTest

const DIRECTORY: String = "user://test_save_slots"

var _slots: SaveSlots


func before_each() -> void:
	_slots = SaveSlots.new(DIRECTORY)
	_clear()


func after_each() -> void:
	_clear()
	DirAccess.remove_absolute(DIRECTORY)


func _clear() -> void:
	for slot: int in SaveSlots.SLOT_COUNT:
		_slots.delete(slot)


func _make_save(area_name: String, play_time: float = 125.0) -> SaveData:
	var save := SaveData.new()
	save.level_path = "res://scenes/levels/graybox_level.tscn"
	save.area_name = area_name
	save.play_time = play_time
	save.timestamp = 1_793_000_000
	save.player_health = 80.0
	save.inventory = {"wooden_plank": 1, "pistol_ammo": 8}
	save.world.record(&"Pickups/Ammo", {"is_collected": true})
	return save


func _write_raw(slot: int, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file := FileAccess.open(_slots.get_slot_path(slot), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_there_are_eight_slots_in_their_own_files() -> void:
	assert_eq(SaveSlots.SLOT_COUNT, 8)
	var paths: Array[String] = []
	for slot: int in SaveSlots.SLOT_COUNT:
		var path: String = _slots.get_slot_path(slot)
		assert_true(path.begins_with(DIRECTORY + "/"), path)
		assert_false(paths.has(path), path)
		paths.append(path)


func test_the_game_keeps_saves_in_user_saves() -> void:
	assert_eq(SaveSlots.new().directory, "user://saves")


func test_tests_never_use_the_players_saves() -> void:
	assert_eq(SaveSystem.slots.directory, SaveSystem.HEADLESS_DIRECTORY)


func test_slots_start_empty() -> void:
	var infos: Array[SaveSlotInfo] = _slots.list()
	assert_eq(infos.size(), 8)
	for info: SaveSlotInfo in infos:
		assert_eq(info.status, SaveSlotInfo.Status.EMPTY)
		assert_false(info.is_occupied())
		assert_false(info.is_loadable())
		assert_eq(info.describe(), "Empty")
	assert_null(_slots.read(0))


func test_writes_and_reads_a_save() -> void:
	assert_eq(_slots.write(2, _make_save("Lobby")), OK)
	var save: SaveData = _slots.read(2)
	assert_not_null(save)
	assert_eq(save.area_name, "Lobby")
	assert_eq(save.player_health, 80.0)
	assert_eq(save.inventory.keys(), ["wooden_plank", "pistol_ammo"])
	assert_eq(save.world.get_state(&"Pickups/Ammo"), {"is_collected": true})
	assert_eq(_slots.read_info(1).status, SaveSlotInfo.Status.EMPTY)


func test_the_slot_shows_area_play_time_and_timestamp() -> void:
	_slots.write(0, _make_save("Lobby", 3725.0))
	var info: SaveSlotInfo = _slots.read_info(0)
	assert_eq(info.slot, 0)
	assert_eq(info.status, SaveSlotInfo.Status.OK)
	assert_true(info.is_loadable())
	assert_eq(info.save.play_time, 3725.0)
	assert_eq(info.save.timestamp, 1_793_000_000)
	var line: String = info.describe()
	assert_string_contains(line, "Lobby")
	assert_string_contains(line, "1:02:05")
	assert_string_contains(line, SaveSlotInfo.format_timestamp(1_793_000_000))


func test_overwriting_replaces_the_save() -> void:
	_slots.write(4, _make_save("Lobby"))
	_slots.write(4, _make_save("Office", 900.0))
	var save: SaveData = _slots.read(4)
	assert_eq(save.area_name, "Office")
	assert_eq(save.play_time, 900.0)
	assert_false(FileAccess.file_exists(_slots.get_slot_path(4) + ".tmp"))


func test_the_file_records_the_format_version() -> void:
	_slots.write(0, _make_save("Lobby"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_slots.get_slot_path(0)))
	assert_eq(int(data["version"]), SaveSlots.FORMAT_VERSION)


func test_a_corrupt_file_is_reported_not_loaded() -> void:
	_write_raw(1, '{"version": 1, "save": {"level_pa')
	var info: SaveSlotInfo = _slots.read_info(1)
	assert_eq(info.status, SaveSlotInfo.Status.UNREADABLE)
	assert_true(info.is_occupied())
	assert_false(info.is_loadable())
	assert_null(_slots.read(1))
	assert_eq(info.describe(), "Unreadable save")


func test_json_that_isnt_a_save_is_unreadable() -> void:
	for text: String in [
		"[1, 2, 3]", '{"save": {}}', '{"version": 1}', '{"version": 1, "save": {}}'
	]:
		_write_raw(3, text)
		assert_eq(_slots.read_info(3).status, SaveSlotInfo.Status.UNREADABLE, text)


func test_an_old_save_is_reported_not_loaded() -> void:
	var data: Dictionary = {"version": SaveSlots.FORMAT_VERSION - 1, "save": {}}
	_write_raw(5, JSON.stringify(data))
	var info: SaveSlotInfo = _slots.read_info(5)
	assert_eq(info.status, SaveSlotInfo.Status.WRONG_VERSION)
	assert_false(info.is_loadable())
	assert_eq(info.describe(), "Save from another version of the game")


func test_a_corrupt_slot_can_be_saved_over() -> void:
	_write_raw(6, "garbage")
	assert_eq(_slots.write(6, _make_save("Lobby")), OK)
	assert_true(_slots.read_info(6).is_loadable())


func test_slots_out_of_range_are_refused() -> void:
	assert_eq(_slots.write(8, _make_save("Lobby")), ERR_PARAMETER_RANGE_ERROR)
	assert_eq(_slots.write(-1, _make_save("Lobby")), ERR_PARAMETER_RANGE_ERROR)
	assert_eq(_slots.read_info(8).status, SaveSlotInfo.Status.EMPTY)


func test_delete_empties_a_slot() -> void:
	_slots.write(7, _make_save("Lobby"))
	_slots.delete(7)
	assert_eq(_slots.read_info(7).status, SaveSlotInfo.Status.EMPTY)


func test_play_time_reads_as_hours_minutes_seconds() -> void:
	assert_eq(SaveSlotInfo.format_play_time(0.0), "0:00:00")
	assert_eq(SaveSlotInfo.format_play_time(65.9), "0:01:05")
	assert_eq(SaveSlotInfo.format_play_time(3725.0), "1:02:05")
	assert_eq(SaveSlotInfo.format_play_time(-3.0), "0:00:00")


func test_timestamps_read_as_date_and_time() -> void:
	assert_eq(SaveSlotInfo.format_timestamp(0), "")
	var regex := RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}$")
	assert_not_null(regex.search(SaveSlotInfo.format_timestamp(1_793_000_000)))
