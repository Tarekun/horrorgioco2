## The tap of room 21's shower, which runs by itself (tension_shower). It can be
## used only while the shower runs: turn_on() when the event fires, and
## `interact` turns it off again, emitting `turned_off` for the event's sound and
## steam to stop.

class_name ShowerTap
extends Interactable

## Emitted when the player turns the shower off.
signal turned_off

## Whether the shower is running.
var is_running: bool = false


func _ready() -> void:
	super._ready()
	prompt = "Turn off"
	remove_from_group(GROUP)


## Sets the shower running, which makes the tap usable.
func turn_on() -> void:
	is_running = true
	add_to_group(GROUP)


## Turns the shower off. Returns no message.
func interact(actor: Node3D) -> String:
	if not is_running:
		return ""
	is_running = false
	remove_from_group(GROUP)
	interacted.emit(actor)
	turned_off.emit()
	return ""
