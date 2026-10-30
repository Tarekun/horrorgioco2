## A place to save, used with `interact`. It opens the save screen, which
## pauses the game. Saving is free and unlimited, and doesn't heal.
##
## While any enemy is chasing the player it refuses with a short message
## instead. A save remembers the spot by `spot_id`, and loading it puts the
## player at `spawn_point`, facing the spot. The look is a placeholder until
## the art work decides one.

class_name SaveSpot
extends Interactable

## Group every save spot joins, so loading can find the one a save names.
const SAVE_SPOT_GROUP: StringName = &"save_spots"

## Shown instead of the save screen while an enemy is chasing the player.
const REFUSAL_MESSAGE: String = "Not now. Something is hunting you."

## The area's name, shown on the save slots.
@export var area_name: String = ""

## Stable id for saves. Left empty, it is the spot's path inside its level.
@export var spot_id: StringName

## Where the player stands after loading a save made here (child).
@export var spawn_point: Node3D


func _ready() -> void:
	super._ready()
	add_to_group(SAVE_SPOT_GROUP)
	prompt = "Save"
	if spot_id.is_empty():
		spot_id = WorldState.default_id(self)


## Opens the save screen for `actor`, or returns the refusal message while an
## enemy is chasing.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	var player := actor as Player
	if player == null or player.save_screen == null:
		return ""
	if is_any_enemy_chasing(get_tree().get_nodes_in_group(Enemy.ENEMY_GROUP)):
		return REFUSAL_MESSAGE
	player.save_screen.open_to_save(SaveSystem.capture(player, self))
	return ""


## The scene file of the level the spot is in, which a save loads again.
func get_level_path() -> String:
	var level: Node = WorldState.level_of(self)
	return level.scene_file_path if level else ""


## Whether any of `enemies` is chasing the player.
static func is_any_enemy_chasing(enemies: Array[Node]) -> bool:
	for node: Node in enemies:
		var enemy := node as Enemy
		if enemy and enemy.is_chasing():
			return true
	return false
