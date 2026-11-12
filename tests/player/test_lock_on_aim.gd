## Tests of the LockOnAim: while `aim` is held, the player locks on to the
## nearest valid enemy, `next_target` cycles through the valid ones in
## angle order, the aim direction points at the lock (or along the camera
## forward with no lock), and the lock is released when the target stops
## being valid or aiming stops.
##
## The rig is a camera at the origin with identity rotation — looking
## along -Z — and plain Node3D "enemies" in a dedicated group, at exact
## angles from the camera forward: an enemy at `(sin(r), 0, -cos(r)) * d`
## is `r` radians to the right of the forward.

extends GutTest

const TEST_GROUP: StringName = &"lock_on_aim_test_enemies"

var _camera: Camera3D
var _scanner: LockOnScanner
var _aim: LockOnAim


func before_each() -> void:
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_scanner = LockOnScanner.new()
	_scanner.enemy_group = TEST_GROUP
	add_child_autofree(_scanner)
	_aim = LockOnAim.new()
	_aim.scanner = _scanner
	_aim.camera = _camera
	add_child_autofree(_aim)
	await _frames(2)


func after_each() -> void:
	Input.action_release(&"aim")
	Input.action_release(&"next_target")


## Spawns a plain Node3D enemy in the test group, `angle_deg` degrees to
## the right of the camera forward, `distance` metres from the camera.
func _add_enemy(angle_deg: float, distance: float) -> Node3D:
	var enemy := Node3D.new()
	var angle: float = deg_to_rad(angle_deg)
	enemy.position = Vector3(sin(angle), 0, -cos(angle)) * distance
	add_child_autofree(enemy)
	enemy.add_to_group(TEST_GROUP)
	return enemy


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


## Feeds a synthetic pressed/released event for `action` straight to
## _unhandled_input, the way the viewport would (in headless runs the Input
## singleton does not propagate injected events to the scene tree).
func _feed(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	_aim._unhandled_input(event)


# --- Starting and stopping the aim ---


func test_start_aiming_locks_the_visible_in_range_enemy() -> void:
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	watch_signals(_aim)
	_aim.start_aiming()
	assert_true(_aim.is_aiming)
	assert_eq(_aim.locked_target, enemy)
	assert_signal_emitted(_aim, "aim_started")
	assert_signal_emitted_with_parameters(_aim, "target_changed", [enemy])
	_aim.stop_aiming()
	assert_false(_aim.is_aiming)
	assert_null(_aim.locked_target)
	assert_signal_emitted(_aim, "aim_ended")
	assert_signal_emitted_with_parameters(_aim, "target_changed", [null])


func test_starting_and_stopping_are_idempotent() -> void:
	watch_signals(_aim)
	_aim.start_aiming()
	_aim.start_aiming()
	assert_signal_emit_count(_aim, "aim_started", 1)
	_aim.stop_aiming()
	_aim.stop_aiming()
	assert_false(_aim.is_aiming)
	assert_signal_emit_count(_aim, "aim_ended", 1)


# --- Cycling ---


func test_next_target_moves_to_the_other_target_and_wraps_back() -> void:
	# Different distances so the initial lock is unambiguous.
	var left := _add_enemy(-30.0, 5.0)
	var right := _add_enemy(30.0, 6.0)
	await _frames(2)
	watch_signals(_aim)
	_aim.start_aiming()
	assert_eq(_aim.locked_target, left, "the nearer enemy is locked first")
	_aim.cycle_target()
	assert_eq(_aim.locked_target, right, "next_target moves to the other valid target")
	assert_signal_emitted_with_parameters(_aim, "target_changed", [right])
	_aim.cycle_target()
	assert_eq(_aim.locked_target, left, "the cycle wraps back around")
	assert_signal_emitted_with_parameters(_aim, "target_changed", [left])


func test_cycling_with_no_valid_targets_releases_the_lock() -> void:
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	watch_signals(_aim)
	_aim.start_aiming()
	assert_eq(_aim.locked_target, enemy)
	enemy.position = Vector3(0, 0, -26)  # beyond the default aim range
	_aim.cycle_target()
	assert_null(_aim.locked_target)
	assert_signal_emitted_with_parameters(_aim, "target_changed", [null])


# --- The lock itself ---


func test_the_lock_persists_while_a_nearer_enemy_appears() -> void:
	var far := _add_enemy(0.0, 6.0)
	await _frames(2)
	_aim.start_aiming()
	assert_eq(_aim.locked_target, far)
	_add_enemy(10.0, 2.0)
	await _frames(3)
	assert_eq(_aim.locked_target, far, "the chosen lock is kept while it stays valid")


func test_a_target_walking_out_of_range_releases_the_lock() -> void:
	_aim.aim_range = 10.0
	var enemy := _add_enemy(0.0, 5.0)
	await _frames(2)
	_aim.start_aiming()
	assert_eq(_aim.locked_target, enemy)
	enemy.position = Vector3(0, 0, -11)
	await _frames(2)
	assert_null(_aim.locked_target)


# --- The aim direction ---


func test_aiming_with_no_enemies_aims_along_the_camera_forward() -> void:
	_aim.start_aiming()
	assert_null(_aim.locked_target)
	assert_eq(_aim.get_aim_direction(), Vector3.FORWARD)
	_aim.stop_aiming()


func test_get_aim_direction_points_at_the_locked_target() -> void:
	var enemy := _add_enemy(25.0, 4.0)
	await _frames(2)
	_aim.start_aiming()
	assert_eq(_aim.locked_target, enemy)
	# The camera is at the origin, so the direction is the normalised
	# target position.
	assert_eq(_aim.get_aim_direction(), enemy.global_position.normalized())
	_aim.stop_aiming()
	assert_eq(_aim.get_aim_direction(), Vector3.FORWARD, "no lock: back to the camera forward")


# --- The input glue ---


func test_the_aim_input_holds_and_releases_the_aim() -> void:
	var left := _add_enemy(-30.0, 5.0)
	var right := _add_enemy(30.0, 6.0)
	await _frames(2)
	_feed(&"next_target", true)
	assert_null(_aim.locked_target, "next_target is ignored while not aiming")
	_feed(&"aim", true)
	assert_true(_aim.is_aiming)
	assert_eq(_aim.locked_target, left)
	_feed(&"next_target", true)
	assert_eq(_aim.locked_target, right, "next_target cycles while aiming")
	_feed(&"aim", false)
	assert_false(_aim.is_aiming)
	assert_null(_aim.locked_target)
