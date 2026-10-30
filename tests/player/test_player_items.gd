## Tests for using items from the inventory screen: the healing items.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DRINK: ItemData = preload("res://assets/data/items/health_drink.tres")
const FIRST_AID: ItemData = preload("res://assets/data/items/first_aid_kit.tres")
const AMPOULE: ItemData = preload("res://assets/data/items/ampoule.tres")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")

var _player: Player
var _items: PlayerItems
var _health: HealthComponent
var _screen: InventoryScreen


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_items = _player.get_node("PlayerItems") as PlayerItems
	_health = _player.health_component
	_screen = _player.get_node("InventoryScreen") as InventoryScreen
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Sets health to `value` points.
func _set_health(value: float) -> void:
	_health.take_damage(_health.current_health - value)


func test_the_healing_items_are_defined() -> void:
	for item: ItemData in [DRINK, FIRST_AID, AMPOULE]:
		assert_eq(item.category, ItemData.Category.HEALING, item.id)
		assert_true(item.is_usable(), item.id)
		assert_eq(ItemCatalog.find(item.id), item)


func test_a_health_drink_heals_30() -> void:
	_set_health(40.0)
	_player.inventory.add(DRINK)
	assert_eq(_items.use_item(DRINK), "")
	assert_eq(_health.current_health, 70.0)


func test_a_first_aid_kit_heals_70() -> void:
	_set_health(20.0)
	_player.inventory.add(FIRST_AID)
	_items.use_item(FIRST_AID)
	assert_eq(_health.current_health, 90.0)


func test_an_ampoule_heals_fully() -> void:
	_set_health(5.0)
	_player.inventory.add(AMPOULE)
	_items.use_item(AMPOULE)
	assert_eq(_health.current_health, _health.max_health)


func test_healing_stops_at_max_health() -> void:
	_set_health(90.0)
	_player.inventory.add(FIRST_AID)
	_items.use_item(FIRST_AID)
	assert_eq(_health.current_health, 100.0)


func test_using_one_consumes_one() -> void:
	_set_health(10.0)
	_player.inventory.add(DRINK, 3)
	_items.use_item(DRINK)
	assert_eq(_player.inventory.count(DRINK), 2)


func test_cannot_be_used_at_full_health() -> void:
	_player.inventory.add(DRINK)
	assert_eq(_items.use_item(DRINK), PlayerItems.FULL_HEALTH_MESSAGE)
	assert_eq(_player.inventory.count(DRINK), 1)
	assert_eq(_health.current_health, 100.0)


func test_an_item_not_held_does_nothing() -> void:
	_set_health(40.0)
	assert_eq(_items.use_item(DRINK), "")
	assert_eq(_health.current_health, 40.0)


func test_ammo_cannot_be_used() -> void:
	_set_health(40.0)
	_player.inventory.add(ROUNDS, 8)
	_items.use_item(ROUNDS)
	assert_eq(_player.inventory.count(ROUNDS), 8)


func test_use_on_the_screen_heals_and_updates_the_status() -> void:
	_set_health(20.0)
	_player.inventory.add(FIRST_AID)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	assert_eq(_screen.status_label.text, "Danger")
	_screen.use_button.pressed.emit()
	assert_eq(_health.current_health, 90.0)
	assert_false(_player.inventory.has(FIRST_AID))
	assert_eq(_screen.status_label.text, "Fine")
	assert_eq(_screen.item_list.item_count, 0)


func test_the_screen_says_why_at_full_health() -> void:
	_player.inventory.add(DRINK)
	_player.inventory.add(AMPOULE)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.use_button.pressed.emit()
	assert_eq(_screen.message_label.text, PlayerItems.FULL_HEALTH_MESSAGE)
	assert_eq(_player.inventory.count(DRINK), 1)
	# Picking another item clears it.
	_screen.select_item(AMPOULE)
	assert_eq(_screen.message_label.text, "")
