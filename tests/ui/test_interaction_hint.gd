## Tests for the interaction hint's prompt and messages.

extends GutTest

const HINT_SCENE: PackedScene = preload("res://scenes/ui/interaction_hint.tscn")

var _hint: InteractionHint


func before_each() -> void:
	_hint = HINT_SCENE.instantiate() as InteractionHint
	add_child_autofree(_hint)


func test_starts_hidden() -> void:
	assert_false(_hint.prompt_label.visible)
	assert_false(_hint.message_label.visible)


func test_a_short_message_fades_after_the_set_time() -> void:
	_hint.show_message("It's locked.")
	assert_true(_hint.message_label.visible)
	_hint.tick(_hint.message_duration - 0.1)
	assert_true(_hint.message_label.visible)
	_hint.tick(0.2)
	assert_false(_hint.message_label.visible)


func test_a_long_message_stays_long_enough_to_read() -> void:
	var text: String = "Five cities, five times on the clock wall, and none of them is right."
	var duration: float = _hint.get_duration(text)
	assert_almost_eq(duration, text.length() * _hint.seconds_per_character, 0.001)
	assert_gt(duration, _hint.message_duration)
	_hint.show_message(text)
	_hint.tick(duration - 0.1)
	assert_true(_hint.message_label.visible)
	_hint.tick(0.2)
	assert_false(_hint.message_label.visible)


func test_a_new_message_replaces_the_old_one() -> void:
	_hint.show_message("No signal.")
	_hint.tick(1.5)
	_hint.show_message("Battery low.")
	_hint.tick(1.0)
	assert_true(_hint.message_label.visible)
	assert_eq(_hint.message_label.text, "Battery low.")
