## Definition of an item the player can carry: what it is called, which tab of
## the inventory screen it belongs to and how it is described.
##
## One resource per item lives in assets/data/items/, named after its id
## (pistol_ammo.tres has the id pistol_ammo). Saves store the id, and
## ItemCatalog turns it back into the item.

class_name ItemData
extends Resource

## The inventory screen's tabs.
enum Category { WEAPON, AMMO, HEALING, KEY_ITEM, DOCUMENT }

## Unique, stable id, used in saves. Never rename one that has shipped.
@export var id: StringName

@export var display_name: String

@export var category: Category = Category.KEY_ITEM

## What the player reads when examining the item.
@export_multiline var description: String

## Picture shown on the inventory screen (optional).
@export var icon: Texture2D

@export_group("Weapon")
## The melee weapon a weapon item equips.
@export var weapon: MeleeWeapon

@export_group("Healing")
## Health a healing item restores.
@export var heal_amount: float = 0.0
## Restores all health, whatever `heal_amount` says.
@export var is_full_heal: bool = false


## Whether the inventory screen offers Equip for it: weapons.
func is_equippable() -> bool:
	return category == Category.WEAPON


## Whether the inventory screen offers Use for it: healing items.
func is_usable() -> bool:
	return category == Category.HEALING


## Health this item restores to someone with `max_health`.
func get_healing(max_health: float) -> float:
	return max_health if is_full_heal else heal_amount
