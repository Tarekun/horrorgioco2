## Carries out what the player asks for on the inventory screen.
##
## Use on a healing item heals through the HealthComponent and consumes the
## item; the screen's status readout follows the health change. At full health
## the item is kept and the screen says why. Since the inventory screen pauses
## the game, using an item is instant and safe.
##
## Equip on a weapon swaps the weapon PlayerCombat swings. Weapons stay in the
## inventory whether held or not; the player starts holding `starting_weapon`,
## or nothing when it is unset (a new game starts unarmed).

class_name PlayerItems
extends Node

## Emitted when another weapon is equipped.
signal weapon_equipped(item: ItemData)

## Shown when a healing item would be wasted.
const FULL_HEALTH_MESSAGE: String = "You don't need that right now."

## The weapon the player starts with, put in the inventory and equipped. Unset
## on the player scene, so a new game starts unarmed; test levels set it.
@export var starting_weapon: ItemData

@export var player: Player
@export var health_component: HealthComponent
@export var combat: PlayerCombat
@export var inventory_screen: InventoryScreen

## The weapon item held, or null.
var equipped_weapon: ItemData


func _ready() -> void:
	inventory_screen.use_requested.connect(_on_use_requested)
	inventory_screen.equip_requested.connect(equip)
	if starting_weapon:
		if not player.inventory.has(starting_weapon):
			player.inventory.add(starting_weapon)
		equip(starting_weapon)


## Equips the weapon `item` from the inventory. Returns false if it isn't held
## or isn't a weapon.
func equip(item: ItemData) -> bool:
	if item == null or item.weapon == null or not player.inventory.has(item):
		return false
	if item != equipped_weapon:
		equipped_weapon = item
		combat.equip(item.weapon)
		inventory_screen.set_equipped(item)
		weapon_equipped.emit(item)
	return true


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
