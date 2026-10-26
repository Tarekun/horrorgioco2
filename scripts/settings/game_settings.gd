## The player's settings: look sensitivity, audio volumes and graphics options.
##
## Plain data with no engine side effects, so it can be tested without a
## scene. The UserSettings autoload owns the live instance, applies it and
## saves it to `user://settings.cfg`.

class_name GameSettings
extends RefCounted

const DEFAULT_PATH: String = "user://settings.cfg"

const MOUSE_SENSITIVITY_RANGE := Vector2(0.02, 0.4)
const STICK_SENSITIVITY_RANGE := Vector2(30.0, 300.0)

## Volume sliders are linear (0 to 1) and scale the bus's level from the audio
## layout; 0 mutes the bus.
const MUTE_DB: float = -80.0

const CONTROLS_SECTION: String = "controls"
const AUDIO_SECTION: String = "audio"
const GRAPHICS_SECTION: String = "graphics"

## Mouse look sensitivity, in degrees per pixel.
var mouse_sensitivity: float = 0.1

## Stick look sensitivity, in degrees per second at full tilt.
var stick_sensitivity: float = 120.0

## Inverts vertical look for both mouse and stick.
var is_y_inverted: bool = false

## Linear volume (0 to 1) of every bus, Master included. A bus missing from
## the dictionary is at full volume.
var volumes: Dictionary[StringName, float] = {}

## Whether the retro screen filter is on (#100 reads it).
var is_retro_filter_enabled: bool = true


## The bus names that have a volume slider, in display order.
static func volume_buses() -> Array[StringName]:
	var buses: Array[StringName] = [AudioBuses.MASTER]
	buses.append_array(AudioBuses.ALL)
	return buses


## Level in dB for a bus whose layout level is `base_db`, with the slider at
## `linear` (0 to 1).
static func bus_volume_db(base_db: float, linear: float) -> float:
	if linear <= 0.0001:
		return MUTE_DB
	return base_db + linear_to_db(clampf(linear, 0.0, 1.0))


## The volume of `bus` (0 to 1).
func get_volume(bus: StringName) -> float:
	return volumes.get(bus, 1.0)


## Sets the volume of `bus`, kept between 0 and 1.
func set_volume(bus: StringName, linear: float) -> void:
	volumes[bus] = clampf(linear, 0.0, 1.0)


## Writes the settings to a config file at `path`. Returns the error code.
func save(path: String = DEFAULT_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value(CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity)
	config.set_value(CONTROLS_SECTION, "stick_sensitivity", stick_sensitivity)
	config.set_value(CONTROLS_SECTION, "invert_y", is_y_inverted)
	for bus in volume_buses():
		config.set_value(AUDIO_SECTION, String(bus), get_volume(bus))
	config.set_value(GRAPHICS_SECTION, "retro_filter", is_retro_filter_enabled)
	return config.save(path)


## Reads the settings from the config file at `path`. A missing or unreadable
## file, and any value missing or of the wrong type, leaves the default. Returns
## the error code of reading the file.
func load_from(path: String = DEFAULT_PATH) -> Error:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return error
	mouse_sensitivity = _read_float(
		config, CONTROLS_SECTION, "mouse_sensitivity", mouse_sensitivity, MOUSE_SENSITIVITY_RANGE
	)
	stick_sensitivity = _read_float(
		config, CONTROLS_SECTION, "stick_sensitivity", stick_sensitivity, STICK_SENSITIVITY_RANGE
	)
	is_y_inverted = _read_bool(config, CONTROLS_SECTION, "invert_y", is_y_inverted)
	for bus in volume_buses():
		set_volume(bus, _read_float(config, AUDIO_SECTION, String(bus), get_volume(bus)))
	is_retro_filter_enabled = _read_bool(
		config, GRAPHICS_SECTION, "retro_filter", is_retro_filter_enabled
	)
	return OK


func _read_float(
	config: ConfigFile, section: String, key: String, fallback: float, limits := Vector2(0.0, 1.0)
) -> float:
	var value: Variant = config.get_value(section, key, fallback)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return fallback
	return clampf(float(value), limits.x, limits.y)


func _read_bool(config: ConfigFile, section: String, key: String, fallback: bool) -> bool:
	var value: Variant = config.get_value(section, key, fallback)
	return value if typeof(value) == TYPE_BOOL else fallback
