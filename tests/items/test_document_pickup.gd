## Tests for DocumentPickup: a Pickup that also opens the document reader.

extends GutTest

const DOCUMENT_PICKUP_SCENE: PackedScene = preload("res://scenes/items/document_pickup.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _reader: DocumentReader
var _pickup: DocumentPickup
var _letter: ItemData


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_reader = _player.get_node("DocumentReader") as DocumentReader
	_letter = ItemData.new()
	_letter.id = &"doc_letter"
	_letter.display_name = "A letter"
	_letter.category = ItemData.Category.DOCUMENT
	_letter.pages = ["Page one."]
	_pickup = DOCUMENT_PICKUP_SCENE.instantiate() as DocumentPickup
	_pickup.item = _letter
	add_child_autofree(_pickup)
	await get_tree().physics_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_picking_up_adds_it_to_the_inventory() -> void:
	_pickup.interact(_player)
	assert_true(_player.inventory.has(_letter))


func test_picking_up_opens_the_reader() -> void:
	_pickup.interact(_player)
	assert_true(_reader.is_open)
	assert_eq(_reader.page_label.text, "Page one.")
	assert_true(_player.document_log.is_read(_letter))


func test_it_can_be_picked_up_only_once() -> void:
	_pickup.interact(_player)
	_reader.close()
	_pickup.interact(_player)
	assert_false(_reader.is_open)


func test_a_non_document_pickup_does_not_open_the_reader() -> void:
	var key := ItemData.new()
	key.id = &"test_key"
	key.category = ItemData.Category.KEY_ITEM
	var other := DOCUMENT_PICKUP_SCENE.instantiate() as DocumentPickup
	other.item = key
	add_child_autofree(other)
	other.interact(_player)
	assert_false(_reader.is_open)
	assert_true(_player.inventory.has(key))
