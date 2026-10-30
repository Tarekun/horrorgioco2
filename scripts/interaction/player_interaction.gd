## Lets the player use the nearest interactable.
##
## Each physics frame it picks the interactable within `interact_range` metres
## in front of the player and shows its prompt, only while one is in range.
## The `interact` action uses it; a message the interactable returns (a locked
## door's) is shown on the hint.

class_name PlayerInteraction
extends Node

## Emitted when the interactable in range changes (null when none).
signal focus_changed(interactable: Interactable)

## How close (metres) an interactable must be.
@export var interact_range: float = 1.5

## Half angle (degrees) around the player's facing in which one counts as in front.
@export var interact_angle: float = 80.0

## How far above or below the player (metres) one may be. Keeps a door on the
## floor below, in the same spot, from being picked.
@export var interact_height: float = 2.0

@export var player: Player
@export var hint: InteractionHint

## The interactable in range, or null.
var focus: Interactable


func _physics_process(_delta: float) -> void:
	update_focus()
	if Input.is_action_just_pressed(&"interact"):
		interact()


## Picks the interactable in range and updates the prompt.
func update_focus() -> void:
	var picked: Interactable = null
	if _can_interact():
		picked = _pick()
	if picked == focus:
		if focus and hint:
			hint.show_prompt(focus.get_prompt())
		return
	focus = picked
	if hint:
		if focus:
			hint.show_prompt(focus.get_prompt())
		else:
			hint.hide_prompt()
	focus_changed.emit(focus)


## Uses the interactable in range, if any. Returns whether there was one.
func interact() -> bool:
	if not _can_interact() or focus == null:
		return false
	var message: String = focus.interact(player)
	if hint and not message.is_empty():
		hint.show_message(message)
	return true


func _can_interact() -> bool:
	return not player.health_component.is_dead and not player.is_movement_locked


func _pick() -> Interactable:
	var candidates: Array[Interactable] = []
	var positions: Array[Vector3] = []
	for node: Node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var interactable := node as Interactable
		if interactable:
			candidates.append(interactable)
			positions.append(interactable.global_position)
	var forward: Vector3 = -player.global_basis.z
	var index: int = SoftTargeting.pick(
		player.global_position, forward, positions, interact_range, interact_angle, interact_height
	)
	return candidates[index] if index >= 0 else null
