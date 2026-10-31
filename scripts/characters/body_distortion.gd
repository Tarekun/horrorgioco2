## Bends and stretches a skeleton's animated pose: each frame, after the
## animation has posed the bones, turns and scales the listed bones further.
## Gives a shared humanoid rig a body of its own (a hunch, long arms) while it
## keeps playing the same clips.

class_name BodyDistortion
extends SkeletonModifier3D

## Extra turn, in degrees about each bone's own axes, added to its pose.
@export var bone_turns: Dictionary[StringName, Vector3] = {}

## Scale applied to each bone's pose; it carries on to the bone's children.
@export var bone_scales: Dictionary[StringName, Vector3] = {}


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	for bone_name: StringName in bone_turns:
		var bone: int = skeleton.find_bone(bone_name)
		if bone == -1:
			continue
		var turn := Quaternion.from_euler(bone_turns[bone_name] * PI / 180.0)
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * turn)
	for bone_name: StringName in bone_scales:
		var bone: int = skeleton.find_bone(bone_name)
		if bone != -1:
			skeleton.set_bone_pose_scale(bone, bone_scales[bone_name])
