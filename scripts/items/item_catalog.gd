## Finds item definitions by id, so a saved inventory (ids and counts) turns
## back into items. Every ItemData in assets/data/items/ is in it; they are
## loaded once, the first time the catalog is asked.

class_name ItemCatalog
extends RefCounted

const ITEMS_DIR: String = "res://assets/data/items/"

static var _items: Dictionary[StringName, ItemData] = {}
static var _is_loaded: bool = false


## Every item, by id.
static func all() -> Dictionary[StringName, ItemData]:
	if not _is_loaded:
		_load()
	return _items


## The item with `id`, or null.
static func find(id: StringName) -> ItemData:
	return all().get(id)


static func _load() -> void:
	_is_loaded = true
	# list_directory() also sees resources that an export has converted.
	for file: String in ResourceLoader.list_directory(ITEMS_DIR):
		if file.ends_with("/"):
			continue
		var item := load(ITEMS_DIR + file) as ItemData
		if item == null:
			continue
		if _items.has(item.id):
			push_error("ItemCatalog: '%s' reuses the id '%s'." % [file, item.id])
			continue
		_items[item.id] = item
