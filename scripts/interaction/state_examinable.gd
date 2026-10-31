## An Examinable whose description changes once, when the world does: the lift
## before and after the power, the nightstand in room 22 before and after the
## porter's log is read, a chained door before and after it is unlocked.
##
## Its state is a saved LevelFlag being set (`flag`) or, without a flag, a
## Door being unlocked (`door`). Until then it reads `lines`; from then on
## `lines_after`. The first look after the change starts from the top.
##
## `shown` can also limit it to one side of the change: the lobby desk is only
## examinable once the power is back, the roller shutter only before. This
## needs a flag, since it follows the flag's `flag_set` (live or loaded).

class_name StateExaminable
extends Examinable

## When it can be examined.
enum Shown { ALWAYS, BEFORE, AFTER }

## The flag that changes it (e.g. `power_restored`). Takes precedence over
## `door`.
@export var flag: LevelFlag

## Without a flag, the door whose unlocking changes it.
@export var door: Door

## The description once the state has changed. Left empty, it keeps `lines`.
@export_multiline var lines_after: PackedStringArray = []

## When it can be examined: always, only before the change, or only after.
@export var shown: Shown = Shown.ALWAYS

var _was_changed: bool = false


func _ready() -> void:
	super._ready()
	if flag:
		flag.flag_set.connect(_on_flag_set)
	elif shown != Shown.ALWAYS:
		push_warning("StateExaminable %s needs a flag to be shown before or after." % name)
	_was_changed = is_changed()
	_update_shown()


## Shows the next line of the description that fits the state.
func interact(actor: Node3D) -> String:
	var changed: bool = is_changed()
	if changed != _was_changed:
		_was_changed = changed
		restart()
	return super.interact(actor)


## Whether the state has changed: the flag is set, or the door unlocked.
func is_changed() -> bool:
	if flag:
		return flag.is_set
	if door:
		return not door.is_locked
	return false


## `lines_after` once the state has changed (if it has any), `lines` before.
func get_lines() -> PackedStringArray:
	if is_changed() and not lines_after.is_empty():
		return lines_after
	return lines


## Whether it can be examined now.
func is_shown() -> bool:
	match shown:
		Shown.BEFORE:
			return not is_changed()
		Shown.AFTER:
			return is_changed()
	return true


func _update_shown() -> void:
	if is_shown():
		add_to_group(Interactable.GROUP)
	else:
		remove_from_group(Interactable.GROUP)


func _on_flag_set(_is_loaded: bool) -> void:
	_update_shown()
