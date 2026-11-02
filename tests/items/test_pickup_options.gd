## Tests for a placed pickup's options: its own prompt, and equipping a weapon
## as soon as it is picked up (the plank off room 28's doorway).

extends GutTest

const PICKUP_SCENE: PackedScene = preload("res://scenes/items/pickup.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")
const PLANK: ItemData = preload("res://assets/data/items/wooden_plank.tres")

var _player: Player


func before_each() -> void:
	SaveSystem.reset()
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	await get_tree().process_frame


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _make_pickup(item: ItemData, equips: bool = false) -> Pickup:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = item
	pickup.equips_on_pickup = equips
	add_child_autofree(pickup)
	return pickup


func test_the_prompt_is_pick_up_unless_set() -> void:
	assert_eq(_make_pickup(ROUNDS).get_prompt(), "Pick up")


func test_a_placed_pickup_keeps_its_own_prompt() -> void:
	var blockade := PICKUP_SCENE.instantiate() as Pickup
	blockade.item = PLANK
	blockade.prompt = "Pull the plank off."
	add_child_autofree(blockade)
	assert_eq(blockade.get_prompt(), "Pull the plank off.")


func test_a_weapon_is_not_equipped_by_default() -> void:
	_make_pickup(PLANK).interact(_player)
	assert_true(_player.inventory.has(PLANK))
	assert_null(_player.items.equipped_weapon)


func test_equips_on_pickup_equips_the_weapon_at_once() -> void:
	_make_pickup(PLANK, true).interact(_player)
	assert_true(_player.inventory.has(PLANK))
	assert_eq(_player.items.equipped_weapon, PLANK)
	assert_eq(_player.items.combat.weapon, PLANK.weapon)


func test_equips_on_pickup_ignores_items_that_are_not_weapons() -> void:
	_make_pickup(ROUNDS, true).interact(_player)
	assert_eq(_player.inventory.count(ROUNDS), 8)
	assert_null(_player.items.equipped_weapon)
