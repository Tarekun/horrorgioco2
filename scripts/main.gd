## The root of the running game. It stays loaded while screens come and go, and
## hands the node that holds them to GameFlow, which opens the title screen.

class_name Main
extends Node

## Holds the current screen: the title screen or a level.
@export var screen_host: Node


func _ready() -> void:
	GameFlow.attach_host(screen_host)
	GameFlow.go_to_title()
