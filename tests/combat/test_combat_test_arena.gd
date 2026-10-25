## The manual test arena loads with the player and dummies wired.

extends GutTest

const ARENA: PackedScene = preload("res://scenes/levels/combat_test_arena.tscn")


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func test_arena_has_player_and_two_dummies_that_can_be_hit() -> void:
	var arena: Node = ARENA.instantiate()
	add_child_autofree(arena)
	await get_tree().physics_frame
	var player := arena.get_node("Player") as Player
	assert_not_null(player)
	assert_not_null(player.get_node("PlayerCombat"))
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 2)
	var dummy := arena.get_node("TrainingDummy") as TrainingDummy
	assert_eq(dummy.hurtbox.receive_hit(HitData.create(10.0, player)), 10.0)
