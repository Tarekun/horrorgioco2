## Tests for LevelFlag: setting a flag live, recording it and loading it back.

extends GutTest

var _flag: LevelFlag


func before_each() -> void:
	SaveSystem.reset()
	_flag = _make_flag(&"power_restored")


func after_each() -> void:
	SaveSystem.reset()


func _make_flag(flag_id: StringName) -> LevelFlag:
	var flag := LevelFlag.new()
	flag.flag_id = flag_id
	add_child_autofree(flag)
	return flag


func test_starts_unset_and_persistent() -> void:
	assert_false(_flag.is_set)
	assert_true(_flag.is_in_group(WorldState.GROUP))
	assert_eq(_flag.get_persistent_id(), &"power_restored")


func test_without_an_id_it_uses_its_path() -> void:
	var flag := _make_flag(&"")
	assert_eq(flag.get_persistent_id(), WorldState.default_id(flag))


func test_setting_it_records_it_and_tells_it_was_live() -> void:
	watch_signals(_flag)
	_flag.set_flag()
	assert_true(_flag.is_set)
	assert_eq(SaveSystem.world.get_state(&"power_restored"), {"is_set": true})
	assert_signal_emitted_with_parameters(_flag, "flag_set", [false])


func test_setting_it_twice_tells_once() -> void:
	watch_signals(_flag)
	_flag.set_flag()
	_flag.set_flag()
	assert_signal_emit_count(_flag, "flag_set", 1)


func test_an_unset_flag_records_nothing() -> void:
	assert_false(SaveSystem.world.has_state(&"power_restored"))


func test_loading_it_sets_it_and_tells_it_was_loaded() -> void:
	watch_signals(_flag)
	_flag.load_state({"is_set": true})
	assert_true(_flag.is_set)
	assert_signal_emitted_with_parameters(_flag, "flag_set", [true])


func test_loading_a_bad_state_leaves_it_unset() -> void:
	watch_signals(_flag)
	for state: Dictionary in [{}, {"is_set": false}, {"is_set": "yes"}]:
		_flag.load_state(state)
	assert_false(_flag.is_set)
	assert_signal_not_emitted(_flag, "flag_set")


func test_loading_an_already_set_flag_tells_nothing() -> void:
	_flag.set_flag()
	watch_signals(_flag)
	_flag.load_state({"is_set": true})
	assert_signal_not_emitted(_flag, "flag_set")


func test_a_saved_flag_is_set_again_in_a_fresh_level() -> void:
	var level := Node.new()
	var flag := LevelFlag.new()
	flag.flag_id = &"power_restored"
	level.add_child(flag)
	var other := LevelFlag.new()
	other.flag_id = &"shutter_up"
	level.add_child(other)
	_flag.set_flag()
	var saved: WorldState = SaveSystem.world.copy()
	saved = _through_json(saved)
	add_child_autofree(level)
	watch_signals(flag)

	saved.apply(level)

	assert_true(flag.is_set)
	assert_false(other.is_set, "other flags stay as placed")
	assert_signal_emitted_with_parameters(flag, "flag_set", [true])


## `world` after a trip through the JSON a save file holds.
func _through_json(world: WorldState) -> WorldState:
	var loaded := WorldState.new()
	loaded.from_dict(JSON.parse_string(JSON.stringify(world.to_dict())) as Dictionary)
	return loaded
