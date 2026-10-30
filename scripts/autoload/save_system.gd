## Keeps what a save needs while the game runs, and the save slots on disk.
##
## `world` is the live WorldState: persistent objects (pickups, doors, enemies)
## record their changes in it as they happen, and a save stores a copy of it.
## `play_time` counts the seconds of play, while a level runs unpaused. A new
## game starts both from zero.
##
## A save spot builds a save with capture() and the save screen writes it with
## write_slot(). Loading one (GameFlow.load_game()) calls begin_from() before
## instancing the save's level and restore() on the fresh level.
##
## `slots` are in user://saves/. On a headless display they are in a separate
## folder, so tests and CI never touch a player's saves.

extends Node

## Where the slots are on a headless display.
const HEADLESS_DIRECTORY: String = "user://headless_saves"

## The state of the current run's persistent objects.
var world := WorldState.new()

## Seconds played in the current run.
var play_time: float = 0.0

## The save slots. Tests replace it.
var slots := SaveSlots.new(
	HEADLESS_DIRECTORY if DisplayServer.get_name() == "headless" else SaveSlots.DEFAULT_DIRECTORY
)


func _process(delta: float) -> void:
	if is_counting_play_time():
		play_time += delta


## Forgets the current run, for a new game.
func reset() -> void:
	world = WorldState.new()
	play_time = 0.0


## A save of the game as it is now, made at `spot` by `player`.
func capture(player: Player, spot: SaveSpot) -> SaveData:
	var save := SaveData.new()
	save.level_path = spot.get_level_path()
	save.area_name = spot.area_name
	save.save_spot_id = spot.spot_id
	save.play_time = play_time
	player.write_save(save)
	save.world = world.copy()
	return save


## Stamps `save` with the time and writes it to `slot`.
func write_slot(slot: int, save: SaveData) -> Error:
	save.timestamp = int(Time.get_unix_time_from_system())
	return slots.write(slot, save)


## Takes the world state and play time of `save` as the current run's.
func begin_from(save: SaveData) -> void:
	world = save.world.copy()
	play_time = save.play_time


## Puts a freshly instanced `level` in the state `save` holds: its persistent
## objects get their recorded states, and the player the saved health,
## inventory, weapon and flashlight, standing at the save spot used.
func restore(level: Node, save: SaveData) -> void:
	world.apply(level)
	var player := _first_in(level, Enemy.PLAYER_GROUP) as Player
	if player == null:
		push_warning("SaveSystem: no player in %s to restore." % level.name)
		return
	player.read_save(save)
	var spot: SaveSpot = find_save_spot(level, save.save_spot_id)
	if spot == null:
		push_warning("SaveSystem: no save spot '%s'; the player stays put." % save.save_spot_id)
		return
	player.place_at(spot.spawn_point if spot.spawn_point else spot)


## The save spot in `level` with `spot_id`, or null.
func find_save_spot(level: Node, spot_id: StringName) -> SaveSpot:
	for node: Node in level.get_tree().get_nodes_in_group(SaveSpot.SAVE_SPOT_GROUP):
		var spot := node as SaveSpot
		if spot and spot.spot_id == spot_id and level.is_ancestor_of(spot):
			return spot
	return null


## Whether play time is running: during play, not while a screen pauses it.
func is_counting_play_time() -> bool:
	return GameFlow.state == GameFlow.State.PLAYING and not get_tree().paused


func _first_in(level: Node, group: StringName) -> Node:
	for node: Node in level.get_tree().get_nodes_in_group(group):
		if level.is_ancestor_of(node):
			return node
	return null
