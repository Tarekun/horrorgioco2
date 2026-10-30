## What a save slot holds, for the slot screen to show: empty, a readable save
## with its area name, play time and timestamp, or a file that can't be loaded.

class_name SaveSlotInfo
extends RefCounted

enum Status {
	## No save in the slot.
	EMPTY,
	## A save that loads.
	OK,
	## A file that isn't a save: damaged, cut short or not JSON.
	UNREADABLE,
	## A save in another format version, from an older (or newer) build.
	WRONG_VERSION,
}

## Index of the slot, from 0.
var slot: int = 0

var status: Status = Status.EMPTY

## The save, when `status` is OK.
var save: SaveData


## Whether the slot holds a save that loads.
func is_loadable() -> bool:
	return status == Status.OK and save != null


## Whether the slot has a file, loadable or not, that a save would overwrite.
func is_occupied() -> bool:
	return status != Status.EMPTY


## The slot's line on the slot screen, without its number.
func describe() -> String:
	match status:
		Status.OK:
			return (
				"%s   %s   %s"
				% [
					save.area_name if not save.area_name.is_empty() else "Unknown area",
					format_play_time(save.play_time),
					format_timestamp(save.timestamp),
				]
			)
		Status.UNREADABLE:
			return "Unreadable save"
		Status.WRONG_VERSION:
			return "Save from another version of the game"
	return "Empty"


## `seconds` of play as hours, minutes and seconds ("1:02:05").
static func format_play_time(seconds: float) -> String:
	var total: int = maxi(int(seconds), 0)
	return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


## A Unix timestamp as local date and time ("2026-10-30 14:05"), or "" for 0.
static func format_timestamp(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var bias_minutes: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var local: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return (
		"%04d-%02d-%02d %02d:%02d"
		% [local["year"], local["month"], local["day"], local["hour"], local["minute"]]
	)
