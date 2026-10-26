extends GutTest

const SCREEN_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _screen: SettingsScreen
var _original := GameSettings.new()


func before_each() -> void:
	_original = UserSettings.settings
	UserSettings.settings = GameSettings.new()
	_screen = SCREEN_SCENE.instantiate() as SettingsScreen
	add_child_autofree(_screen)
	_screen.open()


func after_each() -> void:
	UserSettings.settings = _original
	UserSettings.commit()


func test_is_hidden_until_opened() -> void:
	var screen := SCREEN_SCENE.instantiate() as SettingsScreen
	add_child_autofree(screen)
	assert_false(screen.panel.visible)
	assert_false(screen.is_open)


func test_open_shows_the_current_settings_and_focuses_a_control() -> void:
	UserSettings.settings.mouse_sensitivity = 0.3
	UserSettings.settings.is_y_inverted = true
	UserSettings.settings.set_volume(AudioBuses.SFX, 0.4)
	_screen.close()
	_screen.open()
	assert_almost_eq(_screen.mouse_sensitivity_slider.value, 0.3, 0.001)
	assert_true(_screen.invert_y_check.button_pressed)
	assert_almost_eq(_screen.get_volume_slider(AudioBuses.SFX).value, 0.4, 0.001)
	assert_true(_screen.mouse_sensitivity_slider.has_focus())


func test_every_bus_has_a_slider() -> void:
	for bus in GameSettings.volume_buses():
		assert_not_null(_screen.get_volume_slider(bus), "no slider for %s" % bus)


func test_controls_write_the_settings() -> void:
	_screen.mouse_sensitivity_slider.value = 0.2
	_screen.stick_sensitivity_slider.value = 90.0
	_screen.invert_y_check.button_pressed = true
	_screen.retro_filter_check.button_pressed = false
	_screen.get_volume_slider(AudioBuses.AMBIENCE).value = 0.5
	var settings := UserSettings.settings
	assert_almost_eq(settings.mouse_sensitivity, 0.2, 0.001)
	assert_almost_eq(settings.stick_sensitivity, 90.0, 0.001)
	assert_true(settings.is_y_inverted)
	assert_false(settings.is_retro_filter_enabled)
	assert_almost_eq(settings.get_volume(AudioBuses.AMBIENCE), 0.5, 0.001)


func test_changes_are_announced() -> void:
	watch_signals(UserSettings)
	_screen.invert_y_check.button_pressed = true
	assert_signal_emitted(UserSettings, "changed")


func test_volume_changes_the_audio_bus() -> void:
	var index := AudioServer.get_bus_index(AudioBuses.SFX)
	var before := AudioServer.get_bus_volume_db(index)
	_screen.get_volume_slider(AudioBuses.SFX).value = 0.5
	assert_lt(AudioServer.get_bus_volume_db(index), before)
	_screen.get_volume_slider(AudioBuses.SFX).value = 0.0
	assert_true(AudioServer.is_bus_mute(index))
	_screen.get_volume_slider(AudioBuses.SFX).value = 1.0
	assert_false(AudioServer.is_bus_mute(index))
	assert_almost_eq(AudioServer.get_bus_volume_db(index), before, 0.01)


func test_settings_are_applied_to_the_camera() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	_screen.mouse_sensitivity_slider.value = 0.35
	_screen.stick_sensitivity_slider.value = 250.0
	_screen.invert_y_check.button_pressed = true
	assert_almost_eq(player.camera_controller.mouse_sensitivity, 0.35, 0.001)
	assert_almost_eq(player.camera_controller.joystick_sensitivity, 250.0, 0.001)
	assert_true(player.camera_controller.invert_y)


func test_a_new_camera_starts_with_the_settings() -> void:
	UserSettings.settings.is_y_inverted = true
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	assert_true(player.camera_controller.invert_y)


func test_back_and_cancel_close_it() -> void:
	watch_signals(_screen)
	_screen.back_button.pressed.emit()
	assert_false(_screen.is_open)
	assert_signal_emitted(_screen, "closed")
	_screen.open()
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_false(_screen.is_open)
