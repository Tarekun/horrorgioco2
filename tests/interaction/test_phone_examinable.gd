## Tests for the phone: its battery line, a little lower each time it is read.

extends GutTest

var _phone: PhoneExaminable


func before_each() -> void:
	_phone = PhoneExaminable.new()
	_phone.lines = PackedStringArray(["No signal.", "Battery {battery}%."])
	_phone.battery = 3
	add_child_autofree(_phone)


func test_it_shows_the_battery_then_drains_it() -> void:
	assert_eq(_phone.interact(null), "No signal.")
	assert_eq(_phone.interact(null), "Battery 3%.")
	assert_eq(_phone.battery, 2)


func test_each_look_is_a_little_lower_and_never_dies() -> void:
	var shown: Array[String] = []
	for i: int in 4:
		_phone.interact(null)
		shown.append(_phone.interact(null))
	assert_eq(shown, ["Battery 3%.", "Battery 2%.", "Battery 1%.", "Battery 1%."] as Array[String])


func test_lines_without_the_battery_leave_it_alone() -> void:
	_phone.interact(null)
	assert_eq(_phone.battery, 3)


func test_the_line_it_emits_has_the_battery_filled_in() -> void:
	watch_signals(_phone)
	_phone.interact(null)
	_phone.interact(null)
	assert_signal_emitted_with_parameters(_phone, "examined", ["Battery 3%."])
