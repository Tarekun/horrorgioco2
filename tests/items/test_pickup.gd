## Tests for pickups: collecting, messages, save ids and the glint.

extends GutTest

const PICKUP_SCENE: PackedScene = preload("res://scenes/items/pickup.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/graybox_level.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")

var _player: Player
var _pickup: Pickup


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_pickup = _make_pickup(ROUNDS, 8)
	# In front of the player (who faces -Z).
	_pickup.position = Vector3(0, 0, -1.0)
	add_child_autofree(_pickup)
	await get_tree().physics_frame


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _make_pickup(item: ItemData, amount: int) -> Pickup:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.item = item
	pickup.amount = amount
	return pickup


func test_is_an_interactable_and_a_pickup() -> void:
	assert_true(_pickup.is_in_group(Interactable.GROUP))
	assert_true(_pickup.is_in_group(Pickup.PICKUP_GROUP))
	assert_eq(_pickup.get_prompt(), "Pick up")


func test_picking_up_adds_to_the_inventory() -> void:
	_pickup.interact(_player)
	assert_eq(_player.inventory.count(ROUNDS), 8)


func test_picking_up_removes_the_pickup() -> void:
	_pickup.interact(_player)
	assert_true(_pickup.is_collected)
	assert_false(_pickup.visible)
	assert_false(_pickup.is_in_group(Interactable.GROUP))
	assert_true(_pickup.is_queued_for_deletion())


func test_picking_up_returns_a_message() -> void:
	assert_eq(_pickup.interact(_player), "Picked up Pistol rounds ×8.")


func test_a_single_item_message_has_no_count() -> void:
	assert_eq(Pickup.pickup_message(ROUNDS, 1), "Picked up Pistol rounds.")


func test_picking_up_reports_collected() -> void:
	watch_signals(_pickup)
	_pickup.interact(_player)
	assert_signal_emitted_with_parameters(_pickup, "collected", [_pickup])


func test_it_can_be_picked_up_only_once() -> void:
	_pickup.interact(_player)
	assert_eq(_pickup.interact(_player), "")
	assert_eq(_player.inventory.count(ROUNDS), 8)


func test_only_the_player_picks_up() -> void:
	var other := Node3D.new()
	add_child_autofree(other)
	assert_eq(_pickup.interact(other), "")
	assert_false(_pickup.is_collected)


func test_mark_collected_removes_it_without_giving_the_item() -> void:
	watch_signals(_pickup)
	_pickup.mark_collected()
	assert_true(_pickup.is_collected)
	assert_true(_pickup.is_queued_for_deletion())
	assert_signal_not_emitted(_pickup, "collected")
	assert_true(_player.inventory.is_empty())


func test_the_id_defaults_to_the_path_in_its_level() -> void:
	var level := Node3D.new()
	var stash := Node3D.new()
	stash.name = "Stash"
	level.add_child(stash)
	stash.owner = level
	var pickup := _make_pickup(ROUNDS, 8)
	pickup.name = "Rounds"
	stash.add_child(pickup)
	pickup.owner = level
	add_child_autofree(level)
	assert_eq(pickup.pickup_id, &"Stash/Rounds")


func test_an_explicit_id_is_kept() -> void:
	var pickup := _make_pickup(ROUNDS, 8)
	pickup.pickup_id = &"office_rounds"
	add_child_autofree(pickup)
	assert_eq(pickup.pickup_id, &"office_rounds")


func test_the_player_picks_it_up_with_interact() -> void:
	var interaction := _player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, _pickup)
	assert_true(interaction.interact())
	assert_eq(_player.inventory.count(ROUNDS), 8)
	assert_eq(interaction.hint.message_label.text, "Picked up Pistol rounds ×8.")
	await get_tree().physics_frame
	interaction.update_focus()
	assert_null(interaction.focus)
	assert_false(interaction.hint.prompt_label.visible)


func test_the_glint_pulses_between_its_limits() -> void:
	assert_almost_eq(Pickup.glint_alpha(0.0, 0.1, 0.5, 2.0), 0.1, 0.001)
	assert_almost_eq(Pickup.glint_alpha(1.0, 0.1, 0.5, 2.0), 0.5, 0.001)
	assert_almost_eq(Pickup.glint_alpha(2.0, 0.1, 0.5, 2.0), 0.1, 0.001)
	assert_almost_eq(Pickup.glint_alpha(0.5, 0.1, 0.5, 2.0), 0.3, 0.001)


func test_the_glint_is_a_faint_unshaded_billboard() -> void:
	var material := _pickup.glint.get_active_material(0) as StandardMaterial3D
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_eq(material.billboard_mode, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_eq(_pickup.glint.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_between(material.albedo_color.a, _pickup.glint_min_alpha, _pickup.glint_max_alpha)
	assert_lte(_pickup.glint_max_alpha, 0.5)


func test_each_pickup_has_its_own_glint() -> void:
	var other := _make_pickup(ROUNDS, 8)
	add_child_autofree(other)
	assert_ne(other.glint.get_active_material(0), _pickup.glint.get_active_material(0))


func test_the_level_pickups_have_items_and_unique_ids() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	add_child_autofree(level)
	var ids: Array[StringName] = []
	for node: Node in level.get_node("Pickups").get_children():
		var pickup := node as Pickup
		assert_not_null(pickup, "%s is not a pickup" % node.name)
		if pickup:
			assert_not_null(pickup.item, "%s has no item" % node.name)
			assert_gt(pickup.amount, 0, node.name)
			assert_false(ids.has(pickup.pickup_id), "%s reuses an id" % node.name)
			ids.append(pickup.pickup_id)
	assert_gt(ids.size(), 0)
