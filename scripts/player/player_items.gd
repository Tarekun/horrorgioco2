## Carries out what the player asks for on the inventory screen.
##
## Use on a healing item heals through the HealthComponent and consumes the
## item; the screen's status readout follows the health change. At full health
## the item is kept and the screen says why. Since the inventory screen pauses
## the game, using an item is instant and safe.

class_name PlayerItems
extends Node

## Shown when a healing item would be wasted.
const FULL_HEALTH_MESSAGE: String = "You don't need that right now."

@export var player: Player
@export var health_component: HealthComponent
@export var inventory_screen: InventoryScreen


func _ready() -> void:
	inventory_screen.use_requested.connect(_on_use_requested)


## Uses one `item` from the inventory. Returns a message for the player, or ""
## when the item was used (or isn't held).
func use_item(item: ItemData) -> String:
	if not player.inventory.has(item) or not item.is_usable():
		return ""
	if item.category == ItemData.Category.HEALING:
		return _heal_with(item)
	return ""


func _heal_with(item: ItemData) -> String:
	if health_component.is_dead:
		return ""
	if health_component.current_health >= health_component.max_health:
		return FULL_HEALTH_MESSAGE
	health_component.heal(item.get_healing(health_component.max_health))
	player.inventory.remove(item)
	return ""


func _on_use_requested(item: ItemData) -> void:
	var message: String = use_item(item)
	if not message.is_empty():
		inventory_screen.show_message(message)
