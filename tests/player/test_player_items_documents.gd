## Tests for rereading documents from the inventory screen.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _screen: InventoryScreen
var _reader: DocumentReader
var _letter: ItemData


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_screen = _player.get_node("InventoryScreen") as InventoryScreen
	_reader = _player.get_node("DocumentReader") as DocumentReader
	_letter = ItemData.new()
	_letter.id = &"doc_letter"
	_letter.display_name = "A letter"
	_letter.category = ItemData.Category.DOCUMENT
	_letter.pages = ["Page one.", "Page two."]
	_player.inventory.add(_letter)
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_reading_from_the_inventory_closes_it_and_opens_the_reader() -> void:
	_screen.open()
	_screen.select_tab(ItemData.Category.DOCUMENT)
	_screen.examine_selected()
	assert_false(_screen.is_open)
	assert_true(_reader.is_open)
	assert_eq(_reader.page_label.text, "Page one.")


func test_a_document_can_be_reread() -> void:
	_player.document_log.mark_read(_letter)
	_screen.open()
	_screen.select_tab(ItemData.Category.DOCUMENT)
	_screen.examine_selected()
	assert_true(_reader.is_open)
	assert_true(_player.document_log.is_read(_letter))
