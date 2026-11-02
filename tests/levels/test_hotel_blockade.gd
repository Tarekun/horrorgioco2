## Tests for the blockade across room 28's doorway, Luca's first weapon, against
## the Blockade section of docs/design/slice.md.

extends "res://tests/levels/hotel_level_test.gd"

const PLANK: ItemData = preload("res://assets/data/items/wooden_plank.tres")
const BLOCKADE_PATH: NodePath = ^"Pickups/BlockadeRoom28"


func before_each() -> void:
	SaveSystem.reset()
	await super.before_each()


func after_each() -> void:
	super.after_each()
	SaveSystem.reset()


func _player() -> Player:
	return _level.get_node("Player") as Player


func _blockade() -> Pickup:
	return _level.get_node(BLOCKADE_PATH) as Pickup


func test_a_new_game_starts_unarmed() -> void:
	var player: Player = _player()
	assert_null(player.items.equipped_weapon)
	assert_null(player.items.combat.weapon)
	assert_true(player.inventory.get_items_in(ItemData.Category.WEAPON).is_empty())


func test_the_prompt_reads_pull_the_plank_off() -> void:
	assert_eq(_blockade().get_prompt(), "Pull the plank off.")


func test_pulling_the_plank_off_equips_it() -> void:
	var player: Player = _player()
	_blockade().interact(player)
	assert_true(player.inventory.has(PLANK))
	assert_eq(player.items.equipped_weapon, PLANK)
	assert_eq(player.items.combat.weapon, PLANK.weapon)


func test_once_taken_the_plank_is_gone_after_loading() -> void:
	var blockade: Pickup = _blockade()
	blockade.interact(_player())
	assert_eq(SaveSystem.world.get_state(&"blockade_room_28"), {"is_collected": true})
	var world: WorldState = SaveSystem.world.copy()
	remove_child(_level)
	_level.queue_free()

	_level = LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(_level)
	assert_not_null(_blockade(), "a fresh level has the plank across the doorway")
	world.apply(_level)
	await get_tree().process_frame
	assert_null(_level.get_node_or_null(BLOCKADE_PATH), "the plank is gone")
	assert_false(_player().inventory.has(PLANK), "loading the world state gives nothing")
