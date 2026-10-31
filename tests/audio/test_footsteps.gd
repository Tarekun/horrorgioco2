## Tests for footsteps: the player scene wiring, sync with the walk and run
## animations, and the volume and variant rules.

extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const STEP: float = 1.0 / 60.0

var _player: Player
var _model: PlayerModel
var _footsteps: Footsteps
var _tree: AnimationTree
var _step_times: Array[float] = []
var _step_speeds: Array[float] = []
var _clock: float = 0.0


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_model = _player.model
	_footsteps = _player.get_node("Footsteps") as Footsteps
	_tree = _model.animation_tree
	_step_times.clear()
	_step_speeds.clear()
	_clock = 0.0
	_model.footstep_taken.connect(_on_step)


func _on_step(speed: float) -> void:
	_step_times.append(_clock)
	_step_speeds.append(speed)


## Settles the blend at `speed`, then runs the model for `seconds`, recording
## each footstep.
func _run_at(speed: float, seconds: float) -> void:
	_model.set_speed(speed)
	for i: int in 90:
		_model._process(STEP)
	_step_times.clear()
	_step_speeds.clear()
	_clock = 0.0
	for i: int in int(seconds / STEP):
		_clock += STEP
		_model._process(STEP)


# --- Wiring ---


func test_player_has_footsteps_wired_to_the_model_on_the_sfx_bus() -> void:
	assert_not_null(_footsteps, "Footsteps node in the player scene")
	assert_eq(_footsteps.model, _model, "model reference assigned")
	assert_eq(_footsteps.bus, AudioBuses.SFX)
	assert_eq(_footsteps.variants.size(), 3)
	assert_true(_model.footstep_taken.is_connected(_footsteps._on_footstep_taken))


func test_footstep_signal_plays_a_sound() -> void:
	_model.set_speed(3.5)
	_footsteps.play_footstep(3.5)
	assert_not_null(_footsteps.stream)
	assert_true(_footsteps.playing)


# --- Sync with the animation ---


func test_idle_makes_no_footsteps() -> void:
	_run_at(0.0, 3.0)
	assert_eq(_step_times.size(), 0)


func test_walking_steps_twice_per_cycle() -> void:
	_run_at(1.5, 4.0)
	# Each walk cycle has two foot contacts.
	var cycle: float = (
		(_model.get_node("AnimationPlayer") as AnimationPlayer).get_animation(&"walk").length
	)
	var expected: int = roundi(2.0 * 4.0 / cycle)
	assert_between(_step_times.size(), expected - 1, expected + 1, "steps in 4 s")


func test_running_steps_twice_per_cycle_without_double_triggers() -> void:
	_run_at(3.5, 4.0)
	assert_between(_step_times.size(), 7, 9, "steps in 4 s")
	for i: int in range(1, _step_times.size()):
		assert_between(_step_times[i] - _step_times[i - 1], 0.4, 0.6, "even spacing")


func test_footstep_reports_the_current_speed() -> void:
	_run_at(3.5, 2.0)
	assert_gt(_step_speeds.size(), 0)
	for speed: float in _step_speeds:
		assert_almost_eq(speed, 3.5, 0.2)


func test_footsteps_land_at_foot_contact_phase() -> void:
	# Each gait clip calls emit_footstep() once per foot landing.
	var player := _model.get_node("AnimationPlayer") as AnimationPlayer
	for clip: StringName in [&"walk", &"run"]:
		var animation: Animation = player.get_animation(clip)
		var calls: int = 0
		for track: int in animation.get_track_count():
			if animation.track_get_type(track) != Animation.TYPE_METHOD:
				continue
			assert_eq(animation.track_get_path(track), NodePath("."))
			for key: int in animation.track_get_key_count(track):
				var value: Dictionary = animation.track_get_key_value(track, key)
				assert_eq(value["method"], &"emit_footstep")
				calls += 1
		assert_eq(calls, 2, "%s has two contacts" % clip)
	var idle: Animation = player.get_animation(&"idle")
	for track: int in idle.get_track_count():
		assert_ne(idle.track_get_type(track), Animation.TYPE_METHOD, "idle has no method track")


# --- Rules ---


func test_volume_rises_from_walk_to_sprint() -> void:
	var walk: float = Footsteps.volume_for_speed(1.5, 1.5, 5.5, -9.0, 0.0)
	var run: float = Footsteps.volume_for_speed(3.5, 1.5, 5.5, -9.0, 0.0)
	var sprint: float = Footsteps.volume_for_speed(5.5, 1.5, 5.5, -9.0, 0.0)
	assert_almost_eq(walk, -9.0, 0.001)
	assert_almost_eq(sprint, 0.0, 0.001)
	assert_between(run, -9.0, 0.0)
	assert_almost_eq(Footsteps.volume_for_speed(0.0, 1.5, 5.5, -9.0, 0.0), -9.0, 0.001, "clamped")


func test_pick_variant_never_repeats_and_covers_all() -> void:
	var seen: Dictionary[int, bool] = {}
	for last: int in [-1, 0, 1, 2]:
		for roll: float in [0.0, 0.3, 0.5, 0.7, 0.99]:
			var index: int = Footsteps.pick_variant(3, last, roll)
			assert_between(index, 0, 2)
			if last >= 0:
				assert_ne(index, last)
			seen[index] = true
	assert_eq(seen.size(), 3)
	assert_eq(Footsteps.pick_variant(1, 0, 0.9), 0)
