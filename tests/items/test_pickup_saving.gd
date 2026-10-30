## Tests for pickups as persistent objects: recording and loading collection.

extends GutTest

const PICKUP_SCENE: PackedScene = preload("res://scenes/items/pickup.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")

var _player: Player
var _pickup: Pickup


func before_each() -> void:
	SaveSystem.reset()
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_pickup = PICKUP_SCENE.instantiate() as Pickup
	_pickup.item = ROUNDS
	add_child_autofree(_pickup)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func test_is_persistent() -> void:
	assert_true(_pickup.is_in_group(WorldState.GROUP))
	assert_eq(_pickup.get_persistent_id(), _pickup.pickup_id)


func test_picking_up_is_recorded_in_the_world_state() -> void:
	_pickup.interact(_player)
	assert_eq(SaveSystem.world.get_state(_pickup.pickup_id), {"is_collected": true})


func test_a_pickup_left_alone_records_nothing() -> void:
	assert_false(SaveSystem.world.has_state(_pickup.pickup_id))


func test_loading_a_collected_state_removes_it() -> void:
	_pickup.load_state({"is_collected": true})
	assert_true(_pickup.is_collected)
	assert_false(_player.inventory.has(ROUNDS))


func test_loading_another_state_leaves_it() -> void:
	_pickup.load_state({})
	_pickup.load_state({"is_collected": "yes"})
	assert_false(_pickup.is_collected)
