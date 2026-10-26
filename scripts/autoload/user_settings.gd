## Holds the live player settings: loads them at startup, applies the audio
## volumes, and tells everyone else when they change.
##
## A settings screen edits `settings` and calls commit(); anything that
## depends on a setting (the camera, the retro filter) connects to `changed`
## and reads it from `settings`. save() writes them to disk, and does nothing
## on a headless display, so tests and CI never read or write a player's file.

extends Node

## Emitted by commit(), after the audio buses were updated.
signal changed

## Where the settings are stored. Tests replace it.
var path: String = GameSettings.DEFAULT_PATH

var settings := GameSettings.new()

# The level of each bus in the audio layout, which the volume sliders scale.
var _base_db: Dictionary[StringName, float] = {}


func _ready() -> void:
	for bus in GameSettings.volume_buses():
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			_base_db[bus] = AudioServer.get_bus_volume_db(index)
	if _is_storage_enabled():
		settings.load_from(path)
	_apply_audio()


## Applies the current settings and announces the change.
func commit() -> void:
	_apply_audio()
	changed.emit()


## Writes the settings to disk.
func save() -> void:
	if _is_storage_enabled():
		settings.save(path)


func _is_storage_enabled() -> bool:
	return DisplayServer.get_name() != "headless"


func _apply_audio() -> void:
	for bus: StringName in _base_db:
		var index := AudioServer.get_bus_index(bus)
		var linear := settings.get_volume(bus)
		AudioServer.set_bus_mute(index, linear <= 0.0001)
		AudioServer.set_bus_volume_db(index, GameSettings.bus_volume_db(_base_db[bus], linear))
