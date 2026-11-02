## A document placed in the world: a Pickup that also opens the reader.
##
## Picking it up adds it to the inventory, as any pickup does, then broadcasts
## to DocumentReader.GROUP to open it on the document the moment it's found.
## The reader marks it read; from then on it can be reread from the Documents
## tab of the inventory screen.
##
## A document the level reacts to (the porter's log, which puts the clock back
## on room 22's nightstand) sets `read_flag` when it is picked up and read.

class_name DocumentPickup
extends Pickup

## Set once the document is picked up and read (optional).
@export var read_flag: LevelFlag


func interact(actor: Node3D) -> String:
	var was_collected: bool = is_collected
	var message: String = super.interact(actor)
	if not was_collected and is_collected and item and item.is_document():
		if read_flag:
			read_flag.set_flag()
		get_tree().call_group(DocumentReader.GROUP, &"open", item)
	return message
