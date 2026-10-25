## A door between rooms, opened and closed with `interact`.
##
## The panel swings on a hinge, away from the player who opens it. Closed, its
## collider blocks the doorway for the player, enemies and sight. A locked door
## answers with a message and stays shut until unlock() is called.
##
## Enemies can't open doors: the navigation link through the doorway is enabled
## only while the door is open, so pathing respects closed doors. The level's
## navmesh is baked with the doors shut (see tools/bake_graybox_navmesh.gd).

class_name Door
extends Interactable

## Emitted when the door starts opening.
signal opened
## Emitted when the door starts closing.
signal closed
## Emitted when the player tries a locked door.
signal locked_attempted

## Whether the door refuses to open.
@export var is_locked: bool = false

## What the player is told when the door is locked.
@export var locked_message: String = "It's locked."

## How far the panel swings open, in degrees, and how long it takes.
@export var open_angle: float = 100.0
@export var swing_time: float = 0.5

## The hinge the panel rotates on (child).
@export var hinge: Node3D

## Lets enemies path through the doorway while the door is open (child).
@export var navigation_link: NavigationLink3D

var is_open: bool = false

var _tween: Tween


func _ready() -> void:
	super._ready()
	prompt = "Open"
	navigation_link.enabled = false


func get_prompt() -> String:
	return "Close" if is_open else "Open"


## Opens or closes the door, or reports that it is locked.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if is_open:
		close()
		return ""
	if is_locked:
		locked_attempted.emit()
		return locked_message
	open(actor.global_position if actor else global_position + global_basis.z)
	return ""


## Opens the door, swinging away from `from` (the opener's position).
func open(from: Vector3) -> void:
	if is_open or is_locked:
		return
	is_open = true
	navigation_link.enabled = true
	var side: float = signf(global_basis.z.dot(from - global_position))
	_swing_to(deg_to_rad(open_angle) * (side if side != 0.0 else 1.0))
	opened.emit()


## Closes the door.
func close() -> void:
	if not is_open:
		return
	is_open = false
	navigation_link.enabled = false
	_swing_to(0.0)
	closed.emit()


func lock() -> void:
	if is_open:
		close()
	is_locked = true


func unlock() -> void:
	is_locked = false


func _swing_to(angle: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(hinge, "rotation:y", angle, swing_time)
