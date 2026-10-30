## Tests for the inventory: stacking, removal, queries and signals.

extends GutTest

var _inventory: Inventory
var _rounds: ItemData
var _shells: ItemData
var _drink: ItemData


func before_each() -> void:
	_inventory = Inventory.new()
	_rounds = _make_item(&"rounds", ItemData.Category.AMMO)
	_shells = _make_item(&"shells", ItemData.Category.AMMO)
	_drink = _make_item(&"drink", ItemData.Category.HEALING)


func _make_item(id: StringName, category: ItemData.Category) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = String(id).capitalize()
	item.category = category
	return item


func test_starts_empty() -> void:
	assert_true(_inventory.is_empty())
	assert_eq(_inventory.count(_rounds), 0)
	assert_false(_inventory.has(_rounds))


func test_adding_stacks_without_limit() -> void:
	_inventory.add(_rounds, 8)
	_inventory.add(_rounds, 8)
	_inventory.add(_rounds, 9999)
	assert_eq(_inventory.count(_rounds), 10015)
	assert_eq(_inventory.get_items().size(), 1)


func test_add_defaults_to_one() -> void:
	_inventory.add(_drink)
	assert_eq(_inventory.count(_drink), 1)


func test_adding_nothing_is_ignored() -> void:
	watch_signals(_inventory)
	_inventory.add(_rounds, 0)
	_inventory.add(_rounds, -3)
	_inventory.add(null, 5)
	assert_true(_inventory.is_empty())
	assert_signal_not_emitted(_inventory, "changed")


func test_items_with_the_same_id_share_a_stack() -> void:
	_inventory.add(_rounds, 2)
	_inventory.add(_make_item(&"rounds", ItemData.Category.AMMO), 3)
	assert_eq(_inventory.count(_rounds), 5)


func test_has_checks_the_amount() -> void:
	_inventory.add(_rounds, 4)
	assert_true(_inventory.has(_rounds))
	assert_true(_inventory.has(_rounds, 4))
	assert_false(_inventory.has(_rounds, 5))


func test_removing_lowers_the_count() -> void:
	_inventory.add(_rounds, 8)
	assert_true(_inventory.remove(_rounds, 3))
	assert_eq(_inventory.count(_rounds), 5)


func test_removing_the_last_one_drops_the_item() -> void:
	_inventory.add(_drink)
	assert_true(_inventory.remove(_drink))
	assert_false(_inventory.has(_drink))
	assert_true(_inventory.is_empty())


func test_removing_more_than_held_removes_nothing() -> void:
	_inventory.add(_rounds, 2)
	assert_false(_inventory.remove(_rounds, 3))
	assert_eq(_inventory.count(_rounds), 2)
	assert_false(_inventory.remove(_shells))
	assert_false(_inventory.remove(_rounds, 0))


func test_items_keep_the_order_they_were_first_added() -> void:
	_inventory.add(_shells)
	_inventory.add(_drink)
	_inventory.add(_rounds)
	_inventory.add(_shells)
	assert_eq(_inventory.get_items(), [_shells, _drink, _rounds] as Array[ItemData])


func test_items_in_a_category() -> void:
	_inventory.add(_rounds)
	_inventory.add(_drink)
	_inventory.add(_shells)
	assert_eq(
		_inventory.get_items_in(ItemData.Category.AMMO), [_rounds, _shells] as Array[ItemData]
	)
	assert_eq(_inventory.get_items_in(ItemData.Category.HEALING), [_drink] as Array[ItemData])
	assert_true(_inventory.get_items_in(ItemData.Category.DOCUMENT).is_empty())


func test_add_emits_signals() -> void:
	watch_signals(_inventory)
	_inventory.add(_rounds, 8)
	assert_signal_emitted_with_parameters(_inventory, "item_added", [_rounds, 8])
	assert_signal_emit_count(_inventory, "changed", 1)


func test_remove_emits_signals() -> void:
	_inventory.add(_rounds, 8)
	watch_signals(_inventory)
	_inventory.remove(_rounds, 2)
	assert_signal_emitted_with_parameters(_inventory, "item_removed", [_rounds, 2])
	assert_signal_emit_count(_inventory, "changed", 1)


func test_a_failed_remove_emits_nothing() -> void:
	watch_signals(_inventory)
	_inventory.remove(_rounds)
	assert_signal_not_emitted(_inventory, "item_removed")
	assert_signal_not_emitted(_inventory, "changed")


func test_clear_empties_it() -> void:
	_inventory.add(_rounds, 3)
	_inventory.add(_drink)
	watch_signals(_inventory)
	_inventory.clear()
	assert_true(_inventory.is_empty())
	assert_signal_emit_count(_inventory, "changed", 1)
