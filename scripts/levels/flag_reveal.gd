## Keeps a node hidden until a LevelFlag is set, live or from a save: the flip
## clock on room 22's nightstand, which is back once the porter's log is read.
##
## It sits apart from what it shows, so the target can be a prop that
## tools/dress_hotel.gd rebuilds.

class_name FlagReveal
extends Node

## The flag that reveals the target.
@export var flag: LevelFlag

## What stays hidden until the flag is set.
@export var target: Node3D


func _ready() -> void:
	flag.flag_set.connect(_on_flag_set)
	target.visible = flag.is_set


func _on_flag_set(_is_loaded: bool) -> void:
	target.visible = true
