## Tests for saving an inventory to a dictionary and loading it back.

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


func _catalog() -> Dictionary[StringName, ItemData]:
	return {&"rounds": _rounds, &"shells": _shells, &"drink": _drink}


func test_to_dict_holds_ids_and_counts_in_order() -> void:
	_inventory.add(_shells, 4)
	_inventory.add(_rounds, 8)
	var data: Dictionary[String, int] = _inventory.to_dict()
	assert_eq(data, {"shells": 4, "rounds": 8} as Dictionary[String, int])
	assert_eq(data.keys(), ["shells", "rounds"])


func test_round_trip_through_a_dictionary() -> void:
	_inventory.add(_shells, 4)
	_inventory.add(_rounds, 8)
	_inventory.add(_drink, 2)
	var loaded := Inventory.new()
	loaded.from_dict(_inventory.to_dict(), _catalog())
	assert_eq(loaded.get_items(), _inventory.get_items())
	assert_eq(loaded.count(_shells), 4)
	assert_eq(loaded.count(_rounds), 8)
	assert_eq(loaded.count(_drink), 2)


func test_round_trip_through_json() -> void:
	_inventory.add(_rounds, 8)
	_inventory.add(_drink, 1)
	# JSON brings numbers back as floats.
	var parsed: Variant = JSON.parse_string(JSON.stringify(_inventory.to_dict()))
	var loaded := Inventory.new()
	loaded.from_dict(parsed as Dictionary, _catalog())
	assert_eq(loaded.count(_rounds), 8)
	assert_eq(loaded.count(_drink), 1)


func test_from_dict_replaces_the_contents() -> void:
	_inventory.add(_shells, 4)
	watch_signals(_inventory)
	_inventory.from_dict({"rounds": 3}, _catalog())
	assert_false(_inventory.has(_shells))
	assert_eq(_inventory.count(_rounds), 3)
	assert_signal_emit_count(_inventory, "changed", 1)


func test_from_dict_skips_unknown_ids_and_empty_stacks() -> void:
	_inventory.from_dict({"rounds": 3, "nonexistent": 2, "drink": 0}, _catalog())
	assert_eq(_inventory.get_items(), [_rounds] as Array[ItemData])


func test_from_dict_uses_the_item_catalog_by_default() -> void:
	_inventory.from_dict({"pistol_ammo": 8})
	var rounds: ItemData = ItemCatalog.find(&"pistol_ammo")
	assert_eq(_inventory.count(rounds), 8)
