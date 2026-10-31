## The button on the wall beside a RollerShutter. It does nothing until its
## `power_flag` is set: before, it answers "Nothing happens." and keeps its
## prompt, so the player knows it matters. With the power back it raises the
## shutter.
##
## Once the shutter is up, live or from a loaded save, the button stops being
## an interactable, so its prompt doesn't show again. It records nothing
## itself: the shutter keeps its own state.

class_name ShutterButton
extends Interactable

const PROMPT: String = "Press the button."
const NO_POWER_MESSAGE: String = "Nothing happens."

## The flag that powers the button (the hotel's `power_restored`).
@export var power_flag: LevelFlag

## The shutter the button raises.
@export var shutter: RollerShutter


func _ready() -> void:
	super._ready()
	prompt = PROMPT
	if shutter == null:
		push_warning("ShutterButton %s has no shutter." % name)
		return
	shutter.raised.connect(_on_shutter_raised)
	if shutter.is_up:
		_on_shutter_raised(true)


## Raises the shutter if the power is back, or says nothing happens.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if not is_powered():
		return NO_POWER_MESSAGE
	if shutter:
		shutter.raise()
	return ""


## Whether the power is back, so the button works.
func is_powered() -> bool:
	return power_flag != null and power_flag.is_set


func _on_shutter_raised(_is_loaded: bool) -> void:
	remove_from_group(Interactable.GROUP)
