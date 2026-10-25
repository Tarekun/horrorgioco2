## Something the player can use with `interact`: a door, a pickup, a save spot.
##
## It sits at the point the player has to stand near. Subclasses override
## interact() and may return a message for the hint to show.

class_name Interactable
extends Node3D

## Emitted when the player uses it.
signal interacted(actor: Node3D)

## Group every interactable joins; PlayerInteraction looks in it.
const GROUP: StringName = &"interactables"

## What the on-screen prompt says while the player is in range.
@export var prompt: String = "Use"


func _ready() -> void:
	add_to_group(GROUP)


## The prompt to show right now.
func get_prompt() -> String:
	return prompt


## Uses the interactable. Returns a message to show the player, or "".
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	return ""
