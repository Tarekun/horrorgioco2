## Tests for the player's part of a save.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")
const PIPE: ItemData = preload("res://assets/data/items/steel_pipe.tres")
const PISTOL: ItemData = preload("res://assets/data/items/pistol.tres")

var _player: Player


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	await get_tree().process_frame


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_the_items_node_is_wired() -> void:
	assert_eq(_player.items, _player.get_node("PlayerItems"))


func test_writes_health_inventory_weapon_and_flashlight() -> void:
	_player.health_component.take_damage(35.0)
	_player.inventory.add(ROUNDS, 16)
	_player.inventory.add(PIPE)
	_player.items.equip(PIPE)
	_player.flashlight.set_on(false)
	var save := SaveData.new()
	_player.write_save(save)
	assert_eq(save.player_health, 65.0)
	assert_eq(save.inventory, {"pistol_ammo": 16, "steel_pipe": 1} as Dictionary[String, int])
	assert_eq(save.equipped_weapon, &"steel_pipe")
	assert_eq(save.firearm_magazine, -1, "no firearm held, no magazine saved")
	assert_false(save.is_flashlight_on)


func test_an_unarmed_player_saves_no_weapon() -> void:
	var save := SaveData.new()
	save.equipped_weapon = &"steel_pipe"
	_player.write_save(save)
	assert_eq(save.equipped_weapon, &"")


func test_writes_read_documents() -> void:
	var letter := ItemData.new()
	letter.id = &"doc_letter"
	_player.document_log.mark_read(letter)
	var save := SaveData.new()
	_player.write_save(save)
	assert_eq(save.documents_read, {"doc_letter": true} as Dictionary[String, bool])


func test_a_lit_flashlight_is_saved_on() -> void:
	_player.flashlight.set_on(true)
	var save := SaveData.new()
	save.is_flashlight_on = false
	_player.write_save(save)
	assert_true(save.is_flashlight_on)


func _save_with(health: float, inventory: Dictionary[String, int], weapon: StringName) -> SaveData:
	var save := SaveData.new()
	save.player_health = health
	save.inventory = inventory
	save.equipped_weapon = weapon
	save.is_flashlight_on = false
	return save


func test_reads_health_inventory_weapon_and_flashlight() -> void:
	_player.read_save(
		_save_with(45.0, {"wooden_plank": 1, "steel_pipe": 1, "pistol_ammo": 4}, &"steel_pipe")
	)
	assert_eq(_player.health_component.current_health, 45.0)
	assert_eq(_player.inventory.count(ROUNDS), 4)
	assert_eq(_player.items.equipped_weapon, PIPE)
	assert_false(_player.is_lit())


func test_reading_replaces_what_the_player_carried() -> void:
	_player.inventory.add(ROUNDS, 30)
	_player.read_save(_save_with(100.0, {"wooden_plank": 1}, &"wooden_plank"))
	assert_false(_player.inventory.has(ROUNDS))


func test_reads_documents_read() -> void:
	var save: SaveData = _save_with(100.0, {"wooden_plank": 1}, &"wooden_plank")
	save.documents_read = {"doc_letter": true}
	_player.read_save(save)
	var letter := ItemData.new()
	letter.id = &"doc_letter"
	assert_true(_player.document_log.is_read(letter))


func test_a_round_trip_keeps_the_player() -> void:
	_player.health_component.take_damage(20.0)
	_player.inventory.add(PIPE)
	_player.items.equip(PIPE)
	var letter := ItemData.new()
	letter.id = &"doc_letter"
	_player.document_log.mark_read(letter)
	var save := SaveData.new()
	_player.write_save(save)
	var other := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(other)
	other.read_save(save)
	var copy := SaveData.new()
	other.write_save(copy)
	assert_eq(copy.to_dict(), save.to_dict())


# --- The firearm magazine ---


func test_writes_the_held_firearm_magazine() -> void:
	_player.inventory.add(ROUNDS, 12)
	_player.inventory.add(PISTOL)
	_player.items.equip(PISTOL)
	_player.items.player_firearm.magazine = 6
	var save := SaveData.new()
	_player.write_save(save)
	assert_eq(save.firearm_magazine, 6)


func test_reads_the_firearm_magazine() -> void:
	var save: SaveData = _save_with(100.0, {"pistol": 1, "pistol_ammo": 20}, &"pistol")
	save.firearm_item = &"pistol"
	save.firearm_magazine = 5
	_player.read_save(save)
	assert_eq(_player.items.equipped_weapon, PISTOL)
	assert_eq(_player.items.player_firearm.magazine, 5)


func test_reading_updates_the_magazine_when_the_firearm_is_already_held() -> void:
	_player.inventory.add(ROUNDS, 20)
	_player.inventory.add(PISTOL)
	_player.items.equip(PISTOL)
	_player.items.player_firearm.magazine = 8
	var save: SaveData = _save_with(100.0, {"pistol": 1, "pistol_ammo": 20}, &"pistol")
	save.firearm_item = &"pistol"
	save.firearm_magazine = 2
	_player.read_save(save)
	assert_eq(_player.items.player_firearm.magazine, 2, "not the stale 8")


func test_the_held_firearm_is_restored_with_a_melee_weapon_equipped() -> void:
	# The firearm stays held while the melee weapon is equipped: the save
	# keeps both, and loading puts both back.
	_player.inventory.add(ROUNDS, 20)
	_player.inventory.add(PISTOL)
	_player.inventory.add(PIPE)
	_player.items.equip(PISTOL)
	_player.items.equip(PIPE)
	_player.items.player_firearm.magazine = 4
	var save := SaveData.new()
	_player.write_save(save)
	assert_eq(save.equipped_weapon, &"steel_pipe")
	assert_eq(save.firearm_item, &"pistol")
	assert_eq(save.firearm_magazine, 4)
	var other := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(other)
	other.read_save(save)
	assert_eq(other.items.equipped_weapon, PIPE)
	assert_eq(other.items.player_firearm.current, PISTOL.firearm)
	assert_eq(other.items.player_firearm.magazine, 4)


func test_a_save_without_a_magazine_loads_the_magazine_full() -> void:
	# A save made before firearms have no firearm keys: the equipped
	# firearm starts with a full magazine.
	var data: Dictionary = {
		"level_path": "res://scenes/levels/graybox_level.tscn",
		"player":
		{
			"health": 100.0,
			"inventory": {"pistol": 1, "pistol_ammo": 20},
			"equipped_weapon": "pistol",
			"is_flashlight_on": false,
		},
		"world": {},
	}
	var save: SaveData = SaveData.from_dict(data)
	assert_eq(save.firearm_magazine, -1)
	_player.read_save(save)
	assert_eq(_player.items.player_firearm.magazine, 10)


func test_a_round_trip_keeps_the_held_magazine() -> void:
	_player.inventory.add(ROUNDS, 12)
	_player.inventory.add(PISTOL)
	_player.items.equip(PISTOL)
	_player.items.player_firearm.magazine = 3
	var save := SaveData.new()
	_player.write_save(save)
	var other := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(other)
	other.read_save(save)
	assert_eq(other.items.player_firearm.magazine, 3)


func test_place_at_moves_and_turns_the_player_with_the_camera() -> void:
	var marker := Marker3D.new()
	add_child_autofree(marker)
	marker.global_position = Vector3(4.0, 0.1, -3.0)
	marker.rotation.y = deg_to_rad(90.0)
	_player.place_at(marker)
	assert_almost_eq(_player.global_position, marker.global_position, Vector3.ONE * 0.001)
	assert_almost_eq(_player.rotation.y, deg_to_rad(90.0), 0.001)
	var camera: CameraController = _player.camera_controller
	assert_almost_eq(camera.global_position, marker.global_position, Vector3.ONE * 0.001)
	assert_almost_eq(camera.get_camera_yaw(), deg_to_rad(90.0), 0.001)
	assert_almost_eq(camera.get_camera_pitch(), 0.0, 0.001)
