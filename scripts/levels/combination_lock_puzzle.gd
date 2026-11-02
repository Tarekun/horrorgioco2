## A combination lock puzzle: a 4-wheel cabinet or door that opens once the
## wheels read `code`, with no penalty for wrong tries.
##
## `interact` opens CombinationLockScreen (broadcast through its group, so the
## puzzle never references the player's screens directly), unless it is
## already solved, when it answers with `already_solved_message` instead. The
## screen calls solve() once the wheels match.
##
## Solving grants the reward: `reward_item` is added to whoever solved it,
## and/or `reward_door` is unlocked. Either, both or neither may be set.
##
## Puzzles are persistent (see WorldState): solving records it in
## SaveSystem.world, and loading a save marks it solved again, without
## granting the reward a second time (the reward itself, an item in the
## inventory or an unlocked door, is saved on its own).

class_name CombinationLockPuzzle
extends Interactable

## Emitted once the puzzle is solved.
signal solved

## The code that opens it, one digit (0-9) per wheel.
@export var code: String = "0000"

## Added to the inventory of whoever solves it (optional).
@export var reward_item: ItemData

## Unlocked when the puzzle is solved (optional).
@export var reward_door: Door

## What interact() answers once it's already solved.
@export var already_solved_message: String = "It's already open."

## Stable id for saves. Left empty, it is the puzzle's path inside its level.
@export var puzzle_id: StringName

var is_solved: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(WorldState.GROUP)
	prompt = "Open"
	if puzzle_id.is_empty():
		puzzle_id = WorldState.default_id(self)


## How many wheels the lock has.
func wheel_count() -> int:
	return code.length()


## Opens the combination lock screen on this puzzle, or answers that it is
## already solved.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if is_solved:
		return already_solved_message
	get_tree().call_group(CombinationLockScreen.GROUP, &"open", self)
	return ""


## Whether `digits` (one 0-9 entry per wheel) match the code.
func matches(digits: Array[int]) -> bool:
	if digits.size() != code.length():
		return false
	for index: int in digits.size():
		if digits[index] != int(code[index]):
			return false
	return true


## Solves the puzzle and grants the reward to `actor`. Returns the message to
## show. Safe to call more than once; later calls just repeat the message.
func solve(actor: Node3D) -> String:
	if is_solved:
		return already_solved_message
	is_solved = true
	var player := actor as Player
	if player and reward_item:
		player.inventory.add(reward_item)
	if reward_door:
		reward_door.unlock()
	SaveSystem.world.record(puzzle_id, {"is_solved": true})
	solved.emit()
	return reward_message()


## The message shown on solving it.
func reward_message() -> String:
	if reward_item:
		return "The lock clicks open. Found %s." % reward_item.display_name
	return "The lock clicks open."


func get_persistent_id() -> StringName:
	return puzzle_id


## Takes back a recorded state: marks the puzzle solved, without granting the
## reward again (the reward is saved on its own: the item in the inventory, or
## the door's own lock state).
func load_state(state: Dictionary) -> void:
	var saved_solved: Variant = state.get("is_solved")
	if saved_solved is bool and saved_solved:
		is_solved = true
