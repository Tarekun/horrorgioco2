## Tests for ShowerTap: usable only while the shower runs.

extends GutTest

var _tap: ShowerTap


func before_each() -> void:
	_tap = ShowerTap.new()
	add_child_autofree(_tap)


func test_it_cannot_be_used_until_the_shower_runs() -> void:
	assert_false(_tap.is_in_group(Interactable.GROUP))
	watch_signals(_tap)
	assert_eq(_tap.interact(null), "")
	assert_signal_not_emitted(_tap, "turned_off")


func test_turning_it_off_stops_the_shower() -> void:
	_tap.turn_on()
	assert_true(_tap.is_in_group(Interactable.GROUP))
	assert_eq(_tap.get_prompt(), "Turn off")
	watch_signals(_tap)
	_tap.interact(null)
	assert_signal_emit_count(_tap, "turned_off", 1)
	assert_false(_tap.is_running)
	assert_false(_tap.is_in_group(Interactable.GROUP))
	_tap.interact(null)
	assert_signal_emit_count(_tap, "turned_off", 1, "only once")
