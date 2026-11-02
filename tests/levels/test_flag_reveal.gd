## Tests for FlagReveal: a node hidden until a level flag is set.

extends GutTest

var _flag: LevelFlag
var _target: Node3D
var _reveal: FlagReveal


func before_each() -> void:
	_flag = LevelFlag.new()
	_flag.flag_id = &"test_flag"
	add_child_autofree(_flag)
	_target = Node3D.new()
	add_child_autofree(_target)
	_reveal = FlagReveal.new()
	_reveal.flag = _flag
	_reveal.target = _target


func after_each() -> void:
	SaveSystem.reset()


func test_hides_the_target_until_the_flag_is_set() -> void:
	add_child_autofree(_reveal)
	assert_false(_target.visible)
	_flag.set_flag()
	assert_true(_target.visible)


func test_a_loaded_flag_shows_the_target() -> void:
	add_child_autofree(_reveal)
	_flag.load_state({"is_set": true})
	assert_true(_target.visible)


func test_a_flag_set_before_it_enters_shows_the_target_at_once() -> void:
	_flag.set_flag()
	add_child_autofree(_reveal)
	assert_true(_target.visible)
