extends GutTest

const ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_back",
	&"move_left",
	&"move_right",
	&"look_up",
	&"look_down",
	&"look_left",
	&"look_right",
	&"sprint",
	&"attack",
	&"dodge",
	&"interact",
	&"flashlight",
	&"pause",
	&"inventory",
	&"aim",
	&"next_target",
]


func test_actions_are_defined() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_actions_have_keyboard_or_mouse_binding() -> void:
	for action in ACTIONS:
		var events := InputMap.action_get_events(action)
		var bound := events.any(
			func(e: InputEvent) -> bool: return e is InputEventKey or e is InputEventMouseButton
		)
		assert_true(bound, "%s has no keyboard/mouse binding" % action)


func test_actions_have_gamepad_binding() -> void:
	for action in ACTIONS:
		var events := InputMap.action_get_events(action)
		var bound := events.any(
			func(e: InputEvent) -> bool:
				return e is InputEventJoypadButton or e is InputEventJoypadMotion
		)
		assert_true(bound, "%s has no gamepad binding" % action)


func test_inventory_opens_with_i_and_back() -> void:
	var events := InputMap.action_get_events(&"inventory")
	var has_i := events.any(
		func(e: InputEvent) -> bool:
			return e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_I
	)
	var has_back := events.any(
		func(e: InputEvent) -> bool:
			return (
				e is InputEventJoypadButton
				and (e as InputEventJoypadButton).button_index == JOY_BUTTON_BACK
			)
	)
	assert_true(has_i, "inventory is not on I")
	assert_true(has_back, "inventory is not on Back")
