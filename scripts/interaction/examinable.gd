## Something the player can look at with `interact`: a phone, a clock wall, a
## stopped lift. Each interaction answers with the next line of its
## description; after the last one it starts over. A description left
## unfinished for `restart_after` seconds also starts over, so coming back to
## it later reads it from the top.
##
## Until the dialogue display (#94) exists, the lines are shown on the
## interaction hint, like any interactable's message.
##
## Subclasses can change the description with the world by overriding
## get_lines() (and calling restart() when it changes), and fill in a line as
## it is shown by overriding _show_line().

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
	var description: PackedStringArray = get_lines()
	if description.is_empty():
		return ""
	var now: int = Time.get_ticks_msec()
	if _last_shown_msec >= 0 and now - _last_shown_msec > restart_after * 1000.0:
		_next_line = 0
	_last_shown_msec = now
	if _next_line >= description.size():
		_next_line = 0
	var line: String = _show_line(description[_next_line])
	_next_line = (_next_line + 1) % description.size()
	examined.emit(line)
	return line


## The description right now, one line per interaction. `lines` unless a
## subclass changes it with the world.
func get_lines() -> PackedStringArray:
	return lines


## Makes the next interaction show the first line.
func restart() -> void:
	_next_line = 0


## Whether the next interaction shows the first line.
func is_at_start() -> bool:
	return _next_line == 0


## Called with each line as it is shown; returns the text to show. Override it
## to fill something in.
func _show_line(line: String) -> String:
	return line
