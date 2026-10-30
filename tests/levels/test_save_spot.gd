## Tests for save spots: opening the save screen, refusing during a chase and
## what the save they make holds.

extends GutTest

const SPOT_SCENE: PackedScene = preload("res://scenes/levels/save_spot.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/graybox_level.tscn")
const LEVEL_PATH: String = "res://scenes/levels/graybox_level.tscn"
const DIRECTORY: String = "user://test_save_spot"

var _player: Player
var _spot: SaveSpot
var _previous_state: GameFlow.State
var _previous_slots: SaveSlots


func before_each() -> void:
	_previous_state = GameFlow.state
	_previous_slots = SaveSystem.slots
	SaveSystem.slots = SaveSlots.new(DIRECTORY)
	GameFlow.state = GameFlow.State.PLAYING
	SaveSystem.reset()
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_spot = SPOT_SCENE.instantiate() as SaveSpot
	_spot.area_name = "Lobby"
	# In front of the player (who faces -Z).
	_spot.position = Vector3(0, 0, -1.0)
	add_child_autofree(_spot)
	await get_tree().physics_frame


func after_each() -> void:
	for slot: int in SaveSlots.SLOT_COUNT:
		SaveSystem.slots.delete(slot)
	DirAccess.remove_absolute(DIRECTORY)
	SaveSystem.slots = _previous_slots
	GameFlow.state = _previous_state
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _spawn_enemy() -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = Vector3(0, 0, -20.0)
	add_child_autofree(enemy)
	return enemy


func test_is_an_interactable_with_a_save_prompt() -> void:
	assert_true(_spot.is_in_group(Interactable.GROUP))
	assert_true(_spot.is_in_group(SaveSpot.SAVE_SPOT_GROUP))
	assert_eq(_spot.get_prompt(), "Save")
	assert_eq(_spot.spot_id, WorldState.default_id(_spot))
	assert_not_null(_spot.spawn_point)


func test_the_spawn_point_is_in_front_of_the_spot_facing_it() -> void:
	var to_spot: Vector3 = _spot.global_position - _spot.spawn_point.global_position
	to_spot.y = 0.0
	assert_between(to_spot.length(), 0.5, 1.4)
	var facing: Vector3 = -_spot.spawn_point.global_basis.z
	assert_gt(facing.dot(to_spot.normalized()), 0.99)


func test_the_player_has_a_save_screen() -> void:
	assert_eq(_player.save_screen, _player.get_node("SaveScreen"))


func test_using_it_opens_the_save_screen_and_pauses() -> void:
	assert_eq(_spot.interact(_player), "")
	assert_true(_player.save_screen.is_open)
	assert_eq(_player.save_screen.mode, SaveScreen.Mode.SAVE)
	assert_true(get_tree().paused)


func test_the_player_uses_it_with_interact() -> void:
	var interaction := _player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, _spot)
	assert_true(interaction.interact())
	assert_true(_player.save_screen.is_open)


func test_the_save_holds_the_spot_area_and_player() -> void:
	_player.health_component.take_damage(30.0)
	SaveSystem.play_time = 90.0
	SaveSystem.world.record(&"Pickups/Ammo", {"is_collected": true})
	var save: SaveData = SaveSystem.capture(_player, _spot)
	assert_eq(save.area_name, "Lobby")
	assert_eq(save.save_spot_id, _spot.spot_id)
	assert_eq(save.play_time, 90.0)
	assert_eq(save.player_health, 70.0)
	assert_eq(save.equipped_weapon, &"wooden_plank")
	assert_eq(save.world.get_state(&"Pickups/Ammo"), {"is_collected": true})


func test_the_save_keeps_a_copy_of_the_world() -> void:
	var save: SaveData = SaveSystem.capture(_player, _spot)
	SaveSystem.world.record(&"Doors/Office", {"is_locked": false})
	assert_false(save.world.has_state(&"Doors/Office"))


func test_the_save_names_the_level_the_spot_is_in() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	add_child_autofree(level)
	var spot := level.get_node("SaveSpots/SaveSpotLobby") as SaveSpot
	assert_eq(spot.get_level_path(), LEVEL_PATH)
	assert_eq(spot.spot_id, &"SaveSpots/SaveSpotLobby")
	assert_eq(SaveSystem.capture(_player, spot).level_path, LEVEL_PATH)


func test_saving_doesnt_heal() -> void:
	_player.health_component.take_damage(30.0)
	_spot.interact(_player)
	_player.save_screen.choose_slot(0)
	assert_eq(_player.health_component.current_health, 70.0)


func test_refuses_while_an_enemy_is_chasing() -> void:
	var enemy: Enemy = _spawn_enemy()
	enemy.perception.alert_to(_player.global_position)
	assert_true(enemy.is_chasing())
	assert_eq(_spot.interact(_player), SaveSpot.REFUSAL_MESSAGE)
	assert_false(_player.save_screen.is_open)
	assert_false(get_tree().paused)


func test_the_refusal_shows_on_the_hint() -> void:
	_spawn_enemy().perception.alert_to(_player.global_position)
	var interaction := _player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	interaction.interact()
	assert_eq(interaction.hint.message_label.text, SaveSpot.REFUSAL_MESSAGE)


func test_calm_enemies_dont_stop_saving() -> void:
	_spawn_enemy()
	_spot.interact(_player)
	assert_true(_player.save_screen.is_open)


func test_downed_or_dead_enemies_arent_chasing() -> void:
	var enemy: Enemy = _spawn_enemy()
	enemy.perception.alert_to(_player.global_position)
	enemy.brain.knock_down(10.0)
	assert_false(enemy.is_chasing())
	assert_false(SaveSpot.is_any_enemy_chasing([enemy] as Array[Node]))
	enemy.brain.kill()
	assert_false(enemy.is_chasing())


func test_only_the_player_can_save() -> void:
	var stranger := Node3D.new()
	add_child_autofree(stranger)
	assert_eq(_spot.interact(stranger), "")
	assert_false(_player.save_screen.is_open)


func test_the_graybox_lobby_has_a_save_spot() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	add_child_autofree(level)
	var spots: Array[Node] = level.get_node("SaveSpots").get_children()
	assert_gt(spots.size(), 0)
	for node: Node in spots:
		var spot := node as SaveSpot
		assert_not_null(spot, "%s is not a save spot" % node.name)
		if spot:
			assert_false(spot.area_name.is_empty(), "%s has no area name" % node.name)
