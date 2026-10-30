## Keeps what a save needs while the game runs.
##
## `world` is the live WorldState: persistent objects (pickups, doors, enemies)
## record their changes in it as they happen, and a save stores a copy of it.
## A new game starts it empty.

extends Node

## The state of the current run's persistent objects.
var world := WorldState.new()


## Forgets the current run, for a new game.
func reset() -> void:
	world = WorldState.new()
