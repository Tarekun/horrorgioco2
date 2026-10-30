## A door between rooms, opened and closed with `interact`.
##
## The panel swings on a hinge, away from the player who opens it. Closed, its
## collider blocks the doorway for the player, enemies and sight. A locked door
## answers with a message and stays shut until unlock() is called. If it has a
## `key_id`, a player carrying that key item unlocks it by trying it: the door
## opens and says the key was used. Keys are kept, since one may open several
## doors.
##
## Doors are persistent (see WorldState): lock() and unlock() record the lock
## in SaveSystem.world, and loading a save locks or unlocks the door again.
##
## Enemies can't open doors: the navigation link through the doorway is enabled
## only while the door is open, so pathing respects closed doors. The level's
## navmesh is baked with the doors shut (see tools/bake_navmesh.gd).

class_name Door
extends Interactable

## Emitted when the door starts opening.
signal opened
## Emitted when the door starts closing.
signal closed
## Emitted when the player tries a locked door.
signal locked_attempted
## Emitted when a player's key unlocks the door.
signal unlocked_with_key(key: ItemData)

## Whether the door refuses to open.
@export var is_locked: bool = false

## What the player is told when the door is locked.
@export var locked_message: String = "It's locked."

## Id of the key item (ItemData.id) that unlocks it. Empty: no key does.
@export var key_id: StringName

## How far the panel swings open, in degrees, and how long it takes.
@export var open_angle: float = 100.0
@export var swing_time: float = 0.5

## Stable id for saves. Left empty, it is the door's path inside its level.
@export var door_id: StringName

## The hinge the panel rotates on (child).
@export var hinge: Node3D

## Lets enemies path through the doorway while the door is open (child).
@export var navigation_link: NavigationLink3D

var is_open: bool = false

var _tween: Tween


func _ready() -> void:
	super._ready()
	add_to_group(WorldState.GROUP)
	prompt = "Open"
	navigation_link.enabled = false
	if door_id.is_empty():
		door_id = WorldState.default_id(self)


func get_prompt() -> String:
	return "Close" if is_open else "Open"


## Opens or closes the door, or reports that it is locked.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if is_open:
		close()
		return ""
	var message: String = ""
	if is_locked:
		var player := actor as Player
		var key: ItemData = find_key(player.inventory, key_id) if player else null
		if key == null:
			locked_attempted.emit()
			return locked_message
		unlock()
		unlocked_with_key.emit(key)
		message = used_key_message(key)
	open(actor.global_position if actor else global_position + global_basis.z)
	return message


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
	_record()


func unlock() -> void:
	is_locked = false
	_record()


func get_persistent_id() -> StringName:
	return door_id


## Takes back a recorded state: locks or unlocks the door.
func load_state(state: Dictionary) -> void:
	var saved_lock: Variant = state.get("is_locked")
	if not saved_lock is bool:
		return
	if saved_lock:
		lock()
	else:
		unlock()


## The item with id `key` in `inventory`, or null if it isn't there (or `key`
## is empty).
static func find_key(inventory: Inventory, key: StringName) -> ItemData:
	if key.is_empty():
		return null
	for item: ItemData in inventory.get_items():
		if item.id == key:
			return item
	return null


## The message shown on unlocking a door with `key`.
static func used_key_message(key: ItemData) -> String:
	return "Used %s." % key.display_name


func _record() -> void:
	SaveSystem.world.record(door_id, {"is_locked": is_locked})


func _swing_to(angle: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(hinge, "rotation:y", angle, swing_time)
