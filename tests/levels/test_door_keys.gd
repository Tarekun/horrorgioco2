## Tests for locked doors that open with a key item.

extends GutTest

const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _door: Door


func before_each() -> void:
	_door = DOOR_SCENE.instantiate() as Door
	_door.swing_time = 0.1
	add_child_autofree(_door)
	await get_tree().process_frame


func after_each() -> void:
	SaveSystem.reset()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## A player at +Z of the door carrying the key item `id`, if any.
func _player_with_key(id: StringName) -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.position = Vector3(0, 0, 3)
	add_child_autofree(player)
	if not id.is_empty():
		var key := ItemData.new()
		key.id = id
		key.display_name = "Stairs key"
		key.category = ItemData.Category.KEY_ITEM
		player.inventory.add(key)
	return player


func test_the_right_key_unlocks_and_opens_it() -> void:
	SaveSystem.reset()
	_door.is_locked = true
	_door.key_id = &"key_stairs"
	watch_signals(_door)
	var player: Player = _player_with_key(&"key_stairs")
	assert_eq(_door.interact(player), "Used Stairs key.")
	assert_false(_door.is_locked)
	assert_true(_door.is_open)
	assert_signal_emitted(_door, "unlocked_with_key")
	assert_signal_not_emitted(_door, "locked_attempted")
	assert_eq(SaveSystem.world.get_state(_door.door_id), {"is_locked": false})


func test_the_key_is_kept() -> void:
	_door.is_locked = true
	_door.key_id = &"key_stairs"
	var player: Player = _player_with_key(&"key_stairs")
	_door.interact(player)
	assert_eq(player.inventory.get_items()[-1].id, &"key_stairs")


func test_once_unlocked_it_opens_without_a_message() -> void:
	_door.is_locked = true
	_door.key_id = &"key_stairs"
	var player: Player = _player_with_key(&"key_stairs")
	_door.interact(player)
	_door.interact(player)
	assert_false(_door.is_open)
	assert_eq(_door.interact(player), "")
	assert_true(_door.is_open)


func test_without_the_key_it_stays_locked() -> void:
	_door.is_locked = true
	_door.key_id = &"key_stairs"
	_door.locked_message = "Chained shut."
	for player: Player in [_player_with_key(&""), _player_with_key(&"key_room_16")]:
		assert_eq(_door.interact(player), "Chained shut.")
		assert_true(_door.is_locked)
		assert_false(_door.is_open)


func test_no_key_opens_a_door_without_a_key_id() -> void:
	_door.is_locked = true
	var player: Player = _player_with_key(&"key_stairs")
	assert_eq(_door.interact(player), "It's locked.")
	assert_true(_door.is_locked)
