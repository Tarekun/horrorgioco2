## A one-shot scripted scare from slice.md's Tension table: when its trigger goes
## off, it runs every TensionAction among its children, once.
##
## It fires once per level load and saves nothing, so loading a save plays it
## again. Its actions are sound and light only: none may hurt the player or make a
## noise enemies hear (NoiseEvent), so above ground nothing ever pays off.

class_name TensionEvent
extends Node3D

## Emitted the one time the event fires.
signal fired

## Group every tension event joins.
const GROUP: StringName = &"tension_events"

## The event's id from slice.md, e.g. `tension_shower`.
@export var event_id: StringName

## What sets it off. Left empty, it is the first TensionTrigger child; other
## triggers among the children are free for the actions to use (a phone that
## stops ringing as the player reaches its door).
@export var trigger: TensionTrigger

## Whether it has fired since the level loaded.
var has_fired: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	if trigger == null:
		for child: Node in get_children():
			if child is TensionTrigger:
				trigger = child as TensionTrigger
				break
	if trigger:
		trigger.triggered.connect(fire)


## Runs the event's actions, the first time only. Returns whether it ran.
func fire() -> bool:
	if has_fired:
		return false
	has_fired = true
	if trigger:
		trigger.disarm()
	for action: TensionAction in get_actions():
		action.run()
	fired.emit()
	return true


## The actions it runs: its TensionAction children, in order.
func get_actions() -> Array[TensionAction]:
	var actions: Array[TensionAction] = []
	for child: Node in get_children():
		if child is TensionAction:
			actions.append(child as TensionAction)
	return actions
