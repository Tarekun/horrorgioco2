## A document placed in the world: a Pickup that also opens the reader.
##
## Picking it up adds it to the inventory, as any pickup does, then broadcasts
## to DocumentReader.GROUP to open it on the document the moment it's found.
## The reader marks it read; from then on it can be reread from the Documents
## tab of the inventory screen.

class_name DocumentPickup
extends Pickup


func interact(actor: Node3D) -> String:
	var was_collected: bool = is_collected
	var message: String = super.interact(actor)
	if not was_collected and is_collected and item and item.is_document():
		get_tree().call_group(DocumentReader.GROUP, &"open", item)
	return message
