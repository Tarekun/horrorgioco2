## Tests for the document reader screen: pages, pausing and marking read.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _player: Player
var _reader: DocumentReader
var _letter: ItemData


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_reader = _player.get_node("DocumentReader") as DocumentReader
	_letter = ItemData.new()
	_letter.id = &"doc_letter"
	_letter.display_name = "A letter"
	_letter.category = ItemData.Category.DOCUMENT
	_letter.pages = ["Page one.", "Page two.", "Page three."]
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input_event(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_reader._unhandled_input(event)


func test_opening_shows_the_first_page_and_pauses() -> void:
	_reader.open(_letter)
	assert_true(_reader.is_open)
	assert_true(_reader.panel.visible)
	assert_true(get_tree().paused)
	assert_eq(_reader.title_label.text, "A letter")
	assert_eq(_reader.page_label.text, "Page one.")
	assert_eq(_reader.page_indicator_label.text, "1 / 3")


func test_opening_marks_the_document_read() -> void:
	_reader.open(_letter)
	assert_true(_player.document_log.is_read(_letter))


func test_next_and_prev_turn_the_page() -> void:
	_reader.open(_letter)
	_reader.next_page()
	assert_eq(_reader.page_label.text, "Page two.")
	_reader.next_page()
	assert_eq(_reader.page_label.text, "Page three.")
	_reader.prev_page()
	assert_eq(_reader.page_label.text, "Page two.")


func test_paging_stops_at_either_end() -> void:
	_reader.open(_letter)
	_reader.prev_page()
	assert_eq(_reader.page_indicator_label.text, "1 / 3")
	_reader.next_page()
	_reader.next_page()
	_reader.next_page()
	assert_eq(_reader.page_indicator_label.text, "3 / 3")


func test_left_and_right_turn_the_page() -> void:
	_reader.open(_letter)
	_input_event(&"ui_right")
	assert_eq(_reader.page_label.text, "Page two.")
	_input_event(&"ui_left")
	assert_eq(_reader.page_label.text, "Page one.")


func test_pause_or_cancel_closes_it() -> void:
	_reader.open(_letter)
	_input_event(&"ui_cancel")
	assert_false(_reader.is_open)
	assert_false(get_tree().paused)


func test_close_resumes_and_recaptures_the_mouse() -> void:
	_reader.open(_letter)
	_reader.close()
	assert_false(_reader.is_open)
	assert_false(_reader.panel.visible)
	assert_false(get_tree().paused)
	assert_true(_player.camera_controller.is_mouse_captured())


func test_a_non_document_item_does_not_open() -> void:
	var key := ItemData.new()
	key.category = ItemData.Category.KEY_ITEM
	_reader.open(key)
	assert_false(_reader.is_open)


func test_cannot_open_while_another_screen_has_paused_the_game() -> void:
	get_tree().paused = true
	_reader.open(_letter)
	assert_false(_reader.is_open)


func test_cannot_open_while_dead() -> void:
	_player.health_component.take_damage(_player.health_component.max_health)
	_reader.open(_letter)
	assert_false(_reader.is_open)
