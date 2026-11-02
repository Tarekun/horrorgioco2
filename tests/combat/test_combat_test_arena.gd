## The manual test arena loads with the player and dummies wired.

extends GutTest

const ARENA: PackedScene = preload("res://scenes/levels/combat_test_arena.tscn")
const PLANK: ItemData = preload("res://assets/data/items/wooden_plank.tres")


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_arena_has_player_and_two_dummies_and_an_enemy() -> void:
	var arena: Node = ARENA.instantiate()
	add_child_autofree(arena)
	await get_tree().physics_frame
	var player := arena.get_node("Player") as Player
	assert_not_null(player)
	assert_not_null(player.get_node("PlayerCombat"))
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 3)
	var dummy := arena.get_node("TrainingDummy") as TrainingDummy
	assert_eq(dummy.hurtbox.receive_hit(HitData.create(10.0, player)), 10.0)


func test_the_player_starts_armed_with_the_plank() -> void:
	var arena: Node = ARENA.instantiate()
	add_child_autofree(arena)
	var player := arena.get_node("Player") as Player
	assert_eq(player.items.equipped_weapon, PLANK)
	assert_eq((player.get_node("PlayerCombat") as PlayerCombat).weapon, PLANK.weapon)
