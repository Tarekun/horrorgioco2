## Tests for the slice's puzzle chain in the hotel (slice.md, "The puzzle: the
## key cabinet"): the porter's log puts the clock back on room 22's nightstand,
## the clock reads the cabinet's code, and the cabinet's key opens the
## basement.

extends "res://tests/levels/hotel_level_test.gd"


func after_each() -> void:
	get_tree().paused = false
	SaveSystem.reset()
	super.after_each()


func _clock() -> Node3D:
	return _level.get_node("Props/SecondFloor/ClockRoom22") as Node3D


func _flag() -> LevelFlag:
	return _level.get_node("LevelFlags/PorterLogRead") as LevelFlag


func _cabinet() -> CombinationLockPuzzle:
	return _level.get_node("Puzzles/PuzzleKeyCabinet") as CombinationLockPuzzle


func _player() -> Player:
	return _level.get_node("Player") as Player


func test_the_clock_is_missing_when_luca_wakes() -> void:
	assert_false(_clock().visible)
	assert_false(_flag().is_set)


func test_reading_the_porter_log_brings_the_clock_back() -> void:
	var porter_log := _level.get_node("Documents/DocPorterLog") as DocumentPickup
	porter_log.interact(_player())
	assert_true(_flag().is_set)
	assert_true(_clock().visible)
	assert_true(_player().document_log.is_read(porter_log.item))


func test_the_other_documents_leave_the_clock_alone() -> void:
	for node_name: String in ["DocRegistrationCard", "DocLostProperty", "DocPostcard"]:
		var document := _level.get_node("Documents/" + node_name) as DocumentPickup
		document.interact(_player())
		(_player().get_node("DocumentReader") as DocumentReader).close()
	assert_false(_flag().is_set)
	assert_false(_clock().visible)


func test_a_loaded_save_has_the_clock_back() -> void:
	SaveSystem.world.record(&"doc_porter_log_read", {"is_set": true})
	SaveSystem.world.apply(_level)
	assert_true(_clock().visible)


func test_the_porter_log_ends_with_the_clue() -> void:
	var porter_log := _level.get_node("Documents/DocPorterLog") as DocumentPickup
	var last_page: String = porter_log.item.pages[porter_log.item.pages.size() - 1]
	assert_string_contains(last_page, "key cabinet")
	assert_string_contains(last_page, "twenty-two")


func test_the_clock_reads_the_cabinet_code() -> void:
	var code: String = _cabinet().code
	var time: String = "%s:%s" % [code.substr(0, 2), code.substr(2, 2)]
	var nightstand := _level.get_node("Examinables/SecondFloor/NightstandRoom22") as StateExaminable
	assert_string_contains(" ".join(nightstand.lines_after), time)


func test_the_cabinet_key_opens_the_basement() -> void:
	var player: Player = _player()
	_cabinet().solve(player)
	var door: Door = _door(&"door_basement")
	assert_true(door.is_locked)
	assert_not_null(Door.find_key(player.inventory, door.key_id))
	assert_true(_cabinet().is_solved)
