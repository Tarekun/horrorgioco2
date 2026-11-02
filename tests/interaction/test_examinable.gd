## Tests for examinable objects: lines in turn, starting over, and the hint.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _examinable: Examinable


func before_each() -> void:
	_examinable = Examinable.new()
	_examinable.lines = PackedStringArray(["No signal.", "Battery low."])
	add_child_autofree(_examinable)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_it_is_an_interactable_to_examine() -> void:
	assert_true(_examinable.is_in_group(Interactable.GROUP))
	assert_eq(_examinable.get_prompt(), "Examine")


func test_each_interaction_shows_the_next_line() -> void:
	watch_signals(_examinable)
	assert_eq(_examinable.interact(null), "No signal.")
	assert_eq(_examinable.interact(null), "Battery low.")
	assert_signal_emit_count(_examinable, "examined", 2)
	assert_signal_emitted_with_parameters(_examinable, "examined", ["Battery low."])


func test_after_the_last_line_it_starts_over() -> void:
	_examinable.interact(null)
	assert_false(_examinable.is_at_start())
	_examinable.interact(null)
	assert_true(_examinable.is_at_start())
	assert_eq(_examinable.interact(null), "No signal.")


func test_an_unfinished_description_starts_over_after_a_while() -> void:
	_examinable.restart_after = 0.05
	_examinable.interact(null)
	# It measures real time.
	OS.delay_msec(100)
	assert_eq(_examinable.interact(null), "No signal.")


func test_a_quick_second_look_goes_on() -> void:
	_examinable.restart_after = 5.0
	_examinable.interact(null)
	assert_eq(_examinable.interact(null), "Battery low.")


func test_with_no_lines_it_says_nothing() -> void:
	var empty := Examinable.new()
	add_child_autofree(empty)
	assert_eq(empty.interact(null), "")


func test_the_player_reads_it_on_the_hint() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	# In front of the player (who faces -Z).
	_examinable.position = Vector3(0, 0, -1.0)
	await get_tree().physics_frame
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, _examinable)
	assert_eq(interaction.hint.prompt_label.text, "Examine")
	interaction.interact()
	assert_eq(interaction.hint.message_label.text, "No signal.")
	interaction.interact()
	assert_eq(interaction.hint.message_label.text, "Battery low.")
	assert_true(interaction.hint.message_label.visible)


func test_restart_goes_back_to_the_first_line() -> void:
	_examinable.interact(null)
	_examinable.restart()
	assert_true(_examinable.is_at_start())
	assert_eq(_examinable.interact(null), "No signal.")


func test_fewer_lines_mid_description_start_over() -> void:
	_examinable.interact(null)
	_examinable.lines = PackedStringArray(["Only one."])
	assert_eq(_examinable.interact(null), "Only one.")
