## Tests for the player's part of a save.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")
const PIPE: ItemData = preload("res://assets/data/items/steel_pipe.tres")

var _player: Player


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	await get_tree().process_frame


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_the_items_node_is_wired() -> void:
	assert_eq(_player.items, _player.get_node("PlayerItems"))


func test_writes_health_inventory_weapon_and_flashlight() -> void:
	_player.health_component.take_damage(35.0)
	_player.inventory.add(ROUNDS, 16)
	_player.inventory.add(PIPE)
	_player.items.equip(PIPE)
	_player.flashlight.set_on(false)
	var save := SaveData.new()
	_player.write_save(save)
	assert_eq(save.player_health, 65.0)
	assert_eq(
		save.inventory,
		{"wooden_plank": 1, "pistol_ammo": 16, "steel_pipe": 1} as Dictionary[String, int]
	)
	assert_eq(save.equipped_weapon, &"steel_pipe")
	assert_false(save.is_flashlight_on)


func test_a_lit_flashlight_is_saved_on() -> void:
	_player.flashlight.set_on(true)
	var save := SaveData.new()
	save.is_flashlight_on = false
	_player.write_save(save)
	assert_true(save.is_flashlight_on)
