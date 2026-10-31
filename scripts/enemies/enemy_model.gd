## The standard enemy's body (see CharacterModel): the same humanoid rig as the
## player, reskinned and distorted into something wrong. It hunches and its
## arms hang too long, through a BodyDistortion added to the skeleton.
##
## Its states are idle, walk and run in the locomotion blend, and the actions
## attack, stagger, fall and get_up, which Enemy plays as its state changes.

class_name EnemyModel
extends CharacterModel

## Material laid over every mesh of the body.
@export var skin: Material

## The rig's skeleton, which the distortion bends.
@export var skeleton: Skeleton3D

## Extra turn of each bone, in degrees about its own axes: the hunch.
@export var bone_turns: Dictionary[StringName, Vector3] = {
	&"DEF-spine.002": Vector3(20.0, 0.0, 0.0),
	&"DEF-spine.003": Vector3(15.0, 0.0, 0.0),
	&"DEF-neck": Vector3(-10.0, 0.0, 0.0),
}

## Scale of each bone: arms that hang too long.
@export var bone_scales: Dictionary[StringName, Vector3] = {
	&"DEF-forearm.L": Vector3(1.0, 1.4, 1.0),
	&"DEF-forearm.R": Vector3(1.0, 1.4, 1.0),
}


func _ready() -> void:
	super()
	if skin:
		for mesh: Node in find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = skin
	if skeleton:
		var distortion := BodyDistortion.new()
		distortion.name = "BodyDistortion"
		distortion.bone_turns = bone_turns
		distortion.bone_scales = bone_scales
		skeleton.add_child(distortion)
