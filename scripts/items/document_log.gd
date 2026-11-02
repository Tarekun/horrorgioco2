## Which documents the player has read, by item id.
##
## Dialogue and other systems can ask whether a document was read (the porter's
## line about the key cabinet, say). to_dict() and from_dict() turn the
## contents into plain data for saving.

class_name DocumentLog
extends RefCounted

var _read: Dictionary[StringName, bool] = {}


## Marks `item` as read. Does nothing for a null item.
func mark_read(item: ItemData) -> void:
	if item == null:
		return
	_read[item.id] = true


## Whether `item` has been read.
func is_read(item: ItemData) -> bool:
	return item != null and _read.get(item.id, false)


## The read document ids, ready to save as JSON.
func to_dict() -> Dictionary[String, bool]:
	var data: Dictionary[String, bool] = {}
	for id: StringName in _read:
		data[String(id)] = true
	return data


## Replaces the contents with saved ids (see to_dict()).
func from_dict(data: Dictionary) -> void:
	_read.clear()
	for key: Variant in data:
		if data[key]:
			_read[StringName(str(key))] = true
