## The save slot screen: all SLOT_COUNT slots, each with its area name, play
## time and timestamp, or why it can't be loaded.
##
## In save mode, opened at a save spot, choosing a slot writes the save there,
## asking first when the slot already holds something. In load mode, which the
## main menu and the game over screen open, choosing a slot with a loadable
## save emits `load_requested`; empty, damaged and old slots can't be chosen.
## Opened at a save spot, the switch button turns to load mode and back.
##
## During play, opening the screen pauses the game and closing it resumes and
## captures the mouse again. Over a screen that already paused the game (game
## over), or on the title screen, it leaves the pause alone. `ui_cancel` and
## `pause` step back from the overwrite question, then close the screen. Built
## from Buttons and the ui_* actions, so keyboard, mouse and gamepad all work.
## Placeholder look; the final one comes from the art work.

class_name SaveScreen
extends CanvasLayer

## Emitted after the screen closes.
signal closed
## Emitted after a save was written to `slot`.
signal saved(slot: int)
## Emitted when a loadable save is chosen in load mode.
signal load_requested(save: SaveData)

enum Mode { SAVE, LOAD }

const SAVED_MESSAGE: String = "Saved."
const SAVE_FAILED_MESSAGE: String = "The save failed."
const OVERWRITE_QUESTION: String = "Save over slot %d?"

## The container shown and hidden with the screen.
@export var panel: Control
@export var title_label: Label

## The box the slot buttons are added to.
@export var slot_list: Container

## A short reply ("Saved.").
@export var message_label: Label

## Turns between saving and loading; shown only when opened to save.
@export var switch_button: Button
@export var back_button: Button

@export_group("Overwrite")
## Asks before saving over a slot that holds something.
@export var confirm_panel: Control
@export var confirm_label: Label
@export var confirm_button: Button
@export var cancel_button: Button

var mode: Mode = Mode.LOAD
var is_open: bool = false

## What each slot holds, as last read.
var slot_infos: Array[SaveSlotInfo] = []

# The save written in save mode.
var _save: SaveData
var _pending_slot: int = -1
var _has_paused: bool = false
var _slot_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	confirm_panel.visible = false
	_build_slot_buttons()
	back_button.pressed.connect(close)
	switch_button.pressed.connect(switch_mode)
	confirm_button.pressed.connect(confirm_overwrite)
	cancel_button.pressed.connect(cancel_overwrite)
	# Keep the focus on the question while it is up.
	for button: Button in [confirm_button, cancel_button]:
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if not (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		return
	if is_confirming():
		cancel_overwrite()
	else:
		close()
	get_viewport().set_input_as_handled()


## Opens the screen to write `save` into a slot.
func open_to_save(save: SaveData) -> void:
	_save = save
	_open(Mode.SAVE)


## Opens the screen to pick a save to load.
func open_to_load() -> void:
	_save = null
	_open(Mode.LOAD)


## Turns from saving to loading or back. Only a screen opened to save can.
func switch_mode() -> void:
	if not is_open or _save == null or is_confirming():
		return
	mode = Mode.LOAD if mode == Mode.SAVE else Mode.SAVE
	message_label.text = ""
	_show_mode()
	refresh()
	_focus_first_slot()


## Hides the screen, resuming the game if opening it paused it.
func close() -> void:
	if not is_open:
		return
	_hide()
	if _has_paused:
		_has_paused = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# The camera only turns with the mouse once it knows it is captured.
		get_tree().call_group(CameraController.MOUSE_LOOK_GROUP, &"capture_mouse")
	closed.emit()


## Re-reads the slots and updates their buttons.
func refresh() -> void:
	slot_infos = SaveSystem.slots.list()
	for info: SaveSlotInfo in slot_infos:
		var button: Button = _slot_buttons[info.slot]
		button.text = "Slot %d   %s" % [info.slot + 1, info.describe()]
		button.disabled = mode == Mode.LOAD and not info.is_loadable()


## The button of `slot` (from 0).
func get_slot_button(slot: int) -> Button:
	return _slot_buttons[slot]


## Acts on `slot`: saves into it (asking first if it holds something) or asks
## to load it.
func choose_slot(slot: int) -> void:
	if not is_open or is_confirming() or slot < 0 or slot >= slot_infos.size():
		return
	var info: SaveSlotInfo = slot_infos[slot]
	if mode == Mode.LOAD:
		if info.is_loadable():
			close()
			load_requested.emit(info.save)
	elif info.is_occupied():
		_ask_overwrite(slot)
	else:
		_write(slot)


## Whether the overwrite question is up.
func is_confirming() -> bool:
	return confirm_panel.visible


## Saves over the slot the question is about.
func confirm_overwrite() -> void:
	if not is_confirming():
		return
	var slot: int = _pending_slot
	_close_question()
	_write(slot)


## Drops the overwrite question and goes back to the slots.
func cancel_overwrite() -> void:
	if not is_confirming():
		return
	var slot: int = _pending_slot
	_close_question()
	_slot_buttons[slot].grab_focus()


func _open(new_mode: Mode) -> void:
	if is_open:
		return
	mode = new_mode
	is_open = true
	panel.visible = true
	switch_button.visible = _save != null
	_show_mode()
	message_label.text = ""
	if GameFlow.state == GameFlow.State.PLAYING and not get_tree().paused:
		_has_paused = true
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	refresh()
	_focus_first_slot()


func _show_mode() -> void:
	title_label.text = "Save game" if mode == Mode.SAVE else "Load game"
	switch_button.text = "Load a save" if mode == Mode.SAVE else "Save here"


func _hide() -> void:
	is_open = false
	panel.visible = false
	_close_question()


func _write(slot: int) -> void:
	var error: Error = SaveSystem.write_slot(slot, _save)
	message_label.text = SAVED_MESSAGE if error == OK else SAVE_FAILED_MESSAGE
	refresh()
	_slot_buttons[slot].grab_focus()
	if error == OK:
		saved.emit(slot)


func _ask_overwrite(slot: int) -> void:
	_pending_slot = slot
	confirm_label.text = OVERWRITE_QUESTION % (slot + 1)
	confirm_panel.visible = true
	# No is the safe answer to a double press.
	cancel_button.grab_focus()


func _close_question() -> void:
	_pending_slot = -1
	confirm_panel.visible = false


func _focus_first_slot() -> void:
	for button: Button in _slot_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	back_button.grab_focus()


func _build_slot_buttons() -> void:
	for slot: int in SaveSlots.SLOT_COUNT:
		var button := Button.new()
		button.name = "Slot%d" % (slot + 1)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(choose_slot.bind(slot))
		slot_list.add_child(button)
		_slot_buttons.append(button)
