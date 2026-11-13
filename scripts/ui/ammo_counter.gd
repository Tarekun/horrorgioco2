## The small magazine count shown while aiming, centred a little below the
## screen centre (next to where the reticle will be): "magazine / reserve".
## Nothing at all is shown when not aiming.

class_name AmmoCounter
extends Node

## The count to show, e.g. "7 / 24".
@export var shows_count: bool = false:
	set(value):
		shows_count = value
		if _label:
			_label.visible = value

@onready var _label: Label = $Label


func _ready() -> void:
	shows_count = false
	_label.text = ""


## Shows the magazine and reserve counts.
func show_count(magazine: int, reserve: int) -> void:
	_label.text = "%d / %d" % [magazine, reserve]
	shows_count = true


## Hides the count.
func hide_count() -> void:
	shows_count = false
