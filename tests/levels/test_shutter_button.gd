## Tests for the ShutterButton: before the power it does nothing but keeps
## its prompt; with the power it raises the shutter and stops being an
## interactable, also when a save has the shutter up.

extends GutTest

const SHUTTER_SCENE: PackedScene = preload("res://scenes/levels/roller_shutter.tscn")

var _flag: LevelFlag
var _shutter: RollerShutter


func before_each() -> void:
	SaveSystem.reset()
	_flag = LevelFlag.new()
	_flag.flag_id = &"power_restored"
	add_child_autofree(_flag)
	_shutter = SHUTTER_SCENE.instantiate() as RollerShutter
	_shutter.shutter_id = &"shutter_test"
	_shutter.raise_time = 0.2
	add_child_autofree(_shutter)


func after_each() -> void:
	SaveSystem.reset()


func _make_button() -> ShutterButton:
	var button := ShutterButton.new()
	button.power_flag = _flag
	button.shutter = _shutter
	add_child_autofree(button)
	return button


func test_is_an_interactable_with_its_prompt() -> void:
	var button := _make_button()
	assert_true(button.is_in_group(Interactable.GROUP))
	assert_eq(button.get_prompt(), ShutterButton.PROMPT)
	assert_false(button.is_powered())


func test_before_the_power_nothing_happens() -> void:
	var button := _make_button()
	assert_eq(button.interact(null), "Nothing happens.")
	assert_false(_shutter.is_up)
	assert_false(SaveSystem.world.has_state(&"shutter_test"))


func test_before_the_power_it_keeps_its_prompt() -> void:
	var button := _make_button()
	button.interact(null)
	button.interact(null)
	assert_true(button.is_in_group(Interactable.GROUP))
	assert_eq(button.get_prompt(), ShutterButton.PROMPT)


func test_after_the_power_it_raises_the_shutter() -> void:
	var button := _make_button()
	_flag.set_flag()
	assert_true(button.is_powered())
	assert_eq(button.interact(null), "")
	assert_true(_shutter.is_up)
	assert_false(button.is_in_group(Interactable.GROUP), "no prompt once it's going up")


func test_a_loaded_power_powers_it() -> void:
	var button := _make_button()
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.apply(_flag)
	assert_true(button.is_powered())
	assert_true(button.is_in_group(Interactable.GROUP), "the shutter is still down")


func test_a_loaded_shutter_up_takes_its_prompt_away() -> void:
	var button := _make_button()
	SaveSystem.world.record(&"shutter_test", {"is_up": true})
	SaveSystem.world.apply(_shutter)
	assert_false(button.is_in_group(Interactable.GROUP))


func test_a_shutter_already_up_takes_its_prompt_away() -> void:
	_shutter.raise()
	var button := _make_button()
	assert_false(button.is_in_group(Interactable.GROUP))
