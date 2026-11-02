## A button of the lift, or its doors: something the player presses that the
## lift handles. It reports every press with `interacted` and answers with
## `answer`, which its LiftStop sets (*Out of order.* until the power is back).

class_name LiftButton
extends Interactable

## The floor this button sends the lift to, for the buttons inside the car:
## 0 is GF, 1 is 1F, 2 is 2F. -1 for the call button and the doors.
@export var floor_index: int = -1

## What pressing it says, or "" for nothing.
var answer: String = ""


## Presses the button. Returns `answer`.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	return answer
