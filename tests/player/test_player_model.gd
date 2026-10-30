## Tests for the player's character: rig, animations and speed blending.

extends GutTest

const MODEL_SCENE: PackedScene = preload("res://scenes/player/player_model.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _model: PlayerModel
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _idle_leg: Quaternion


func before_each() -> void:
	_model = MODEL_SCENE.instantiate() as PlayerModel
	add_child_autofree(_model)
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_tree = _model.animation_tree
	_settle_at(0.0)
	_idle_leg = _skeleton.get_bone_pose_rotation(_skeleton.find_bone("DEF-thigh.R"))


func after_each() -> void:
	Input.action_release(&"move_forward")


## Sets the speed and runs the blend and the tree long enough to settle.
func _settle_at(speed: float) -> void:
	_model.set_speed(speed)
	for i: int in 60:
		_model._process(1.0 / 60.0)


## How far (radians) the bone is turned from its rest pose.
func _turn_from_rest(bone: String) -> float:
	var index: int = _skeleton.find_bone(bone)
	var rest: Quaternion = _skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	return rest.angle_to(_skeleton.get_bone_pose_rotation(index))


## How far (radians) the right thigh is turned from where it stands at idle.
func _leg_swing() -> float:
	return _idle_leg.angle_to(_skeleton.get_bone_pose_rotation(_skeleton.find_bone("DEF-thigh.R")))


# --- Rig ---


func test_skeleton_is_a_humanoid_within_budget() -> void:
	assert_between(_skeleton.get_bone_count(), 15, 55, "bone count")
	for bone: String in ["DEF-hips", "DEF-spine.001", "DEF-head", "DEF-upper_arm.L"]:
		assert_ne(_skeleton.find_bone(bone), -1, bone)
	for bone: String in ["DEF-shin.R", "DEF-foot.L", "DEF-hand.R"]:
		assert_ne(_skeleton.find_bone(bone), -1, bone)


func test_model_is_within_the_character_budget() -> void:
	var triangles: int = 0
	for mesh_instance: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		triangles += mesh_instance.mesh.get_faces().size() / 3
	assert_between(triangles, 3000, 6000, "triangle count")


func test_the_plank_follows_the_right_hand() -> void:
	var attachment := _model.get_node("PlankAttachment") as BoneAttachment3D
	assert_eq(attachment.bone_name, "DEF-hand.R")
	_model.play_action(&"attack_light_1")
	_tree.advance(0.01)
	_tree.advance(0.3)
	await get_tree().process_frame
	var hand: int = _skeleton.find_bone("DEF-hand.R")
	var hand_position: Vector3 = (
		(_skeleton.global_transform * _skeleton.get_bone_global_pose(hand)).origin
	)
	assert_lt(attachment.global_position.distance_to(hand_position), 0.05, "plank at the hand")


func test_every_animation_loops_and_targets_existing_bones() -> void:
	var player := _model.get_node("AnimationPlayer") as AnimationPlayer
	for animation_name: StringName in [&"idle", &"walk", &"run"]:
		var animation: Animation = player.get_animation(animation_name)
		assert_eq(animation.loop_mode, Animation.LOOP_LINEAR, "%s loops" % animation_name)
		assert_gt(animation.get_track_count(), 0)
		for track: int in animation.get_track_count():
			# Method tracks call back into the model (footsteps); they target no bone.
			if animation.track_get_type(track) == Animation.TYPE_METHOD:
				continue
			var bone: String = str(animation.track_get_path(track).get_concatenated_subnames())
			assert_ne(_skeleton.find_bone(bone), -1, "%s: %s" % [animation_name, bone])


# --- Speed blending ---


func test_blend_follows_the_reported_speed() -> void:
	_settle_at(3.5)
	assert_almost_eq(_model.get_blend_speed(), 3.5, 0.05)
	_settle_at(0.0)
	assert_almost_eq(_model.get_blend_speed(), 0.0, 0.05)


func test_negative_speed_is_clamped() -> void:
	_settle_at(-4.0)
	assert_eq(_model.get_blend_speed(), 0.0)


func test_smoothing_is_gradual_not_instant() -> void:
	_model.set_speed(3.5)
	_model._process(1.0 / 60.0)
	assert_gt(_model.get_blend_speed(), 0.0)
	assert_lt(_model.get_blend_speed(), 3.5)


func test_smoothing_is_frame_rate_independent() -> void:
	var at_30: float = 0.0
	var at_120: float = 0.0
	for i: int in 3:
		at_30 = PlayerModel.smoothed_speed(at_30, 3.5, 12.0, 1.0 / 30.0)
	for i: int in 12:
		at_120 = PlayerModel.smoothed_speed(at_120, 3.5, 12.0, 1.0 / 120.0)
	assert_almost_eq(at_30, at_120, 0.001)


func test_idle_stands_still_and_walk_and_run_swing_the_legs() -> void:
	_settle_at(0.0)
	var idle_swing: float = _leg_swing()
	assert_lt(idle_swing, 0.1, "idle legs are still")

	var walk_peak: float = 0.0
	_settle_at(1.5)
	for i: int in 30:
		_tree.advance(1.0 / 30.0)
		walk_peak = maxf(walk_peak, _leg_swing())
	assert_gt(walk_peak, 0.2, "walk swings the legs")

	var run_peak: float = 0.0
	_settle_at(3.5)
	for i: int in 30:
		_tree.advance(1.0 / 30.0)
		run_peak = maxf(run_peak, _leg_swing())
	assert_gt(run_peak, walk_peak + 0.1, "run swings further than walk")


func test_in_between_speeds_blend_between_clips() -> void:
	var peaks: Dictionary[float, float] = {}
	for speed: float in [1.5, 2.5, 3.5]:
		_settle_at(speed)
		var peak: float = 0.0
		for i: int in 30:
			_tree.advance(1.0 / 30.0)
			peak = maxf(peak, _leg_swing())
		peaks[speed] = peak
	assert_gt(peaks[2.5], peaks[1.5], "above walk")
	assert_lt(peaks[2.5], peaks[3.5], "below run")


# --- Player integration ---


func test_player_drives_the_model_from_its_speed() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	assert_not_null(player.model, "model wired")

	for i: int in 10:
		await get_tree().physics_frame
	assert_lt(player.model.get_blend_speed(), 0.1, "idle when standing")

	Input.action_press(&"move_forward")
	for i: int in 90:
		await get_tree().physics_frame
	assert_gt(player.model.get_blend_speed(), 3.0, "running when moving")


# --- Actions ---


func test_action_clips_exist_and_target_existing_bones() -> void:
	var player := _model.get_node("AnimationPlayer") as AnimationPlayer
	for animation_name: StringName in [
		&"attack_light_1",
		&"attack_light_2",
		&"attack_light_3",
		&"attack_heavy_charge",
		&"attack_heavy_swing",
	]:
		assert_true(player.has_animation(animation_name), str(animation_name))
		var animation: Animation = player.get_animation(animation_name)
		assert_eq(animation.loop_mode, Animation.LOOP_NONE)
		for track: int in animation.get_track_count():
			var bone: String = str(animation.track_get_path(track).get_concatenated_subnames())
			assert_ne(_skeleton.find_bone(bone), -1, "%s: %s" % [animation_name, bone])


func test_play_action_leaves_and_returns_to_locomotion() -> void:
	_tree.advance(0.01)
	assert_eq(_model.get_current_state(), PlayerModel.LOCOMOTION_STATE)
	_model.play_action(&"attack_light_1")
	_tree.advance(0.01)
	assert_eq(_model.get_current_state(), &"attack_light_1")
	_model.return_to_locomotion()
	_tree.advance(0.01)
	assert_eq(_model.get_current_state(), PlayerModel.LOCOMOTION_STATE)


func test_action_moves_the_arm_and_locomotion_still_blends_after() -> void:
	_model.play_action(&"attack_light_1")
	_tree.advance(0.01)
	_tree.advance(0.2)
	assert_gt(_turn_from_rest("DEF-upper_arm.R"), 0.5, "arm raised")
	_model.return_to_locomotion()
	_settle_at(3.5)
	assert_almost_eq(_model.get_blend_speed(), 3.5, 0.05)
	assert_gt(_leg_swing(), 0.0)


func test_freezing_stops_the_animation() -> void:
	_model.play_action(&"attack_light_1")
	_model._process(0.05)
	var playback := _tree.get(PlayerModel.PLAYBACK_PARAMETER) as AnimationNodeStateMachinePlayback
	var position: float = playback.get_current_play_position()
	_model.set_frozen(true)
	assert_true(_model.is_frozen())
	_model._process(0.1)
	assert_eq(playback.get_current_play_position(), position)
	_model.set_frozen(false)
	_model._process(0.1)
	assert_gt(playback.get_current_play_position(), position)


func test_an_action_can_be_stretched_to_a_duration() -> void:
	_model.play_action(&"attack_light_1", 0.9)
	var length: float = _tree.get_animation(&"attack_light_1").length
	assert_almost_eq(_model.get_action_speed(), length / 0.9, 0.001)
	_model.return_to_locomotion()
	assert_eq(_model.get_action_speed(), 1.0)
	_model.play_action(&"attack_light_1")
	assert_eq(_model.get_action_speed(), 1.0)


func test_freezing_keeps_the_action_playing() -> void:
	_model.play_action(&"attack_light_1")
	await get_tree().process_frame
	await get_tree().process_frame
	_model.set_frozen(true)
	await get_tree().process_frame
	_model.set_frozen(false)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_model.get_current_state(), &"attack_light_1")


func test_limp_offset_dips_and_leans_with_the_cycle() -> void:
	assert_eq(PlayerModel.limp_offset(1.0, 0.0, 0.05, 0.07), Vector2.ZERO, "no limp at weight 0")
	var rest := PlayerModel.limp_offset(PI * 1.5, 1.0, 0.05, 0.07)
	var lean := PlayerModel.limp_offset(PI * 0.5, 1.0, 0.05, 0.07)
	assert_almost_eq(rest.x, 0.0, 0.0001, "no dip at the top of the stride")
	assert_almost_eq(lean.x, -0.05, 0.0001, "full dip on the other side")
	assert_almost_eq(lean.y, 0.07, 0.0001)
	assert_almost_eq(rest.y, -0.07, 0.0001)
