extends GutTest

const PATH: String = "user://test_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_defaults_match_the_camera_defaults() -> void:
	var settings := GameSettings.new()
	assert_eq(settings.mouse_sensitivity, 0.1)
	assert_eq(settings.stick_sensitivity, 120.0)
	assert_false(settings.is_y_inverted)
	assert_true(settings.is_retro_filter_enabled)
	for bus in GameSettings.volume_buses():
		assert_eq(settings.get_volume(bus), 1.0)


func test_every_audio_bus_has_a_volume() -> void:
	var buses := GameSettings.volume_buses()
	assert_has(buses, AudioBuses.MASTER)
	for bus in AudioBuses.ALL:
		assert_has(buses, bus)


func test_volume_is_kept_between_zero_and_one() -> void:
	var settings := GameSettings.new()
	settings.set_volume(AudioBuses.SFX, 2.0)
	assert_eq(settings.get_volume(AudioBuses.SFX), 1.0)
	settings.set_volume(AudioBuses.SFX, -1.0)
	assert_eq(settings.get_volume(AudioBuses.SFX), 0.0)


func test_bus_volume_scales_the_layout_level() -> void:
	assert_almost_eq(GameSettings.bus_volume_db(-6.0, 1.0), -6.0, 0.001)
	assert_almost_eq(GameSettings.bus_volume_db(-6.0, 0.5), -6.0 + linear_to_db(0.5), 0.001)
	assert_eq(GameSettings.bus_volume_db(-6.0, 0.0), GameSettings.MUTE_DB)


func test_save_and_load_round_trip() -> void:
	var saved := GameSettings.new()
	saved.mouse_sensitivity = 0.25
	saved.stick_sensitivity = 200.0
	saved.is_y_inverted = true
	saved.is_retro_filter_enabled = false
	saved.set_volume(AudioBuses.MUSIC, 0.3)
	saved.set_volume(AudioBuses.MASTER, 0.8)
	assert_eq(saved.save(PATH), OK)

	var loaded := GameSettings.new()
	assert_eq(loaded.load_from(PATH), OK)
	assert_almost_eq(loaded.mouse_sensitivity, 0.25, 0.0001)
	assert_almost_eq(loaded.stick_sensitivity, 200.0, 0.0001)
	assert_true(loaded.is_y_inverted)
	assert_false(loaded.is_retro_filter_enabled)
	assert_almost_eq(loaded.get_volume(AudioBuses.MUSIC), 0.3, 0.0001)
	assert_almost_eq(loaded.get_volume(AudioBuses.MASTER), 0.8, 0.0001)
	assert_eq(loaded.get_volume(AudioBuses.SFX), 1.0)


func test_a_missing_file_leaves_the_defaults() -> void:
	var settings := GameSettings.new()
	assert_ne(settings.load_from("user://does_not_exist.cfg"), OK)
	assert_eq(settings.mouse_sensitivity, 0.1)


func test_bad_values_fall_back_or_clamp() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", "fast")
	config.set_value("controls", "stick_sensitivity", 9999.0)
	config.set_value("controls", "invert_y", 3)
	config.set_value("audio", "SFX", 5.0)
	config.save(PATH)
	var settings := GameSettings.new()
	settings.load_from(PATH)
	assert_eq(settings.mouse_sensitivity, 0.1)
	assert_eq(settings.stick_sensitivity, GameSettings.STICK_SENSITIVITY_RANGE.y)
	assert_false(settings.is_y_inverted)
	assert_eq(settings.get_volume(AudioBuses.SFX), 1.0)


func test_the_file_is_the_documented_one() -> void:
	assert_eq(GameSettings.DEFAULT_PATH, "user://settings.cfg")
