## The stack of sunbeds on a wheeled rack jammed against the ground floor's
## stairs door (docs/design/slice.md, "The obstacle").
##
## From the corridor it is an interactable: pushing it rolls the stack clear
## along the corridor and emits `moved`, which the level wires to the stairs
## door's unlock(). From the stairs side the player only reaches the locked
## door, whose message says something heavy is on the other side. Once moved,
## the stack stays where it rolled and is no longer an interactable.
##
## It is persistent (see WorldState): moving it records it in SaveSystem.world,
## and loading a save puts the stack straight in its moved place. The door
## saves its own lock.
##
## The level's navmesh is baked with the stack moved (tools/bake_navmesh.gd
## calls place_moved()), the way it stays for the rest of the game. Before
## that, the locked door's navigation link already keeps paths out of the
## doorway the stack blocks.

class_name SunbedsObstacle
extends Interactable

## Emitted when the stack starts rolling clear (not when a save puts it there).
signal moved

## Stable id for saves. Left empty, it is the obstacle's path inside its level.
@export var obstacle_id: StringName

## The stack that rolls, with its collider (child).
@export var stack: Node3D

## Where the stack rolls to, from where it stands, in the obstacle's space.
@export var roll_offset: Vector3 = Vector3(2.0, 0.0, 0.0)

## How long the roll takes, in seconds.
@export var roll_time: float = 1.0

var is_moved: bool = false

var _placed_position: Vector3
var _tween: Tween


func _ready() -> void:
	super._ready()
	add_to_group(WorldState.GROUP)
	if obstacle_id.is_empty():
		obstacle_id = WorldState.default_id(self)
	_placed_position = stack.position


## Rolls the stack clear and reports it. Returns no message.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	if is_moved:
		return ""
	_set_moved()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(stack, "position", moved_position(), roll_time)
	SaveSystem.world.record(obstacle_id, {"is_moved": true})
	moved.emit()
	return ""


## Where the stack stands once moved, in the obstacle's space.
func moved_position() -> Vector3:
	return _placed_position + roll_offset


## Puts the stack in its moved place at once, without rolling or recording it:
## for loading a save and for baking the navmesh.
func place_moved() -> void:
	_set_moved()
	if _tween:
		_tween.kill()
	stack.position = moved_position()


func get_persistent_id() -> StringName:
	return obstacle_id


## Takes back a recorded state: a moved stack is put in its moved place.
func load_state(state: Dictionary) -> void:
	var saved_moved: Variant = state.get("is_moved")
	if saved_moved is bool and saved_moved:
		place_moved()


func _set_moved() -> void:
	is_moved = true
	# Out of reach at once: there is nothing more to do with it.
	remove_from_group(Interactable.GROUP)
