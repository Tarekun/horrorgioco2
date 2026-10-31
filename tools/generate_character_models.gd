## Generates the animated character scenes from the rigged models in
## assets/models/ (see assets/sources.json):
##
## - the player: scenes/player/player_model.tscn and assets/data/player_animations.res;
## - the standard enemy: scenes/enemies/enemy_model.tscn and assets/data/enemy_animations.res.
##
## Each scene instances its model and adds a CharacterModel script, an
## AnimationPlayer holding the source's clips under the names the game plays
## them by (idle, walk, attack_light_1, stagger, ...), and the AnimationTree: a
## state machine with the locomotion blend space and a state per action. The
## player's walk and run clips get footstep calls at the frames a foot lands,
## found by sampling the feet, and a wooden plank in the right hand. The enemy
## gets its skin and the modifier that distorts its body. The output is
## committed; rerun this after rebuilding a model or changing its clips.
## Run with: godot --headless --path . --script res://tools/generate_character_models.gd
extends SceneTree

## The model's node in each scene. The clips address bones through it.
const MODEL_NODE: String = "Model"
const SKELETON_PATH: String = "Rig/Skeleton3D"

const RIGHT_HAND: String = "DEF-hand.R"
const FEET: Array[String] = ["DEF-foot.L", "DEF-foot.R"]

## Samples per gait cycle when looking for a foot landing, and how far above
## its lowest point (metres) a foot counts as planted.
const FOOT_SAMPLES: int = 60
const FOOT_PLANTED_HEIGHT: float = 0.04

## The plank: size, and where its middle sits in the right hand's frame.
const PLANK_SIZE: Vector3 = Vector3(0.05, 0.75, 0.09)
const PLANK_OFFSET: Vector3 = Vector3(0.0, 0.2, 0.0)
const PLANK_COLOR: Color = Color(0.45, 0.32, 0.2)

## The enemy's skin: a pale, sickly grey.
const ENEMY_SKIN_COLOR: Color = Color(0.42, 0.44, 0.38)

## Each character. "locomotion" lists [blend space point, speed in m/s, source
## clip]; "actions" maps a state to its source clip. Attacks, staggers and the
## like are stretched to their gameplay timings, so a clip's own length only
## paces its keys. Actions in "backwards" play their clip in reverse, and
## those in "returns" go back to locomotion by themselves when they end (the
## player's code returns on its own).
const CHARACTERS: Array[Dictionary] = [
	{
		"name": "player",
		"model": "res://assets/models/characters/luca/luca.gltf",
		"scene": "res://scenes/player/player_model.tscn",
		"library": "res://assets/data/player_animations.res",
		"script": "res://scripts/player/player_model.gd",
		"locomotion":
		[
			[&"idle", 0.0, &"Idle"],
			[&"walk", 1.5, &"Walk"],
			[&"run", 3.5, &"Jog_Fwd"],
			[&"sprint", 5.5, &"Sprint"],
		],
		"actions":
		{
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
		},
		"backwards": [&"backstep"],
		"looping": [&"winded"],
		"returns": [],
		"footsteps": [&"walk", &"run", &"sprint"],
	},
	{
		"name": "enemy",
		"model": "res://assets/models/monsters/monster/monster.gltf",
		"scene": "res://scenes/enemies/enemy_model.tscn",
		"library": "res://assets/data/enemy_animations.res",
		"script": "res://scripts/enemies/enemy_model.gd",
		"locomotion":
		[
			[&"idle", 0.0, &"Idle"],
			[&"walk", 1.2, &"Walk"],
			[&"run", 3.0, &"Jog_Fwd"],
		],
		"actions":
		{
			&"attack": &"Sword_Attack",
			&"stagger": &"Hit_Chest",
			&"fall": &"Death01",
			&"get_up": &"Death01",
		},
		"backwards": [&"get_up"],
		"looping": [],
		"returns": [&"attack", &"stagger", &"get_up"],
		"footsteps": [],
	},
]


func _initialize() -> void:
	# Animations and global transforms only work once the tree has run a frame.
	await process_frame
	var failed: bool = false
	for character: Dictionary in CHARACTERS:
		var error: Error = await _generate(character)
		if error == OK:
			print("Wrote %s and %s" % [character["scene"], character["library"]])
		else:
			printerr("Failed to write the %s model (error %d)" % [character["name"], error])
			failed = true
	quit(1 if failed else 0)


func _generate(character: Dictionary) -> Error:
	var source := (load(character["model"]) as PackedScene).instantiate() as Node3D
	if source == null:
		return ERR_CANT_OPEN
	root.add_child(source)
	await process_frame
	var source_player := (
		source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	)
	var skeleton := source.get_node(SKELETON_PATH) as Skeleton3D

	var library := AnimationLibrary.new()
	for point: Array in character["locomotion"]:
		library.add_animation(point[0], _clip(source_player, point[2], true))
	var actions: Dictionary = character["actions"]
	for state: StringName in actions:
		var is_looping: bool = state in character["looping"]
		library.add_animation(state, _clip(source_player, actions[state], is_looping))
	for point: Array in character["locomotion"]:
		if point[0] in character["footsteps"]:
			var strikes := _foot_strikes(source_player, skeleton, point[2])
			_add_footstep_calls(library.get_animation(point[0]), strikes)
	source.get_parent().remove_child(source)
	source.free()

	var error := ResourceSaver.save(library, character["library"])
	if error != OK:
		return error
	# Reloaded so the scene refers to the saved file instead of embedding the clips.
	var saved := ResourceLoader.load(character["library"], "", ResourceLoader.CACHE_MODE_REPLACE)
	return _save_scene(character, saved as AnimationLibrary)


func _save_scene(character: Dictionary, library: AnimationLibrary) -> Error:
	var model_root := (load(character["script"]) as GDScript).new() as CharacterModel
	model_root.name = "PlayerModel" if character["name"] == "player" else "EnemyModel"

	var model := (load(character["model"]) as PackedScene).instantiate() as Node3D
	model.name = MODEL_NODE
	model_root.add_child(model)

	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model_root.add_child(player)
	player.add_animation_library(&"", library)

	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = _build_tree_root(character)
	tree.anim_player = NodePath("../AnimationPlayer")
	tree.active = true
	# Footstep calls must fire in the same frame the animation reaches them.
	tree.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	model_root.add_child(tree)
	model_root.animation_tree = tree

	if model_root is PlayerModel:
		_dress_player(model_root as PlayerModel, model)
	elif model_root is EnemyModel:
		_dress_enemy(model_root as EnemyModel, model)

	_set_owner_recursive(model_root, model_root)
	var packed := PackedScene.new()
	var error := packed.pack(model_root)
	if error == OK:
		error = ResourceSaver.save(packed, character["scene"])
	model_root.free()
	return error


func _dress_player(model_root: PlayerModel, model: Node3D) -> void:
	model_root.limp_pivot = model
	var plank_hand := BoneAttachment3D.new()
	plank_hand.name = "PlankAttachment"
	plank_hand.use_external_skeleton = true
	plank_hand.external_skeleton = NodePath("../%s/%s" % [MODEL_NODE, SKELETON_PATH])
	plank_hand.bone_name = RIGHT_HAND
	model_root.add_child(plank_hand)
	var mesh := BoxMesh.new()
	mesh.size = PLANK_SIZE
	var plank := MeshInstance3D.new()
	plank.name = "Plank"
	plank.mesh = mesh
	plank.material_override = _flat_material(PLANK_COLOR)
	plank.position = PLANK_OFFSET
	plank_hand.add_child(plank)


func _dress_enemy(model_root: EnemyModel, model: Node3D) -> void:
	model_root.skin = _flat_material(ENEMY_SKIN_COLOR)
	model_root.skeleton = model.get_node(SKELETON_PATH) as Skeleton3D


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


## A copy of the source's `clip`, its tracks addressing the bones through the
## model's node, looping or not as asked.
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
			var pose: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
			heights.append(pose.origin.y)
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


func _build_tree_root(character: Dictionary) -> AnimationNodeStateMachine:
	var machine := AnimationNodeStateMachine.new()
	machine.add_node(&"locomotion", _build_locomotion_space(character), Vector2(0.0, 0.0))
	var row: int = 0
	for state: StringName in character["actions"]:
		row += 1
		var node := _clip_node(state)
		if state in character["backwards"]:
			node.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD
		machine.add_node(state, node, Vector2(300.0, 100.0 * row))
		if state in character["returns"]:
			var back := AnimationNodeStateMachineTransition.new()
			back.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
			back.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
			machine.add_transition(state, &"locomotion", back)
	var start := AnimationNodeStateMachineTransition.new()
	start.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	machine.add_transition(&"Start", &"locomotion", start)
	return machine


func _build_locomotion_space(character: Dictionary) -> AnimationNodeBlendSpace1D:
	var space := AnimationNodeBlendSpace1D.new()
	var points: Array = character["locomotion"]
	space.min_space = 0.0
	space.max_space = (points[points.size() - 1] as Array)[1]
	space.sync = true
	for point: Array in points:
		space.add_blend_point(_clip_node(point[0]), point[1], -1, point[0])
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
