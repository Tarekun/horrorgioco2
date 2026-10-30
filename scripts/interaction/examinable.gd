## Something the player can look at with `interact`: a phone, a clock wall, a
## stopped lift. Each interaction answers with the next line of its
## description; after the last one it starts over. A description left
## unfinished for `restart_after` seconds also starts over, so coming back to
## it later reads it from the top.
##
## Until the dialogue display (#94) exists, the lines are shown on the
## interaction hint, like any interactable's message.

class_name Examinable
extends Interactable

## Emitted with each line shown.
signal examined(line: String)

## The description, one line per interaction.
@export_multiline var lines: PackedStringArray = []

## Seconds after which an unfinished description starts over.
@export var restart_after: float = 8.0

var _next_line: int = 0
var _last_shown_msec: int = -1


func _ready() -> void:
	super._ready()
	prompt = "Examine"


## Shows the next line of the description. Returns it, or "" if there are none.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if lines.is_empty():
		return ""
	var now: int = Time.get_ticks_msec()
	if _last_shown_msec >= 0 and now - _last_shown_msec > restart_after * 1000.0:
		_next_line = 0
	_last_shown_msec = now
	var line: String = lines[_next_line]
	_next_line = (_next_line + 1) % lines.size()
	examined.emit(line)
	return line


## Whether the next interaction shows the first line.
func is_at_start() -> bool:
	return _next_line == 0
