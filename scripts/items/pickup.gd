## An item placed in the world, picked up with `interact`.
##
## Pickups are placed by hand and never respawn. A faint glint pulses over each
## one so it can be found in the dark. Picking one up adds its items to the
## player's inventory, shows a short message and removes the pickup.
##
## How many it holds isn't set here: it is the item's standard pickup amount in
## the Scarcity resource (8 pistol rounds, say), times `bundles`.
##
## Every pickup has a persistent id and reports `collected`, so a save can
## record which ones are gone; loading calls mark_collected() on them.

class_name Pickup
extends Interactable

## Emitted when the player picks it up.
signal collected(pickup: Pickup)

## Group every pickup joins, for saving and loading.
const PICKUP_GROUP: StringName = &"pickups"

## What is picked up.
@export var item: ItemData

## How many standard pickups of `item` this one holds (2 for a bigger stash).
@export_range(1, 10) var bundles: int = 1

## Stable id for saves. Left empty, it is the pickup's path inside its level
## (its owner), which holds as long as the level isn't rearranged.
@export var pickup_id: StringName

@export_group("Glint")
## The glint over the item; its material's alpha pulses.
@export var glint: MeshInstance3D
## Glint alpha at the dimmest and brightest point of a pulse.
@export_range(0.0, 1.0) var glint_min_alpha: float = 0.1
@export_range(0.0, 1.0) var glint_max_alpha: float = 0.45
## Seconds per pulse.
@export var glint_period: float = 2.4

var is_collected: bool = false

var _glint_material: StandardMaterial3D
var _glint_time: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(PICKUP_GROUP)
	prompt = "Pick up"
	if pickup_id.is_empty():
		pickup_id = StringName(str(owner.get_path_to(self)) if owner else str(name))
	if glint:
		_glint_material = glint.get_active_material(0) as StandardMaterial3D
		# Desynchronise neighbouring glints.
		_glint_time = randf() * glint_period
		_update_glint()


func _process(delta: float) -> void:
	_glint_time += delta
	_update_glint()


## Adds the item to the player's inventory and removes the pickup. Returns the
## message to show, or "" if `actor` can't carry items.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	var player := actor as Player
	if player == null or item == null or is_collected:
		return ""
	var amount: int = get_amount()
	player.inventory.add(item, amount)
	_remove()
	collected.emit(self)
	return pickup_message(item, amount)


## How many of `item` it holds, from the scarcity in use.
func get_amount() -> int:
	return Scarcity.current().pickup_amount(item) * bundles


## Removes a pickup a save records as collected, without giving the item.
func mark_collected() -> void:
	_remove()


## The message shown on picking up `amount` of `item`.
static func pickup_message(item: ItemData, amount: int) -> String:
	if amount == 1:
		return "Picked up %s." % item.display_name
	return "Picked up %s ×%d." % [item.display_name, amount]


## Glint alpha `time` seconds into the pulse cycle.
static func glint_alpha(time: float, min_alpha: float, max_alpha: float, period: float) -> float:
	var wave: float = 0.5 - 0.5 * cos(TAU * time / maxf(period, 0.001))
	return lerpf(min_alpha, max_alpha, wave)


func _remove() -> void:
	if is_collected:
		return
	is_collected = true
	# Out of reach at once, not at the end of the frame.
	remove_from_group(Interactable.GROUP)
	visible = false
	queue_free()


func _update_glint() -> void:
	if _glint_material:
		_glint_material.albedo_color.a = glint_alpha(
			_glint_time, glint_min_alpha, glint_max_alpha, glint_period
		)
