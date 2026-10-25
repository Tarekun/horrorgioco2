## Generates the placeholder humanoid: scenes/player/player_model.tscn.
##
## A skeleton of primitive-shaped body parts with procedural idle, walk and run
## animations, blended by speed in an AnimationTree. The output is committed;
## rerun this only to change the placeholder.
## Run with: godot --headless --path . --script res://tools/generate_placeholder_character.gd
extends SceneTree

const OUTPUT_PATH: String = "res://scenes/player/player_model.tscn"
const SKELETON_PATH: String = "Skeleton3D"

## Bones as [name, parent, rest position relative to the parent]. Right is +X
## and the character faces -Z. The origin is at the feet.
const BONES: Array = [
	["Hips", "", Vector3(0.0, 0.95, 0.0)],
	["Spine", "Hips", Vector3(0.0, 0.1, 0.0)],
	["Chest", "Spine", Vector3(0.0, 0.2, 0.0)],
	["Neck", "Chest", Vector3(0.0, 0.3, 0.0)],
	["Head", "Neck", Vector3(0.0, 0.08, 0.0)],
	["UpperArm_R", "Chest", Vector3(0.22, 0.25, 0.0)],
	["LowerArm_R", "UpperArm_R", Vector3(0.0, -0.3, 0.0)],
	["UpperArm_L", "Chest", Vector3(-0.22, 0.25, 0.0)],
	["LowerArm_L", "UpperArm_L", Vector3(0.0, -0.3, 0.0)],
	["UpperLeg_R", "Hips", Vector3(0.1, -0.05, 0.0)],
	["LowerLeg_R", "UpperLeg_R", Vector3(0.0, -0.46, 0.0)],
	["Foot_R", "LowerLeg_R", Vector3(0.0, -0.44, 0.0)],
	["UpperLeg_L", "Hips", Vector3(-0.1, -0.05, 0.0)],
	["LowerLeg_L", "UpperLeg_L", Vector3(0.0, -0.46, 0.0)],
	["Foot_L", "LowerLeg_L", Vector3(0.0, -0.44, 0.0)],
]

## Mesh parts as [bone, kind, size, offset from the bone, is skin].
## Sizes: box = (x, y, z), capsule = (radius, height, 0), sphere = (radius, height, 0).
const PARTS: Array = [
	["Hips", "box", Vector3(0.34, 0.2, 0.2), Vector3(0.0, 0.0, 0.0), false],
	["Spine", "box", Vector3(0.32, 0.22, 0.2), Vector3(0.0, 0.1, 0.0), false],
	["Chest", "box", Vector3(0.38, 0.3, 0.22), Vector3(0.0, 0.12, 0.0), false],
	["Neck", "capsule", Vector3(0.045, 0.14, 0.0), Vector3(0.0, 0.03, 0.0), true],
	["Head", "sphere", Vector3(0.11, 0.22, 0.0), Vector3(0.0, 0.1, 0.0), true],
	["Head", "box", Vector3(0.04, 0.04, 0.06), Vector3(0.0, 0.09, -0.11), true],
	["UpperArm_R", "capsule", Vector3(0.05, 0.32, 0.0), Vector3(0.0, -0.14, 0.0), false],
	["LowerArm_R", "capsule", Vector3(0.045, 0.3, 0.0), Vector3(0.0, -0.14, 0.0), true],
	["UpperArm_L", "capsule", Vector3(0.05, 0.32, 0.0), Vector3(0.0, -0.14, 0.0), false],
	["LowerArm_L", "capsule", Vector3(0.045, 0.3, 0.0), Vector3(0.0, -0.14, 0.0), true],
	["UpperLeg_R", "capsule", Vector3(0.08, 0.5, 0.0), Vector3(0.0, -0.23, 0.0), false],
	["LowerLeg_R", "capsule", Vector3(0.065, 0.46, 0.0), Vector3(0.0, -0.22, 0.0), false],
	["Foot_R", "box", Vector3(0.1, 0.06, 0.26), Vector3(0.0, 0.03, -0.06), false],
	["UpperLeg_L", "capsule", Vector3(0.08, 0.5, 0.0), Vector3(0.0, -0.23, 0.0), false],
	["LowerLeg_L", "capsule", Vector3(0.065, 0.46, 0.0), Vector3(0.0, -0.22, 0.0), false],
	["Foot_L", "box", Vector3(0.1, 0.06, 0.26), Vector3(0.0, 0.03, -0.06), false],
]

## Speeds (m/s) the locomotion blend space places each clip at.
const WALK_SPEED: float = 1.5
const RUN_SPEED: float = 3.5
const SPRINT_SPEED: float = 5.5

## Frames sampled per animation cycle.
const KEYS_PER_CYCLE: int = 16


func _init() -> void:
	var root := PlayerModel.new()
	root.name = "PlayerModel"

	var skeleton := _build_skeleton()
	root.add_child(skeleton)
	_add_parts(skeleton)

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
	var library := AnimationLibrary.new()
	library.add_animation(&"idle", _build_idle())
	library.add_animation(&"walk", _build_gait(1.0, 0.45, 0.7, 0.04, 0.12, 0.25))
	library.add_animation(&"run", _build_gait(1.0, 0.85, 1.2, 0.07, 0.3, 0.5))
	player.add_animation_library(&"", library)

	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = _build_tree_root()
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.active = true
	root.add_child(tree)
	root.animation_tree = tree

	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, OUTPUT_PATH)
	if error == OK:
		print("Wrote %s" % OUTPUT_PATH)
	else:
		printerr("Failed to write %s (error %d)" % [OUTPUT_PATH, error])
	root.free()
	quit(1 if error != OK else 0)


func _build_skeleton() -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	for bone: Array in BONES:
		var index := skeleton.add_bone(bone[0] as String)
		var parent_name: String = bone[1]
		if parent_name != "":
			skeleton.set_bone_parent(index, skeleton.find_bone(parent_name))
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, bone[2] as Vector3))
	skeleton.reset_bone_poses()
	return skeleton


func _add_parts(skeleton: Skeleton3D) -> void:
	var clothes := StandardMaterial3D.new()
	clothes.albedo_color = Color(0.32, 0.36, 0.42)
	clothes.roughness = 0.9
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.78, 0.66, 0.58)
	skin.roughness = 0.9

	var attachments: Dictionary[String, BoneAttachment3D] = {}
	for part: Array in PARTS:
		var bone_name: String = part[0]
		if not attachments.has(bone_name):
			var attachment := BoneAttachment3D.new()
			attachment.name = bone_name + "Attachment"
			attachment.bone_name = bone_name
			skeleton.add_child(attachment)
			attachments[bone_name] = attachment

		var size: Vector3 = part[2]
		var instance := MeshInstance3D.new()
		instance.name = "%s%d" % [bone_name, attachments[bone_name].get_child_count()]
		instance.mesh = _make_mesh(part[1] as String, size)
		instance.position = part[3] as Vector3
		var is_skin: bool = part[4]
		instance.material_override = skin if is_skin else clothes
		attachments[bone_name].add_child(instance)


func _make_mesh(kind: String, size: Vector3) -> Mesh:
	match kind:
		"box":
			var box := BoxMesh.new()
			box.size = size
			return box
		"capsule":
			var capsule := CapsuleMesh.new()
			capsule.radius = size.x
			capsule.height = size.y
			capsule.radial_segments = 8
			capsule.rings = 2
			return capsule
		_:
			var sphere := SphereMesh.new()
			sphere.radius = size.x
			sphere.height = size.y
			sphere.radial_segments = 8
			sphere.rings = 4
			return sphere


## Idle: slow breathing and a slight arm sway.
func _build_idle() -> Animation:
	var animation := _new_loop(3.0)
	var hips := _add_position_track(animation, "Hips")
	var spine := _add_rotation_track(animation, "Spine")
	var chest := _add_rotation_track(animation, "Chest")
	var arm_r := _add_rotation_track(animation, "UpperArm_R")
	var arm_l := _add_rotation_track(animation, "UpperArm_L")
	for i in KEYS_PER_CYCLE + 1:
		var t := float(i) / KEYS_PER_CYCLE
		var phase := TAU * t
		var time := 3.0 * t
		animation.position_track_insert_key(
			hips, time, Vector3(0.0, 0.95 + 0.004 * sin(phase), 0.0)
		)
		animation.rotation_track_insert_key(spine, time, _pitch(-0.02 * sin(phase)))
		animation.rotation_track_insert_key(chest, time, _pitch(-0.03 * sin(phase)))
		animation.rotation_track_insert_key(arm_r, time, _pitch(0.03 * sin(phase)))
		animation.rotation_track_insert_key(arm_l, time, _pitch(-0.03 * sin(phase)))
	return animation


## A walking or running cycle. Angles in radians: thigh swing, knee bend, arm
## swing, elbow bend and torso lean forward; `bob` is the hip bounce in metres.
func _build_gait(
	period: float, thigh: float, knee: float, bob: float, lean: float, arm: float
) -> Animation:
	var animation := _new_loop(period)
	var tracks: Dictionary[String, int] = {}
	tracks["Hips"] = _add_position_track(animation, "Hips")
	for bone: String in [
		"Spine",
		"UpperLeg_R",
		"UpperLeg_L",
		"LowerLeg_R",
		"LowerLeg_L",
		"UpperArm_R",
		"UpperArm_L",
		"LowerArm_R",
		"LowerArm_L",
		"Foot_R",
		"Foot_L",
	]:
		tracks[bone] = _add_rotation_track(animation, bone)

	for i in KEYS_PER_CYCLE + 1:
		var t := float(i) / KEYS_PER_CYCLE
		var phase := TAU * t
		var time := period * t
		var hips_y := 0.95 - bob + bob * absf(cos(phase))
		animation.position_track_insert_key(tracks["Hips"], time, Vector3(0.0, hips_y, 0.0))
		animation.rotation_track_insert_key(tracks["Spine"], time, _pitch(-lean))
		for side in 2:
			var side_sign: float = 1.0 if side == 0 else -1.0
			var suffix := "_R" if side == 0 else "_L"
			var swing := sin(phase) * side_sign
			animation.rotation_track_insert_key(
				tracks["UpperLeg" + suffix], time, _pitch(thigh * swing)
			)
			# The knee bends most while the leg swings forward.
			var bend := knee * maxf(0.0, cos(phase) * side_sign)
			animation.rotation_track_insert_key(tracks["LowerLeg" + suffix], time, _pitch(-bend))
			animation.rotation_track_insert_key(tracks["Foot" + suffix], time, _pitch(0.2 * bend))
			# Arms swing against the legs, with the elbows bent forward.
			animation.rotation_track_insert_key(
				tracks["UpperArm" + suffix], time, _pitch(-arm * swing)
			)
			animation.rotation_track_insert_key(
				tracks["LowerArm" + suffix], time, _pitch(0.3 + arm * 0.6)
			)
	return animation


func _build_tree_root() -> AnimationNodeBlendSpace1D:
	var space := AnimationNodeBlendSpace1D.new()
	space.min_space = 0.0
	space.max_space = SPRINT_SPEED
	space.sync = true
	space.add_blend_point(_clip(&"idle"), 0.0, -1, &"idle")
	space.add_blend_point(_clip(&"walk"), WALK_SPEED, -1, &"walk")
	space.add_blend_point(_clip(&"run"), RUN_SPEED, -1, &"run")
	# Sprinting reuses the run clip; its speed lies beyond the run point.
	space.add_blend_point(_clip(&"run"), SPRINT_SPEED, -1, &"sprint")
	return space


func _clip(animation_name: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = animation_name
	return node


func _new_loop(length: float) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR
	return animation


func _add_rotation_track(animation: Animation, bone: String) -> int:
	var index := animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(index, NodePath("%s:%s" % [SKELETON_PATH, bone]))
	return index


func _add_position_track(animation: Animation, bone: String) -> int:
	var index := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(index, NodePath("%s:%s" % [SKELETON_PATH, bone]))
	return index


## A rotation about the X axis. Positive swings a downward limb forward (-Z)
## and an upward one (the spine) backward.
func _pitch(angle: float) -> Quaternion:
	return Quaternion(Vector3.RIGHT, angle)


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
