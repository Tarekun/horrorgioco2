## Tests for equipping weapons from the inventory, on a player given the plank
## to start with (the player scene itself starts unarmed).

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const PLANK: ItemData = preload("res://assets/data/items/wooden_plank.tres")
const PIPE: ItemData = preload("res://assets/data/items/steel_pipe.tres")
const AXE: ItemData = preload("res://assets/data/items/fire_axe.tres")

var _player: Player
var _items: PlayerItems
var _combat: PlayerCombat
var _screen: InventoryScreen


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	_items = _player.get_node("PlayerItems") as PlayerItems
	_items.starting_weapon = PLANK
	add_child_autofree(_player)
	_combat = _player.get_node("PlayerCombat") as PlayerCombat
	_screen = _player.get_node("InventoryScreen") as InventoryScreen
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_the_weapons_are_items() -> void:
	for item: ItemData in [PLANK, PIPE, AXE]:
		assert_eq(item.category, ItemData.Category.WEAPON, item.id)
		assert_true(item.is_equippable(), item.id)
		assert_not_null(item.weapon, item.id)
		assert_eq(item.weapon.display_name, item.display_name)


func test_the_player_starts_holding_the_starting_weapon_from_the_inventory() -> void:
	assert_eq(_player.inventory.count(PLANK), 1)
	assert_eq(_items.equipped_weapon, PLANK)
	assert_eq(_combat.weapon, PLANK.weapon)


func test_equipping_swaps_the_weapon() -> void:
	_player.inventory.add(PIPE)
	watch_signals(_items)
	assert_true(_items.equip(PIPE))
	assert_eq(_items.equipped_weapon, PIPE)
	assert_eq(_combat.weapon, PIPE.weapon)
	assert_signal_emitted_with_parameters(_items, "weapon_equipped", [PIPE])


func test_the_plank_stays_in_the_inventory() -> void:
	_player.inventory.add(AXE)
	_items.equip(AXE)
	assert_true(_player.inventory.has(PLANK))
	assert_true(_player.inventory.has(AXE))
	_items.equip(PLANK)
	assert_eq(_combat.weapon, PLANK.weapon)


func test_a_weapon_not_held_cannot_be_equipped() -> void:
	assert_false(_items.equip(AXE))
	assert_eq(_combat.weapon, PLANK.weapon)


func test_equip_on_the_screen_swaps_the_weapon() -> void:
	_player.inventory.add(PIPE)
	_screen.open()
	_screen.select_tab(ItemData.Category.WEAPON)
	_screen.select_item(PIPE)
	_screen.equip_button.pressed.emit()
	assert_eq(_combat.weapon, PIPE.weapon)


func test_the_screen_marks_the_weapon_held() -> void:
	_player.inventory.add(PIPE)
	_screen.open()
	_screen.select_tab(ItemData.Category.WEAPON)
	assert_eq(_screen.item_list.get_item_text(0), "Wooden plank  (equipped)")
	assert_eq(_screen.item_list.get_item_text(1), "Steel pipe")
	_items.equip(PIPE)
	assert_eq(_screen.item_list.get_item_text(0), "Wooden plank")
	assert_eq(_screen.item_list.get_item_text(1), "Steel pipe  (equipped)")


func test_equip_is_off_for_the_weapon_held() -> void:
	_player.inventory.add(PIPE)
	_screen.open()
	_screen.select_tab(ItemData.Category.WEAPON)
	_screen.select_item(PLANK)
	assert_true(_screen.equip_button.disabled)
	_screen.select_item(PIPE)
	assert_false(_screen.equip_button.disabled)
