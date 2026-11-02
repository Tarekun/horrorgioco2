## Tests for the inventory screen's tabs, item list and actions.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")
const SHELLS: ItemData = preload("res://assets/data/items/shotgun_shells.tres")

var _player: Player
var _screen: InventoryScreen
var _weapon: ItemData
var _drink: ItemData


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_screen = _player.get_node("InventoryScreen") as InventoryScreen
	_weapon = _make_item(&"test_bat", ItemData.Category.WEAPON)
	_drink = _make_item(&"test_drink", ItemData.Category.HEALING)
	await get_tree().process_frame


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _make_item(id: StringName, category: ItemData.Category) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = String(id).capitalize()
	item.description = "A test item."
	item.category = category
	return item


func _labels() -> Array[String]:
	var labels: Array[String] = []
	for index: int in _screen.item_list.item_count:
		labels.append(_screen.item_list.get_item_text(index))
	return labels


func _input_event(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_screen._input(event)


func test_has_a_tab_per_category() -> void:
	var titles: Array[String] = []
	for index: int in _screen.tab_bar.tab_count:
		titles.append(_screen.tab_bar.get_tab_title(index))
	assert_eq(titles, ["Weapons", "Ammo", "Healing", "Key items", "Documents"] as Array[String])
	for category: int in ItemData.Category.values():
		_screen.select_tab(category)
		assert_eq(_screen.get_category(), category)


func test_a_tab_lists_its_items_with_counts() -> void:
	_player.inventory.add(ROUNDS, 8)
	_player.inventory.add(_drink)
	_player.inventory.add(SHELLS, 1)
	_screen.open()
	_screen.select_tab(ItemData.Category.AMMO)
	assert_eq(_labels(), ["Pistol rounds ×8", "Shotgun shells"] as Array[String])
	_screen.select_tab(ItemData.Category.HEALING)
	assert_eq(_labels(), ["Test Drink"] as Array[String])


func test_left_and_right_change_tab_from_the_list() -> void:
	_screen.open()
	_screen.select_tab(ItemData.Category.AMMO)
	_input_event(&"ui_right")
	assert_eq(_screen.get_category(), ItemData.Category.HEALING)
	_input_event(&"ui_left")
	_input_event(&"ui_left")
	assert_eq(_screen.get_category(), ItemData.Category.WEAPON)
	_input_event(&"ui_left")
	assert_eq(_screen.get_category(), ItemData.Category.DOCUMENT)


func test_left_and_right_move_between_the_actions_instead() -> void:
	_player.inventory.add(_drink)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.use_button.grab_focus()
	_input_event(&"ui_right")
	assert_eq(_screen.get_category(), ItemData.Category.HEALING)


func test_the_first_item_is_selected_with_its_details() -> void:
	_player.inventory.add(ROUNDS, 8)
	_player.inventory.add(SHELLS, 4)
	_screen.open()
	_screen.select_tab(ItemData.Category.AMMO)
	assert_eq(_screen.get_selected_item(), ROUNDS)
	assert_eq(_screen.item_name_label.text, "Pistol rounds")
	assert_eq(_screen.description_label.text, "")


func test_an_empty_tab_disables_the_actions() -> void:
	_screen.open()
	_screen.select_tab(ItemData.Category.DOCUMENT)
	assert_null(_screen.get_selected_item())
	assert_eq(_screen.item_name_label.text, "")
	assert_true(_screen.equip_button.disabled)
	assert_true(_screen.use_button.disabled)
	assert_true(_screen.examine_button.disabled)


func test_actions_depend_on_the_category() -> void:
	_player.inventory.add(_weapon)
	_player.inventory.add(_drink)
	_player.inventory.add(ROUNDS, 8)
	_screen.open()
	_screen.select_tab(ItemData.Category.WEAPON)
	_screen.select_item(_weapon)
	assert_false(_screen.equip_button.disabled)
	assert_true(_screen.use_button.disabled)
	_screen.select_tab(ItemData.Category.HEALING)
	assert_true(_screen.equip_button.disabled)
	assert_false(_screen.use_button.disabled)
	_screen.select_tab(ItemData.Category.AMMO)
	assert_true(_screen.equip_button.disabled)
	assert_true(_screen.use_button.disabled)
	assert_false(_screen.examine_button.disabled)


func test_examine_reads_on_a_document_instead() -> void:
	var document: ItemData = _make_item(&"test_doc", ItemData.Category.DOCUMENT)
	_player.inventory.add(document)
	_screen.open()
	_screen.select_tab(ItemData.Category.DOCUMENT)
	assert_eq(_screen.examine_button.text, "Read")
	watch_signals(_screen)
	_screen.examine_button.pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "read_requested", [document])
	assert_eq(_screen.description_label.text, "")


func test_examine_shows_the_description() -> void:
	_player.inventory.add(ROUNDS, 8)
	_player.inventory.add(SHELLS, 4)
	_screen.open()
	_screen.select_tab(ItemData.Category.AMMO)
	_screen.examine_button.pressed.emit()
	assert_eq(_screen.description_label.text, ROUNDS.description)
	# Another item hides it again.
	_screen.select_item(SHELLS)
	assert_eq(_screen.description_label.text, "")


func test_equip_asks_for_the_weapon() -> void:
	_player.inventory.add(_weapon)
	_screen.open()
	watch_signals(_screen)
	_screen.select_tab(ItemData.Category.WEAPON)
	_screen.select_item(_weapon)
	_screen.equip_button.pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "equip_requested", [_weapon])


func test_use_asks_for_the_item() -> void:
	_player.inventory.add(_drink)
	_screen.open()
	watch_signals(_screen)
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.use_button.pressed.emit()
	assert_signal_emitted_with_parameters(_screen, "use_requested", [_drink])


func test_use_does_nothing_on_ammo() -> void:
	_player.inventory.add(ROUNDS, 8)
	_screen.open()
	watch_signals(_screen)
	_screen.select_tab(ItemData.Category.AMMO)
	_screen.use_selected()
	_screen.equip_selected()
	assert_signal_not_emitted(_screen, "use_requested")
	assert_signal_not_emitted(_screen, "equip_requested")


func test_activating_an_item_moves_to_its_first_action() -> void:
	_player.inventory.add(_drink)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.item_list.item_activated.emit(0)
	assert_true(_screen.use_button.has_focus())


func test_cancel_steps_back_from_the_actions_to_the_list() -> void:
	_player.inventory.add(_drink)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.use_button.grab_focus()
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	_screen._unhandled_input(event)
	assert_true(_screen.is_open)
	assert_true(_screen.item_list.has_focus())


func test_the_list_follows_inventory_changes() -> void:
	_player.inventory.add(ROUNDS, 8)
	_player.inventory.add(SHELLS, 4)
	_screen.open()
	_screen.select_tab(ItemData.Category.AMMO)
	_screen.select_item(SHELLS)
	_player.inventory.add(ROUNDS, 8)
	assert_eq(_labels(), ["Pistol rounds ×16", "Shotgun shells ×4"] as Array[String])
	assert_eq(_screen.get_selected_item(), SHELLS)


func test_a_used_up_item_moves_the_selection_and_focus() -> void:
	_player.inventory.add(_drink)
	_screen.open()
	_screen.select_tab(ItemData.Category.HEALING)
	_screen.use_button.grab_focus()
	_player.inventory.remove(_drink)
	assert_eq(_screen.item_list.item_count, 0)
	assert_true(_screen.use_button.disabled)
	assert_true(_screen.item_list.has_focus())
