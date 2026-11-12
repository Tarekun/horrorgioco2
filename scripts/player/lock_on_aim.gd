## The player's lock-on aiming: while `aim` is held, the player is locked on
## to the best valid enemy — the one LockOn.select picks from the scanner's
## candidates — and `next_target` cycles through the valid ones in angle
## order. The lock persists as long as the locked enemy stays valid, even
## when a nearer enemy appears; a fresh lock is acquired only when nothing
## is locked or the locked enemy stops being valid.
##
## The component exposes its state (`is_aiming`, `locked_target`) and the
## direction to aim along (`get_aim_direction`), and reports changes through
## `aim_started`, `aim_ended` and `target_changed`. It keeps no other state;
## the scanner and LockOn are stateless, so the component stays testable
## with a plain camera and a test enemy group.

class_name LockOnAim
extends Node

## Emitted when the player starts aiming and the lock becomes active.
signal aim_started
## Emitted when the player stops aiming and the lock is released.
signal aim_ended
## Emitted whenever the locked target changes, with the new target (null
## when the lock is released).
signal target_changed(target: Node3D)

## The scanner that builds the candidates to lock on to.
@export var scanner: LockOnScanner
## The camera the aim is relative to: its position is the origin and its
## forward the direction of the aim.
@export var camera: Camera3D
## Until the real weapons land (#14/#13), the aim range is a plain export.
@export var aim_range: float = 25.0

## Whether the player is currently aiming.
var is_aiming: bool = false
## The enemy the player is locked on to, or null.
var locked_target: Node3D = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"aim"):
		start_aiming()
	elif event.is_action_released(&"aim"):
		stop_aiming()
	elif is_aiming and event.is_action_pressed(&"next_target"):
		cycle_target()


func _physics_process(_delta: float) -> void:
	if is_aiming:
		_refresh_lock()


## Starts aiming. Idempotent: while already aiming, nothing happens.
func start_aiming() -> void:
	if is_aiming:
		return
	is_aiming = true
	aim_started.emit()
	_refresh_lock()


## Stops aiming and releases the lock. Idempotent: while not aiming,
## nothing happens.
func stop_aiming() -> void:
	if not is_aiming:
		return
	is_aiming = false
	_release_lock()
	aim_ended.emit()


## Locks on to the next valid candidate in angle order, as in
## LockOn.cycle. Only meaningful while aiming with a lock; with no valid
## candidates the lock is released.
func cycle_target() -> void:
	if scanner == null or camera == null:
		return
	var candidates: Array[LockOnCandidate] = scanner.scan(camera)
	var index: int = LockOn.cycle(
		_current_index(candidates), camera.global_position, _camera_forward(), aim_range, candidates
	)
	_set_locked(candidates, index)


## The direction the player aims along: toward the locked target when there
## is one further than ~1 mm from the camera, the camera's forward
## otherwise.
func get_aim_direction() -> Vector3:
	if locked_target != null and camera != null:
		var offset: Vector3 = locked_target.global_position - camera.global_position
		if offset.length() > LockOn.MIN_DISTANCE:
			return offset.normalized()
	return _camera_forward()


## Re-acquires the lock from a fresh scan: the locked target is kept while
## it is still valid, otherwise the nearest valid candidate is locked (or
## the lock is released when nothing is valid).
func _refresh_lock() -> void:
	if scanner == null or camera == null:
		return
	var candidates: Array[LockOnCandidate] = scanner.scan(camera)
	var position: Vector3 = camera.global_position
	var forward: Vector3 = _camera_forward()
	var current: int = _current_index(candidates)
	var valid: Array[int] = LockOn.ordered(position, forward, aim_range, candidates)
	var index: int = (
		current
		if current != -1 and valid.has(current)
		else LockOn.select(position, forward, aim_range, candidates)
	)
	_set_locked(candidates, index)


## The index in `candidates` of the candidate built from `locked_target`,
## or -1 when nothing is locked or it is no longer among the candidates.
func _current_index(candidates: Array[LockOnCandidate]) -> int:
	for i: int in candidates.size():
		if candidates[i].node == locked_target:
			return i
	return -1


## The camera's forward, or -Z when there is no camera.
func _camera_forward() -> Vector3:
	if camera == null:
		return Vector3.FORWARD
	return camera.global_transform.basis * Vector3.FORWARD


## Locks on to the candidate at `index` (-1 for none), emitting
## target_changed when the locked node actually changes.
func _set_locked(candidates: Array[LockOnCandidate], index: int) -> void:
	var target: Node3D = candidates[index].node if index != -1 else null
	if target != locked_target:
		locked_target = target
		target_changed.emit(target)


## Releases the lock, emitting target_changed(null) when there was one.
func _release_lock() -> void:
	if locked_target == null:
		return
	locked_target = null
	target_changed.emit(null)
