## Tests for examinables whose description changes with the world: by a level
## flag or a door's lock, and shown only before or after the change.

extends GutTest

const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")

var _flag: LevelFlag
var _examinable: StateExaminable


func before_each() -> void:
	SaveSystem.reset()
	_flag = LevelFlag.new()
	_flag.flag_id = &"power_restored"
	add_child_autofree(_flag)
	_examinable = _make(_flag)


func after_each() -> void:
	SaveSystem.reset()


func _make(
	flag: LevelFlag, shown: StateExaminable.Shown = StateExaminable.Shown.ALWAYS
) -> StateExaminable:
	var examinable := StateExaminable.new()
	examinable.flag = flag
	examinable.shown = shown
	examinable.lines = PackedStringArray(["Out of order.", "The indicator says 3."])
	examinable.lines_after = PackedStringArray(["It works.", "The indicator shows where it is."])
	add_child_autofree(examinable)
	return examinable


func test_before_the_change_it_reads_its_lines() -> void:
	assert_false(_examinable.is_changed())
	assert_eq(_examinable.interact(null), "Out of order.")
	assert_eq(_examinable.interact(null), "The indicator says 3.")


func test_after_the_flag_it_reads_the_lines_after() -> void:
	_flag.set_flag()
	assert_true(_examinable.is_changed())
	assert_eq(_examinable.interact(null), "It works.")
	assert_eq(_examinable.interact(null), "The indicator shows where it is.")


func test_the_first_look_after_the_change_starts_from_the_top() -> void:
	_examinable.interact(null)
	_flag.set_flag()
	assert_eq(_examinable.interact(null), "It works.")


func test_a_loaded_flag_changes_it_too() -> void:
	_flag.load_state({"is_set": true})
	assert_eq(_examinable.interact(null), "It works.")


func test_without_lines_after_it_keeps_its_lines() -> void:
	_examinable.lines_after = PackedStringArray()
	_flag.set_flag()
	assert_eq(_examinable.interact(null), "Out of order.")


func test_shown_after_is_only_examinable_once_the_flag_is_set() -> void:
	var desk: StateExaminable = _make(_flag, StateExaminable.Shown.AFTER)
	assert_false(desk.is_in_group(Interactable.GROUP))
	_flag.set_flag()
	assert_true(desk.is_in_group(Interactable.GROUP))


func test_shown_before_stops_being_examinable_once_the_flag_is_set() -> void:
	var shutter: StateExaminable = _make(_flag, StateExaminable.Shown.BEFORE)
	assert_true(shutter.is_in_group(Interactable.GROUP))
	_flag.load_state({"is_set": true})
	assert_false(shutter.is_in_group(Interactable.GROUP))


func test_a_flag_already_set_is_read_on_entering_the_tree() -> void:
	_flag.set_flag()
	var desk: StateExaminable = _make(_flag, StateExaminable.Shown.AFTER)
	assert_true(desk.is_in_group(Interactable.GROUP))
	assert_eq(desk.interact(null), "It works.")


func test_a_door_changes_it_once_unlocked() -> void:
	var door := DOOR_SCENE.instantiate() as Door
	door.is_locked = true
	add_child_autofree(door)
	var chain := StateExaminable.new()
	chain.door = door
	chain.lines = PackedStringArray(["Chained shut."])
	chain.lines_after = PackedStringArray(["The chain is on the floor."])
	add_child_autofree(chain)
	assert_eq(chain.interact(null), "Chained shut.")
	door.unlock()
	assert_true(chain.is_changed())
	assert_eq(chain.interact(null), "The chain is on the floor.")
