## Keeps what a save needs while the game runs, and the save slots on disk.
##
## `world` is the live WorldState: persistent objects (pickups, doors, enemies)
## record their changes in it as they happen, and a save stores a copy of it.
## `play_time` counts the seconds of play, while a level runs unpaused. A new
## game starts both from zero.
##
## A save spot builds a save with capture() and the save screen writes it with
## write_slot().
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


## Whether play time is running: during play, not while a screen pauses it.
func is_counting_play_time() -> bool:
	return GameFlow.state == GameFlow.State.PLAYING and not get_tree().paused
