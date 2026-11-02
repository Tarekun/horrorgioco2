## The inventory screen: where the player manages items, and the only place
## their health state is shown.
##
## `inventory` opens it during play and closes it again; `pause` closes it too.
## While open it pauses the game and releases the mouse. It won't open while
## the player is dead or over another screen that paused the game.
##
## Tabs sort the items by category. While the list has focus, left and right
## change tab, up and down pick an item, and accept moves to its actions:
## Equip (weapons), Use (healing items) and Examine (everything). `ui_cancel`
## steps back from the actions to the list, then closes the screen. Equip and
## Use only ask: the screen emits a signal and the player's other nodes carry
## it out. It is built from Controls and the ui_* actions, so keyboard, mouse
## and gamepad all work.
##
## The status readout is an ECG trace and the word Fine, Caution or Danger,
## never a number.

class_name InventoryScreen
extends CanvasLayer

## Emitted after the screen opens.
signal opened
## Emitted after the screen closes.
signal closed
## Emitted when the player chooses Equip on `item`.
signal equip_requested(item: ItemData)
## Emitted when the player chooses Use on `item`.
signal use_requested(item: ItemData)
## Emitted when the player chooses Read on a document.
signal read_requested(item: ItemData)

## Whose inventory and health it shows.
@export var player: Player

## The container shown and hidden with the screen.
@export var panel: Control

## One tab per ItemData.Category, in the enum's order.
@export var tab_bar: TabBar

@export var item_list: ItemList
@export var item_name_label: Label

## Shows the selected item's description once it is examined.
@export var description_label: Label

@export var equip_button: Button
@export var use_button: Button
@export var examine_button: Button

## A short reply to an action ("You don't need that right now.").
@export var message_label: Label

@export_group("Status")
@export var ecg_line: EcgLine
@export var status_label: Label

var is_open: bool = false

## The weapon held, marked in the list; Equip is off for it.
var equipped_item: ItemData

## The item the details panel shows, to tell a new selection from a refresh.
var _shown_item: ItemData


func _ready() -> void:
	# Keep running while the tree is paused, so the screen works.
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	tab_bar.tab_changed.connect(_on_tab_changed)
	item_list.item_selected.connect(_on_item_selected)
	item_list.item_activated.connect(_on_item_activated)
	equip_button.pressed.connect(equip_selected)
	use_button.pressed.connect(use_selected)
	examine_button.pressed.connect(examine_selected)
	for button: Button in _action_buttons():
		button.focus_neighbor_top = button.get_path_to(item_list)
	equip_button.focus_neighbor_left = equip_button.get_path_to(item_list)
	player.inventory.changed.connect(_on_inventory_changed)
	player.health_component.health_changed.connect(_on_health_changed)
	refresh()
	_update_status()


func _input(event: InputEvent) -> void:
	# Before the GUI, which would move the focus away from the list.
	if not is_open or not item_list.has_focus():
		return
	if event.is_action_pressed(&"ui_left", true):
		select_tab(tab_bar.current_tab - 1)
	elif event.is_action_pressed(&"ui_right", true):
		select_tab(tab_bar.current_tab + 1)
	else:
		return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory"):
		if is_open:
			close()
		elif can_open():
			open()
		else:
			return
	elif not is_open:
		return
	elif event.is_action_pressed(&"ui_cancel") and _is_in_actions():
		item_list.grab_focus()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


## Whether the screen may open now: the player is alive and no other screen
## has paused the game.
func can_open() -> bool:
	return not get_tree().paused and not player.health_component.is_dead


## Pauses the game and shows the screen. Does nothing if it can't open.
func open() -> void:
	if is_open or not can_open():
		return
	is_open = true
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	message_label.text = ""
	refresh()
	_update_status()
	item_list.grab_focus()
	opened.emit()


## Hides the screen, resumes the game and captures the mouse again.
func close() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# The camera only turns with the mouse once it knows it is captured.
	get_tree().call_group(CameraController.MOUSE_LOOK_GROUP, &"capture_mouse")
	closed.emit()


## Shows the tab at `index`, wrapping around at either end.
func select_tab(index: int) -> void:
	tab_bar.current_tab = wrapi(index, 0, tab_bar.tab_count)


## The category of the tab shown.
func get_category() -> ItemData.Category:
	return tab_bar.current_tab as ItemData.Category


## The item selected in the list, or null.
func get_selected_item() -> ItemData:
	var selected: PackedInt32Array = item_list.get_selected_items()
	if selected.is_empty():
		return null
	return item_list.get_item_metadata(selected[0]) as ItemData


## Selects the row of `item` in the list. Returns false if it isn't shown.
func select_item(item: ItemData) -> bool:
	for index: int in item_list.item_count:
		if item_list.get_item_metadata(index) == item:
			item_list.select(index)
			_show_details(item)
			return true
	return false


## Asks for the selected weapon to be equipped.
func equip_selected() -> void:
	var item: ItemData = get_selected_item()
	if item and item.is_equippable():
		equip_requested.emit(item)


## Asks for the selected item to be used.
func use_selected() -> void:
	var item: ItemData = get_selected_item()
	if item and item.is_usable():
		use_requested.emit(item)


## Shows the selected item's description, or asks to read it if it is a
## document.
func examine_selected() -> void:
	var item: ItemData = get_selected_item()
	if item == null:
		return
	if item.is_document():
		read_requested.emit(item)
	else:
		description_label.text = item.description


## Marks `item` as the weapon held.
func set_equipped(item: ItemData) -> void:
	equipped_item = item
	refresh()


## Shows a short reply to an action until another item is selected.
func show_message(text: String) -> void:
	message_label.text = text


## Rebuilds the list for the current tab, keeping the selection on the same
## item, or on the same row if that item is gone.
func refresh() -> void:
	var previous: ItemData = get_selected_item()
	var selected: PackedInt32Array = item_list.get_selected_items()
	var previous_row: int = selected[0] if not selected.is_empty() else 0
	item_list.clear()
	for item: ItemData in player.inventory.get_items_in(get_category()):
		var label: String = item_label(item, player.inventory.count(item), item == equipped_item)
		var row: int = item_list.add_item(label, item.icon)
		item_list.set_item_metadata(row, item)
	if item_list.item_count == 0:
		_show_details(null)
	elif not select_item(previous):
		item_list.select(clampi(previous_row, 0, item_list.item_count - 1))
		_show_details(get_selected_item())
	item_list.ensure_current_is_visible()


## The list's text for `count` of `item`, marked if it is the weapon held.
static func item_label(item: ItemData, count: int, is_equipped: bool = false) -> String:
	var label: String = item.display_name
	if count > 1:
		label = "%s ×%d" % [label, count]
	if is_equipped:
		label += "  (equipped)"
	return label


func _action_buttons() -> Array[Button]:
	return [equip_button, use_button, examine_button]


func _is_in_actions() -> bool:
	return _action_buttons().any(func(button: Button) -> bool: return button.has_focus())


func _show_details(item: ItemData) -> void:
	if item != _shown_item:
		description_label.text = ""
		message_label.text = ""
	_shown_item = item
	item_name_label.text = item.display_name if item else ""
	equip_button.disabled = item == null or not item.is_equippable() or item == equipped_item
	use_button.disabled = item == null or not item.is_usable()
	examine_button.disabled = item == null
	examine_button.text = "Read" if item and item.is_document() else "Examine"
	# A button that just became unusable gives the focus back to the list.
	for button: Button in _action_buttons():
		if button.disabled and button.has_focus():
			item_list.grab_focus()


func _update_status() -> void:
	var state: HealthState.State = HealthState.from_health(player.health_component.current_health)
	ecg_line.state = state
	status_label.text = HealthState.state_name(state)
	status_label.add_theme_color_override(&"font_color", ecg_line.get_color())


func _on_tab_changed(_tab: int) -> void:
	# A new tab starts at its first item.
	item_list.deselect_all()
	refresh()


func _on_item_selected(_index: int) -> void:
	_show_details(get_selected_item())


func _on_item_activated(_index: int) -> void:
	for button: Button in _action_buttons():
		if not button.disabled:
			button.grab_focus()
			return


func _on_inventory_changed() -> void:
	refresh()


func _on_health_changed(_new_value: float) -> void:
	_update_status()
