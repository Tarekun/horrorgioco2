## Tests for the standard enemy's body: its rig and clips, how the enemy's
## states drive it, and that its hurtbox and attack hitbox match what it shows.

extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const MODEL_SCENE: PackedScene = preload("res://scenes/enemies/enemy_model.tscn")

var _enemy: Enemy
var _model: EnemyModel
var _skeleton: Skeleton3D


func before_each() -> void:
	_enemy = ENEMY_SCENE.instantiate() as Enemy
	_enemy.is_dormant = true
	add_child_autofree(_enemy)
	_model = _enemy.model
	_skeleton = _model.skeleton
	await get_tree().process_frame


## Where `bone` is, in the enemy's own space.
func _bone_position(bone: String) -> Vector3:
	var pose: Transform3D = _skeleton.get_bone_global_pose(_skeleton.find_bone(bone))
	return _enemy.to_local(_skeleton.global_transform * pose.origin)


## Plays the model forward by `seconds` and lets the skeleton take the pose.
func _play_for(seconds: float) -> void:
	var step: float = 1.0 / 60.0
	var elapsed: float = 0.0
	while elapsed < seconds:
		_model._process(step)
		elapsed += step
	await get_tree().process_frame


# --- Rig and clips ---


func test_model_is_within_the_monster_budget() -> void:
	var triangles: int = 0
	for mesh_instance: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		triangles += mesh_instance.mesh.get_faces().size() / 3
	assert_between(triangles, 2000, 4000, "triangle count")


func test_every_state_has_a_clip() -> void:
	var player := _model.get_node("AnimationPlayer") as AnimationPlayer
	for clip: StringName in [&"idle", &"walk", &"run"]:
		assert_eq(player.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, str(clip))
	for clip: StringName in [&"attack", &"stagger", &"fall", &"get_up"]:
		assert_true(player.has_animation(clip), str(clip))
		assert_eq(player.get_animation(clip).loop_mode, Animation.LOOP_NONE, str(clip))


func test_the_skin_covers_the_body() -> void:
	for mesh_instance: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		assert_eq(mesh_instance.material_override, _model.skin)


func test_the_body_is_distorted() -> void:
	var distortion := _skeleton.get_node("BodyDistortion") as BodyDistortion
	assert_not_null(distortion)
	# The skeleton restores its pose after the modifiers run, so run it here.
	var spine: int = _skeleton.find_bone("DEF-spine.002")
	var before: Quaternion = _skeleton.get_bone_pose_rotation(spine)
	distortion._process_modification_with_delta(0.0)
	var forearm: int = _skeleton.find_bone("DEF-forearm.R")
	assert_almost_eq(_skeleton.get_bone_pose_scale(forearm).y, 1.4, 0.01, "long arms")
	assert_almost_eq(
		before.angle_to(_skeleton.get_bone_pose_rotation(spine)), deg_to_rad(20.0), 0.01, "hunch"
	)


func test_actions_go_back_to_locomotion_when_they_end() -> void:
	_model.play_action(&"stagger", 0.3)
	_model._process(0.01)
	assert_eq(_model.get_current_state(), &"stagger")
	await _play_for(0.5)
	assert_eq(_model.get_current_state(), CharacterModel.LOCOMOTION_STATE)


# --- Driven by the enemy ---


func test_the_model_follows_the_enemy_speed() -> void:
	_enemy.velocity = Vector3(3.0, -1.0, 4.0)
	_enemy._update_model()
	_model._process(1.0)
	assert_almost_eq(_model.get_blend_speed(), 5.0, 0.01, "horizontal speed")


func test_states_play_their_clips() -> void:
	_enemy._on_state_changed(EnemyBrain.State.CHASE, EnemyBrain.State.ATTACK)
	_model._process(0.01)
	assert_eq(_model.get_current_state(), &"attack")
	_enemy._on_state_changed(EnemyBrain.State.ATTACK, EnemyBrain.State.STAGGER)
	_model._process(0.01)
	assert_eq(_model.get_current_state(), &"stagger")
	_enemy._on_state_changed(EnemyBrain.State.STAGGER, EnemyBrain.State.DOWNED)
	_model._process(0.01)
	assert_eq(_model.get_current_state(), &"fall")
	_enemy._on_state_changed(EnemyBrain.State.DOWNED, EnemyBrain.State.IDLE)
	_model._process(0.01)
	assert_eq(_model.get_current_state(), &"get_up")


func test_an_enemy_getting_up_stands_still() -> void:
	_enemy._on_state_changed(EnemyBrain.State.DOWNED, EnemyBrain.State.CHASE)
	_enemy.is_dormant = false
	_enemy.velocity = Vector3(3.0, 0.0, 0.0)
	_enemy._run_state(1.0 / 60.0)
	_enemy._physics_process(1.0 / 60.0)
	assert_eq(Vector2(_enemy.velocity.x, _enemy.velocity.z), Vector2.ZERO)


# --- Hit areas line up with the body ---


func test_standing_body_fills_the_hurtbox() -> void:
	var capsule := (_enemy.hurtbox.get_child(0) as CollisionShape3D).shape as CapsuleShape3D
	var head: Vector3 = _bone_position("DEF-head")
	assert_between(
		head.y, capsule.height * 0.7, capsule.height, "head inside the top of the capsule"
	)
	assert_lt(Vector2(head.x, head.z).length(), capsule.radius + 0.1, "head over the capsule")


func test_a_downed_body_lies_where_its_hurtbox_lies() -> void:
	_enemy._on_state_changed(EnemyBrain.State.IDLE, EnemyBrain.State.DOWNED)
	await _play_for(_enemy.fall_duration + 0.2)
	var shape := _enemy.hurtbox.get_child(0) as CollisionShape3D
	var head: Vector3 = _bone_position("DEF-head")
	# The capsule's axis, in the enemy's own (lying) space, runs from the feet
	# at the origin up its local Y.
	var axis_end: Vector3 = shape.position * 2.0
	var along: float = head.dot(axis_end.normalized())
	var off_axis: float = (head - axis_end.normalized() * along).length()
	assert_between(along, 0.0, axis_end.length() + 0.3, "head along the capsule")
	assert_lt(off_axis, 0.6, "head close to the capsule's axis")


func test_the_swing_passes_through_the_attack_hitbox() -> void:
	var shape := _enemy.attack_hitbox.get_child(0) as CollisionShape3D
	var box := AABB(
		shape.position - (shape.shape as BoxShape3D).size / 2.0, (shape.shape as BoxShape3D).size
	)
	_enemy._on_state_changed(EnemyBrain.State.CHASE, EnemyBrain.State.ATTACK)
	await _play_for(_enemy.attack_windup)
	var steps: int = 5
	var hits: int = 0
	for i: int in steps:
		var inside: bool = false
		for hand: String in ["DEF-hand.L", "DEF-hand.R"]:
			var position: Vector3 = _bone_position(hand)
			inside = inside or box.grow(0.15).has_point(position)
		hits += 1 if inside else 0
		await _play_for(_enemy.attack_active / steps)
	assert_gt(hits, steps / 2, "a hand is in the hitbox for most of the active window")
