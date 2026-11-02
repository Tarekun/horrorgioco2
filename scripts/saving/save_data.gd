## Everything one save holds: where it was made, the player and the world.
##
## The player's part is health, inventory, the weapon held and the flashlight;
## Player.write_save() fills it in. The world's part is a WorldState copy. The
## save spot used is kept by id, and loading puts the player there. Area name,
## play time and timestamp are what a save slot shows.
##
## to_dict() and from_dict() turn it into plain, JSON-safe data and back.
## Firearms will add magazine and reserve ammo here.

class_name SaveData
extends RefCounted

## The level scene the save was made in.
var level_path: String = ""

## Name of the area, shown on the save slot.
var area_name: String = ""

## Persistent id of the save spot used.
var save_spot_id: StringName = &""

## Seconds of play, shown on the save slot.
var play_time: float = 0.0

## When the save was written, in Unix seconds (UTC).
var timestamp: int = 0

var player_health: float = 0.0

## Item ids and counts, as Inventory.to_dict() gives them.
var inventory: Dictionary[String, int] = {}

## Read document ids, as DocumentLog.to_dict() gives them.
var documents_read: Dictionary[String, bool] = {}

## Id of the weapon held, or empty.
var equipped_weapon: StringName = &""

var is_flashlight_on: bool = true

var world := WorldState.new()


## The save as plain data, ready to store as JSON.
func to_dict() -> Dictionary:
	return {
		"level_path": level_path,
		"area_name": area_name,
		"save_spot_id": String(save_spot_id),
		"play_time": play_time,
		"timestamp": timestamp,
		"player":
		{
			"health": player_health,
			"inventory": inventory.duplicate(),
			"documents_read": documents_read.duplicate(),
			"equipped_weapon": String(equipped_weapon),
			"is_flashlight_on": is_flashlight_on,
		},
		"world": world.to_dict(),
	}


## A save from to_dict()'s data, or null if it has no level to load. Missing
## or mistyped values fall back to the defaults, so a damaged save still loads
## what it can.
static func from_dict(data: Dictionary) -> SaveData:
	var level: Variant = data.get("level_path")
	if not level is String or (level as String).is_empty():
		return null
	var save := SaveData.new()
	save.level_path = level
	save.area_name = _get_string(data, "area_name")
	save.save_spot_id = StringName(_get_string(data, "save_spot_id"))
	save.play_time = maxf(_get_number(data, "play_time"), 0.0)
	save.timestamp = int(_get_number(data, "timestamp"))
	var player: Dictionary = _get_dictionary(data, "player")
	save.player_health = _get_number(player, "health")
	var items: Dictionary = _get_dictionary(player, "inventory")
	for id: Variant in items:
		var amount: Variant = items[id]
		if amount is float or amount is int:
			save.inventory[str(id)] = int(amount)
	var read_documents: Dictionary = _get_dictionary(player, "documents_read")
	for id: Variant in read_documents:
		if read_documents[id]:
			save.documents_read[str(id)] = true
	save.equipped_weapon = StringName(_get_string(player, "equipped_weapon"))
	var flashlight: Variant = player.get("is_flashlight_on")
	save.is_flashlight_on = flashlight if flashlight is bool else true
	save.world.from_dict(_get_dictionary(data, "world"))
	return save


static func _get_string(data: Dictionary, key: String) -> String:
	var value: Variant = data.get(key)
	return value if value is String else ""


static func _get_number(data: Dictionary, key: String) -> float:
	var value: Variant = data.get(key)
	return float(value) if value is float or value is int else 0.0


static func _get_dictionary(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key)
	return value if value is Dictionary else {}
