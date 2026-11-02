## A tension action that shows nodes hidden until the event fires: the flame of a
## lit stove. stop() hides them again.

class_name TensionReveal
extends TensionAction

## What to show, each left hidden in the scene.
@export var targets: Array[Node3D] = []


func _start() -> void:
	_set_shown(true)


func _end() -> void:
	_set_shown(false)


func _set_shown(is_shown: bool) -> void:
	for target: Node3D in targets:
		if target:
			target.visible = is_shown
