## The items someone carries. There's no limit: every item stacks without end,
## so scarcity comes only from what is placed in the world.
##
## Items are listed in the order they were first added, so the inventory screen
## keeps a stable order. to_dict() and from_dict() turn the contents into plain
## data for saving: item ids and counts.

class_name Inventory
extends RefCounted

## Emitted after `amount` of `item` was added.
signal item_added(item: ItemData, amount: int)
## Emitted after `amount` of `item` was removed.
signal item_removed(item: ItemData, amount: int)
## Emitted after any change to the contents.
signal changed

var _items: Dictionary[StringName, ItemData] = {}
var _counts: Dictionary[StringName, int] = {}


## Adds `amount` of `item`. Ignores a null item or an amount below 1.
func add(item: ItemData, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return
	if not _items.has(item.id):
		_items[item.id] = item
		_counts[item.id] = 0
	_counts[item.id] += amount
	item_added.emit(item, amount)
	changed.emit()


## Removes `amount` of `item`. If there are fewer than that, removes nothing
## and returns false.
func remove(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0 or count(item) < amount:
		return false
	_counts[item.id] -= amount
	if _counts[item.id] == 0:
		_counts.erase(item.id)
		_items.erase(item.id)
	item_removed.emit(item, amount)
	changed.emit()
	return true


## How many of `item` there are.
func count(item: ItemData) -> int:
	if item == null:
		return 0
	return _counts.get(item.id, 0)


## Whether there are at least `amount` of `item`.
func has(item: ItemData, amount: int = 1) -> bool:
	return count(item) >= maxi(amount, 1)


## Every item held, in the order first added.
func get_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	items.assign(_items.values())
	return items


## The items held in `category`, in the order first added.
func get_items_in(category: ItemData.Category) -> Array[ItemData]:
	return get_items().filter(func(item: ItemData) -> bool: return item.category == category)


func is_empty() -> bool:
	return _items.is_empty()


## Empties the inventory.
func clear() -> void:
	if is_empty():
		return
	_items.clear()
	_counts.clear()
	changed.emit()


## The contents as item ids and counts, in order, ready to save as JSON.
func to_dict() -> Dictionary[String, int]:
	var data: Dictionary[String, int] = {}
	for id: StringName in _counts:
		data[String(id)] = _counts[id]
	return data


## Replaces the contents with saved ids and counts (see to_dict()). Ids are
## looked up in `catalog`, or in ItemCatalog when it is empty; unknown ids and
## counts below 1 are skipped. Emits `changed` once, not per item.
func from_dict(data: Dictionary, catalog: Dictionary[StringName, ItemData] = {}) -> void:
	var lookup: Dictionary[StringName, ItemData] = (
		catalog if not catalog.is_empty() else ItemCatalog.all()
	)
	_items.clear()
	_counts.clear()
	for key: Variant in data:
		var id := StringName(str(key))
		var amount: int = int(data[key])
		var item: ItemData = lookup.get(id)
		if item == null:
			push_warning("Inventory: no item with id '%s'; skipped." % id)
			continue
		if amount > 0:
			_items[id] = item
			_counts[id] = amount
	changed.emit()
