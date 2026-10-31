## Tests for the RollerShutter: down it blocks the way, raising it is loud,
## rolls it up and then opens the way; it records itself as up, and a loaded
## save puts it straight up in silence.

extends GutTest

const SHUTTER_SCENE: PackedScene = preload("res://scenes/levels/roller_shutter.tscn")
const NOISE_LISTENER: GDScript = preload("res://tests/combat/noise_listener.gd")

var _shutter: RollerShutter
var _heard: Array[float] = []


func before_each() -> void:
	SaveSystem.reset()
	_heard.clear()
	var listener := Node.new()
	listener.set_script(NOISE_LISTENER)
	listener.set(&"sink", _heard)
	listener.add_to_group(NoiseEvent.HEARING_GROUP)
	add_child_autofree(listener)
	_shutter = SHUTTER_SCENE.instantiate() as RollerShutter
	_shutter.shutter_id = &"shutter_test"
	_shutter.raise_time = 0.2
	add_child_autofree(_shutter)


func after_each() -> void:
	SaveSystem.reset()


func _wait_until_open() -> void:
	await wait_for_signal(_shutter.opened, _shutter.raise_time + 2.0)


func test_starts_down_and_blocks_the_way() -> void:
	assert_false(_shutter.is_up)
	assert_false(_shutter.is_open)
	assert_false(_shutter.collision_shape.disabled)
	assert_false(_shutter.navigation_link.enabled)
	assert_eq(_shutter.curtain.position.y, 0.0)
	assert_eq(_shutter.curtain.scale.y, 1.0)


func test_is_persistent_with_its_id() -> void:
	assert_true(_shutter.is_in_group(WorldState.GROUP))
	assert_eq(_shutter.get_persistent_id(), &"shutter_test")


func test_takes_about_three_seconds_to_raise() -> void:
	var shutter := SHUTTER_SCENE.instantiate() as RollerShutter
	assert_almost_eq(shutter.raise_time, 3.0, 0.5)
	shutter.free()


func test_raising_it_records_it_up() -> void:
	watch_signals(_shutter)
	_shutter.raise()
	assert_true(_shutter.is_up)
	assert_eq(SaveSystem.world.get_state(&"shutter_test"), {"is_up": true})
	assert_signal_emitted_with_parameters(_shutter, "raised", [false])


func test_raising_it_makes_a_twelve_metre_noise_once() -> void:
	assert_eq(_shutter.noise_radius, 12.0)
	_shutter.raise()
	assert_eq(_heard, [12.0] as Array[float])
	_shutter.raise()
	assert_eq(_heard.size(), 1, "raising it again does nothing")


func test_raising_it_plays_its_sound() -> void:
	_shutter.raise()
	assert_true(_shutter.raise_sound.playing)


func test_the_way_stays_shut_while_it_rolls_up() -> void:
	_shutter.raise_time = 1.0
	_shutter.raise()
	await wait_seconds(0.4)
	assert_false(_shutter.is_open)
	assert_false(_shutter.collision_shape.disabled)
	assert_false(_shutter.navigation_link.enabled)
	assert_gt(_shutter.curtain.position.y, 0.0, "the curtain is going up")


func test_once_up_the_way_is_open() -> void:
	_shutter.raise()
	await _wait_until_open()
	assert_true(_shutter.is_open)
	assert_true(_shutter.collision_shape.disabled)
	assert_true(_shutter.navigation_link.enabled)
	assert_almost_eq(_shutter.curtain.scale.y, _shutter.rolled_fraction, 0.001)
	assert_gt(_shutter.curtain.position.y, 2.0, "its bottom edge is above the player's head")


func test_a_loaded_save_puts_it_straight_up_in_silence() -> void:
	watch_signals(_shutter)
	SaveSystem.world.record(&"shutter_test", {"is_up": true})
	SaveSystem.world.apply(_shutter)
	assert_true(_shutter.is_up)
	assert_true(_shutter.is_open)
	assert_true(_shutter.collision_shape.disabled)
	assert_true(_shutter.navigation_link.enabled)
	assert_almost_eq(_shutter.curtain.scale.y, _shutter.rolled_fraction, 0.001)
	assert_eq(_heard.size(), 0, "no noise")
	assert_false(_shutter.raise_sound.playing, "no sound")
	assert_signal_emitted_with_parameters(_shutter, "raised", [true])


func test_a_save_with_it_down_leaves_it_down() -> void:
	SaveSystem.world.record(&"shutter_test", {"is_up": false})
	SaveSystem.world.apply(_shutter)
	assert_false(_shutter.is_up)
	assert_false(_shutter.collision_shape.disabled)
