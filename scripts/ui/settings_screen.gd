## The settings screen: look sensitivity, volume sliders and graphics options.
##
## Each control writes straight to UserSettings.settings and commits, so the
## camera and the audio buses follow while the player drags. Closing saves the
## settings to disk. Works with keyboard, mouse and gamepad through the
## engine's UI focus navigation (left and right adjust a focused slider).
##
## The volume rows are built from the audio buses, so a new bus gets a slider
## without touching the scene. The screen keeps running while the game is
## paused, and handles `pause` and `ui_cancel` itself so a menu under it
## doesn't close too.

class_name SettingsScreen
extends CanvasLayer

## Emitted after the screen closes.
signal closed

@export var panel: Control
@export var mouse_sensitivity_slider: HSlider
@export var stick_sensitivity_slider: HSlider
@export var invert_y_check: CheckBox

## The box the volume rows are added to.
@export var volume_rows: Container

@export var retro_filter_check: CheckBox
@export var back_button: Button

var is_open: bool = false

var _volume_sliders: Dictionary[StringName, HSlider] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_build_volume_rows()
	mouse_sensitivity_slider.min_value = GameSettings.MOUSE_SENSITIVITY_RANGE.x
	mouse_sensitivity_slider.max_value = GameSettings.MOUSE_SENSITIVITY_RANGE.y
	stick_sensitivity_slider.min_value = GameSettings.STICK_SENSITIVITY_RANGE.x
	stick_sensitivity_slider.max_value = GameSettings.STICK_SENSITIVITY_RANGE.y
	mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	stick_sensitivity_slider.value_changed.connect(_on_stick_sensitivity_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)
	retro_filter_check.toggled.connect(_on_retro_filter_toggled)
	back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Shows the screen with the controls at the current settings.
func open() -> void:
	if is_open:
		return
	_show_current_settings()
	is_open = true
	panel.visible = true
	mouse_sensitivity_slider.grab_focus()


## Hides the screen and saves the settings.
func close() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	UserSettings.save()
	closed.emit()


## The slider for `bus`'s volume, or null if it has none.
func get_volume_slider(bus: StringName) -> HSlider:
	return _volume_sliders.get(bus)


func _build_volume_rows() -> void:
	for bus in GameSettings.volume_buses():
		var row := HBoxContainer.new()
		row.name = "%sVolume" % bus
		var label := Label.new()
		label.text = "%s volume" % bus
		label.custom_minimum_size.x = 160.0
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 240.0
		slider.value_changed.connect(_on_volume_changed.bind(bus))
		row.add_child(label)
		row.add_child(slider)
		volume_rows.add_child(row)
		_volume_sliders[bus] = slider


func _show_current_settings() -> void:
	var settings: GameSettings = UserSettings.settings
	# Setting a control's value emits its signal, which would write the same
	# value back; harmless, but the commit would announce a change that isn't.
	mouse_sensitivity_slider.set_value_no_signal(settings.mouse_sensitivity)
	stick_sensitivity_slider.set_value_no_signal(settings.stick_sensitivity)
	invert_y_check.set_pressed_no_signal(settings.is_y_inverted)
	retro_filter_check.set_pressed_no_signal(settings.is_retro_filter_enabled)
	for bus: StringName in _volume_sliders:
		_volume_sliders[bus].set_value_no_signal(settings.get_volume(bus))


func _on_mouse_sensitivity_changed(value: float) -> void:
	UserSettings.settings.mouse_sensitivity = value
	UserSettings.commit()


func _on_stick_sensitivity_changed(value: float) -> void:
	UserSettings.settings.stick_sensitivity = value
	UserSettings.commit()


func _on_invert_y_toggled(is_pressed: bool) -> void:
	UserSettings.settings.is_y_inverted = is_pressed
	UserSettings.commit()


func _on_retro_filter_toggled(is_pressed: bool) -> void:
	UserSettings.settings.is_retro_filter_enabled = is_pressed
	UserSettings.commit()


func _on_volume_changed(value: float, bus: StringName) -> void:
	UserSettings.settings.set_volume(bus, value)
	UserSettings.commit()
