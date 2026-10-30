## Tests for SaveData: what a save holds and its round trip through JSON.

extends GutTest


func _make_save() -> SaveData:
	var save := SaveData.new()
	save.level_path = "res://scenes/levels/graybox_level.tscn"
	save.area_name = "Lobby"
	save.save_spot_id = &"SaveSpots/Lobby"
	save.play_time = 754.5
	save.timestamp = 1_793_000_000
	save.player_health = 62.5
	save.inventory = {"wooden_plank": 1, "pistol_ammo": 16}
	save.equipped_weapon = &"wooden_plank"
	save.is_flashlight_on = false
	save.world.record(&"Pickups/Ammo", {"is_collected": true})
	save.world.record(
		&"Enemies/Yard",
		{"is_dead": true, "position": WorldState.encode_vector(Vector3(-20.0, 0.0, -4.0))}
	)
	return save


func _through_json(save: SaveData) -> SaveData:
	var parsed: Variant = JSON.parse_string(JSON.stringify(save.to_dict(), "", false))
	return SaveData.from_dict(parsed)


func test_round_trips_through_json() -> void:
	var loaded: SaveData = _through_json(_make_save())
	assert_not_null(loaded)
	assert_eq(loaded.level_path, "res://scenes/levels/graybox_level.tscn")
	assert_eq(loaded.area_name, "Lobby")
	assert_eq(loaded.save_spot_id, &"SaveSpots/Lobby")
	assert_eq(loaded.play_time, 754.5)
	assert_eq(loaded.timestamp, 1_793_000_000)
	assert_eq(loaded.player_health, 62.5)
	assert_eq(loaded.inventory, {"wooden_plank": 1, "pistol_ammo": 16} as Dictionary[String, int])
	assert_eq(loaded.equipped_weapon, &"wooden_plank")
	assert_false(loaded.is_flashlight_on)
	assert_eq(loaded.world.get_state(&"Pickups/Ammo"), {"is_collected": true})
	var enemy: Dictionary = loaded.world.get_state(&"Enemies/Yard")
	assert_eq(WorldState.decode_vector(enemy["position"]), Vector3(-20.0, 0.0, -4.0))


func test_the_inventory_keeps_its_order() -> void:
	var loaded: SaveData = _through_json(_make_save())
	assert_eq(loaded.inventory.keys(), ["wooden_plank", "pistol_ammo"])


func test_the_inventory_goes_back_into_an_inventory() -> void:
	var loaded: SaveData = _through_json(_make_save())
	var inventory := Inventory.new()
	inventory.from_dict(loaded.inventory)
	assert_eq(inventory.count(ItemCatalog.find(&"pistol_ammo")), 16)


func test_a_save_without_a_level_is_rejected() -> void:
	var data: Dictionary = _make_save().to_dict()
	data.erase("level_path")
	assert_null(SaveData.from_dict(data))
	data["level_path"] = ""
	assert_null(SaveData.from_dict(data))
	data["level_path"] = 12
	assert_null(SaveData.from_dict(data))


func test_missing_or_mistyped_values_fall_back_to_defaults() -> void:
	var data: Dictionary = {
		"level_path": "res://level.tscn",
		"area_name": 4,
		"play_time": "long",
		"player": {"health": "full", "inventory": {"pistol_ammo": "lots", "ampoule": 2.0}},
		"world": [],
	}
	var loaded: SaveData = SaveData.from_dict(data)
	assert_not_null(loaded)
	assert_eq(loaded.area_name, "")
	assert_eq(loaded.play_time, 0.0)
	assert_eq(loaded.player_health, 0.0)
	assert_eq(loaded.inventory, {"ampoule": 2} as Dictionary[String, int])
	assert_eq(loaded.equipped_weapon, &"")
	assert_true(loaded.is_flashlight_on)
	assert_true(loaded.world.is_empty())


func test_the_world_is_a_copy_in_the_data() -> void:
	var save: SaveData = _make_save()
	var data: Dictionary = save.to_dict()
	save.world.record(&"Doors/Office", {"is_locked": false})
	assert_false((data["world"] as Dictionary).has("Doors/Office"))
