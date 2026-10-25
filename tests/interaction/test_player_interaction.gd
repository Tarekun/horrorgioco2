## Tests for the player's interaction: range, facing, prompt and messages.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")

var _player: Player
var _interaction: PlayerInteraction
var _door: Door


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_interaction = _player.get_node("PlayerInteraction") as PlayerInteraction
	_door = DOOR_SCENE.instantiate() as Door
	# In front of the player (who faces -Z).
	_door.position = Vector3(0, 0, -1.2)
	add_child_autofree(_door)
	await get_tree().physics_frame
	await get_tree().physics_frame


func after_each() -> void:
	Input.action_release(&"interact")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_picks_an_interactable_in_range_and_in_front() -> void:
	_interaction.update_focus()
	assert_eq(_interaction.focus, _door)


func test_the_prompt_shows_only_while_in_range() -> void:
	_interaction.update_focus()
	assert_true(_interaction.hint.prompt_label.visible)
	assert_eq(_interaction.hint.prompt_label.text, "Open")
	_door.position = Vector3(0, 0, -4)
	_interaction.update_focus()
	assert_null(_interaction.focus)
	assert_false(_interaction.hint.prompt_label.visible)


func test_one_behind_the_player_is_ignored() -> void:
	_door.position = Vector3(0, 0, 1.2)
	_interaction.update_focus()
	assert_null(_interaction.focus)


func test_interact_opens_the_door() -> void:
	_interaction.update_focus()
	assert_true(_interaction.interact())
	assert_true(_door.is_open)
	_interaction.update_focus()
	assert_eq(_interaction.hint.prompt_label.text, "Close")


func test_interact_with_nothing_in_range_does_nothing() -> void:
	_door.position = Vector3(0, 0, -6)
	_interaction.update_focus()
	assert_false(_interaction.interact())


func test_a_locked_door_message_is_shown_and_expires() -> void:
	_door.is_locked = true
	_interaction.update_focus()
	_interaction.interact()
	assert_false(_door.is_open)
	assert_true(_interaction.hint.message_label.visible)
	assert_eq(_interaction.hint.message_label.text, "It's locked.")
	_interaction.hint.tick(3.0)
	assert_false(_interaction.hint.message_label.visible)


func test_the_interact_action_uses_the_door() -> void:
	Input.action_press(&"interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(_door.is_open)


func test_nothing_can_be_used_while_dead() -> void:
	_player.health_component.take_damage(500.0)
	_interaction.update_focus()
	assert_null(_interaction.focus)
	assert_false(_interaction.interact())


func test_focus_changed_is_emitted() -> void:
	_interaction.update_focus()
	watch_signals(_interaction)
	_door.position = Vector3(0, 0, -6)
	_interaction.update_focus()
	assert_signal_emitted(_interaction, "focus_changed")
