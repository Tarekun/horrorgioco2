## Generates the player's character: scenes/player/player_model.tscn and
## assets/data/player_animations.res.
##
## The body is the rigged mannequin from assets/models/characters/luca/ (see
## assets/sources.json). This script gives it the PlayerModel script, an
## AnimationPlayer holding the source's clips under the names the game plays
## them by (idle, walk, attack_light_1, ...), and the AnimationTree: a state
## machine with the locomotion blend space and a state per action. The walk
## and run clips get footstep calls at the frames a foot lands, found by
## sampling the feet. A wooden plank is attached to the right hand. The output
## is committed; rerun this after rebuilding the model or changing the clips.
## Run with: godot --headless --path . --script res://tools/generate_player_model.gd
extends SceneTree

const MODEL_PATH: String = "res://assets/models/characters/luca/luca.gltf"
const SCENE_PATH: String = "res://scenes/player/player_model.tscn"
const LIBRARY_PATH: String = "res://assets/data/player_animations.res"

## The model's node in the scene. The clips address bones through it.
const MODEL_NODE: String = "Model"
const SKELETON_PATH: String = "Rig/Skeleton3D"

const RIGHT_HAND: String = "DEF-hand.R"
const FEET: Array[String] = ["DEF-foot.L", "DEF-foot.R"]

## Speeds (m/s) the locomotion blend space places each clip at.
const WALK_SPEED: float = 1.5
const RUN_SPEED: float = 3.5
const SPRINT_SPEED: float = 5.5

## Locomotion clips: the name the blend space uses -> the source's clip.
const LOCOMOTION: Dictionary[StringName, StringName] = {
	&"idle": &"Idle",
	&"walk": &"Walk",
	&"run": &"Jog_Fwd",
	&"sprint": &"Sprint",
}

## One-off action clips: the state's name -> the source's clip. Attacks are
## stretched to the weapon's timings (MeleeWeapon), so a clip's own length
## only sets how its keys are paced.
const ACTIONS: Dictionary[StringName, StringName] = {
	&"attack_light_1": &"Punch_Jab",
	&"attack_light_2": &"Punch_Cross",
	&"attack_light_3": &"Sword_Attack",
	&"attack_heavy_charge": &"Punch_Enter",
	&"attack_heavy_swing": &"Sword_Attack",
	&"dodge": &"Roll",
	&"backstep": &"Roll",
	&"hit": &"Hit_Chest",
	&"death": &"Death01",
	&"winded": &"Crouch_Idle",
}

## Actions that play their clip backwards.
const BACKWARDS: Array[StringName] = [&"backstep"]

## Clips that loop: the locomotion clips and the winded crouch.
const LOOPING: Array[StringName] = [&"idle", &"walk", &"run", &"sprint", &"winded"]

## Clips that call emit_footstep() when a foot lands.
const FOOTSTEP_CLIPS: Array[StringName] = [&"walk", &"run", &"sprint"]

## Samples per gait cycle when looking for a foot landing, and how far above
## its lowest point (metres) a foot counts as planted.
const FOOT_SAMPLES: int = 60
const FOOT_PLANTED_HEIGHT: float = 0.04

## The plank: size, and where its middle sits in the right hand's frame.
const PLANK_SIZE: Vector3 = Vector3(0.05, 0.75, 0.09)
const PLANK_OFFSET: Vector3 = Vector3(0.0, 0.2, 0.0)
const PLANK_COLOR: Color = Color(0.45, 0.32, 0.2)


func _initialize() -> void:
	var source := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	if source == null:
		printerr("Could not load %s" % MODEL_PATH)
		quit(1)
		return
	root.add_child(source)
	# Animations and global transforms only work once the tree has run a frame.
	await process_frame
	var source_player := (
		source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	)
	var skeleton := source.get_node(SKELETON_PATH) as Skeleton3D

	var library := AnimationLibrary.new()
	for state: StringName in LOCOMOTION:
		library.add_animation(state, _clip(source_player, LOCOMOTION[state], state in LOOPING))
	for state: StringName in ACTIONS:
		library.add_animation(state, _clip(source_player, ACTIONS[state], state in LOOPING))
	for state: StringName in FOOTSTEP_CLIPS:
		var strikes := _foot_strikes(source_player, skeleton, LOCOMOTION[state])
		_add_footstep_calls(library.get_animation(state), strikes)
	source.get_parent().remove_child(source)
	source.free()

	var error := ResourceSaver.save(library, LIBRARY_PATH)
	if error == OK:
		# Reloaded so the scene refers to the saved file instead of embedding the clips.
		error = _save_scene(
			ResourceLoader.load(LIBRARY_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
		)
	if error == OK:
		print("Wrote %s and %s" % [SCENE_PATH, LIBRARY_PATH])
	else:
		printerr("Failed to write the player model (error %d)" % error)
	quit(1 if error != OK else 0)


func _save_scene(library: Resource) -> Error:
	var model_root := PlayerModel.new()
	model_root.name = "PlayerModel"

	var model := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	model.name = MODEL_NODE
	model_root.add_child(model)

	var plank_hand := BoneAttachment3D.new()
	plank_hand.name = "PlankAttachment"
	plank_hand.use_external_skeleton = true
	plank_hand.external_skeleton = NodePath("../%s/%s" % [MODEL_NODE, SKELETON_PATH])
	plank_hand.bone_name = RIGHT_HAND
	model_root.add_child(plank_hand)
	plank_hand.add_child(_plank())

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model_root.add_child(player)
	player.add_animation_library(&"", library as AnimationLibrary)

	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = _build_tree_root()
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.active = true
	# Footstep calls must fire in the same frame the animation reaches them.
	tree.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	model_root.add_child(tree)
	model_root.animation_tree = tree
	model_root.limp_pivot = model

	_set_owner_recursive(model_root, model_root)
	var packed := PackedScene.new()
	var error := packed.pack(model_root)
	if error == OK:
		error = ResourceSaver.save(packed, SCENE_PATH)
	model_root.free()
	return error


func _plank() -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = PLANK_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = PLANK_COLOR
	material.roughness = 0.9
	var plank := MeshInstance3D.new()
	plank.name = "Plank"
	plank.mesh = mesh
	plank.material_override = material
	plank.position = PLANK_OFFSET
	return plank


## A copy of the source's `clip` for `state`, its tracks addressing the bones
## through the model's node, looping or not as asked.
func _clip(source_player: AnimationPlayer, clip: StringName, is_looping: bool) -> Animation:
	var animation := source_player.get_animation(clip).duplicate() as Animation
	for track: int in animation.get_track_count():
		var path: String = str(animation.track_get_path(track))
		animation.track_set_path(track, NodePath("%s/%s" % [MODEL_NODE, path]))
	animation.loop_mode = Animation.LOOP_LINEAR if is_looping else Animation.LOOP_NONE
	return animation


## The times (seconds) in the source's `clip` at which a foot comes down: it
## drops to within FOOT_PLANTED_HEIGHT of its lowest point after being above.
func _foot_strikes(
	source_player: AnimationPlayer, skeleton: Skeleton3D, clip: StringName
) -> Array[float]:
	var length: float = source_player.get_animation(clip).length
	var strikes: Array[float] = []
	source_player.play(clip)
	for foot: String in FEET:
		var bone: int = skeleton.find_bone(foot)
		var heights: Array[float] = []
		for i: int in FOOT_SAMPLES:
			source_player.seek(length * i / FOOT_SAMPLES, true)
			heights.append(
				(skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin.y
			)
		var planted: float = heights.min() + FOOT_PLANTED_HEIGHT
		for i: int in FOOT_SAMPLES:
			if heights[(i - 1 + FOOT_SAMPLES) % FOOT_SAMPLES] > planted and heights[i] <= planted:
				strikes.append(length * i / FOOT_SAMPLES)
	source_player.stop()
	strikes.sort()
	return strikes


func _add_footstep_calls(animation: Animation, strikes: Array[float]) -> void:
	var index: int = animation.add_track(Animation.TYPE_METHOD)
	animation.track_set_path(index, NodePath("."))
	for time: float in strikes:
		animation.track_insert_key(index, time, {"method": &"emit_footstep", "args": []})


func _build_tree_root() -> AnimationNodeStateMachine:
	var machine := AnimationNodeStateMachine.new()
	machine.add_node(&"locomotion", _build_locomotion_space(), Vector2(0.0, 0.0))
	var row: int = 0
	for state: StringName in ACTIONS:
		row += 1
		var node := _clip_node(state)
		if state in BACKWARDS:
			node.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD
		machine.add_node(state, node, Vector2(300.0, 100.0 * row))
	var start := AnimationNodeStateMachineTransition.new()
	start.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	machine.add_transition(&"Start", &"locomotion", start)
	return machine


func _build_locomotion_space() -> AnimationNodeBlendSpace1D:
	var space := AnimationNodeBlendSpace1D.new()
	space.min_space = 0.0
	space.max_space = SPRINT_SPEED
	space.sync = true
	space.add_blend_point(_clip_node(&"idle"), 0.0, -1, &"idle")
	space.add_blend_point(_clip_node(&"walk"), WALK_SPEED, -1, &"walk")
	space.add_blend_point(_clip_node(&"run"), RUN_SPEED, -1, &"run")
	space.add_blend_point(_clip_node(&"sprint"), SPRINT_SPEED, -1, &"sprint")
	return space


func _clip_node(animation_name: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = animation_name
	return node


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	# The model is an instanced scene: only the nodes added here belong to this one.
	if node != owner_node and not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
