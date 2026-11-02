## The document reader: shows a document's pages, full screen.
##
## open() pauses the game and releases the mouse, like the other screens.
## Pickup opens it the moment a document is picked up; the inventory screen's
## Read action reopens it for a document already held. Either way, opening a
## document marks it read in the player's DocumentLog.
##
## Left and right turn the page; `pause` or `ui_cancel` closes it.

class_name DocumentReader
extends CanvasLayer

## Emitted after the reader opens.
signal opened
## Emitted after the reader closes.
signal closed

## Group pickups broadcast to, so a level scene can open the reader without a
## direct reference to the player's screens.
const GROUP: StringName = &"document_reader"

## Whose DocumentLog records the document as read.
@export var player: Player

## The container shown and hidden with the screen.
@export var panel: Control

@export var title_label: Label
@export var page_label: Label
@export var page_indicator_label: Label
@export var prev_button: Button
@export var next_button: Button

var is_open: bool = false

var _item: ItemData
var _page_index: int = 0


func _ready() -> void:
	# Keep running while the tree is paused, so the screen works.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	panel.visible = false
	prev_button.pressed.connect(prev_page)
	next_button.pressed.connect(next_page)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"ui_left"):
		prev_page()
	elif event.is_action_pressed(&"ui_right"):
		next_page()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


## Whether the reader may open now: the player is alive and no other screen
## has paused the game.
func can_open() -> bool:
	return not get_tree().paused and player and not player.health_component.is_dead


## Opens the reader on `item`'s first page and marks it read. Does nothing for
## a non-document item, or if the reader can't open.
func open(item: ItemData) -> void:
	if item == null or not item.is_document():
		return
	if not is_open and not can_open():
		return
	is_open = true
	_item = item
	_page_index = 0
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if player:
		player.document_log.mark_read(item)
	_refresh()
	opened.emit()


## Hides the reader, resumes the game and captures the mouse again.
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


## Turns to the next page, if any.
func next_page() -> void:
	_turn_page(1)


## Turns to the previous page, if any.
func prev_page() -> void:
	_turn_page(-1)


func _turn_page(step: int) -> void:
	if _item == null or _item.pages.is_empty():
		return
	var last_page: int = _item.pages.size() - 1
	var new_index: int = clampi(_page_index + step, 0, last_page)
	if new_index == _page_index:
		return
	_page_index = new_index
	_refresh()


func _refresh() -> void:
	if _item == null:
		return
	title_label.text = _item.display_name
	var total: int = _item.pages.size()
	page_label.text = _item.pages[_page_index] if _page_index < total else ""
	page_indicator_label.text = "%d / %d" % [_page_index + 1, maxi(total, 1)]
	prev_button.disabled = _page_index <= 0
	next_button.disabled = _page_index >= total - 1
