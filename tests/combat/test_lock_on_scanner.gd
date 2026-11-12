## Tests of the LockOnScanner: one LockOnCandidate per live enemy in the
## scanned group, with a line-of-sight result from the observer and the
## standing state, so LockOn.select can pick from it.

extends GutTest

const DT: float = 1.0 / 60.0
const TEST_GROUP: StringName = &"lock_on_test_enemies"

var _observer: Node3D
var _scanner: LockOnScanner


func before_each() -> void:
	_observer = Node3D.new()
	add_child_autofree(_observer)
	_scanner = LockOnScanner.new()
	_scanner.enemy_group = TEST_GROUP
	add_child_autofree(_scanner)
	await _frames(2)


func _add_enemy(position: Vector3, dummy: Node3D) -> Node3D:
	dummy.position = position
	add_child_autofree(dummy)
	dummy.add_to_group(TEST_GROUP)
	return dummy


func _wall(position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = position
	add_child_autofree(body)


func _candidate_at(candidates: Array[LockOnCandidate], position: Vector3) -> LockOnCandidate:
	for candidate in candidates:
		if candidate.position.is_equal_approx(position):
			return candidate
	assert_true(false, "no candidate at " + str(position))
	return null


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func test_every_live_enemy_in_the_group_is_a_candidate() -> void:
	_add_enemy(Vector3(0, 0, -2), Node3D.new())
	_add_enemy(Vector3(1, 0, -3), Node3D.new())
	_add_enemy(Vector3(-1, 0, -4), Node3D.new())
	await _frames(2)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	assert_eq(candidates.size(), 3)
	for candidate in candidates:
		assert_true(candidate.is_visible)
		assert_true(candidate.is_standing)


func test_a_wall_between_the_observer_and_an_enemy_hides_it() -> void:
	var hidden := _add_enemy(Vector3(0, 0, -3), Node3D.new())
	var aside := _add_enemy(Vector3(3, 0, -1.5), Node3D.new())
	_wall(Vector3(0, 0, -1), Vector3(2, 2, 0.5))
	await _frames(3)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	assert_false(_candidate_at(candidates, hidden.position).is_visible)
	assert_true(_candidate_at(candidates, aside.position).is_visible)


func test_enemies_do_not_block_each_others_sight() -> void:
	var far := _add_enemy(Vector3(0, 0, -4), Node3D.new())
	var close := _add_enemy(Vector3(0, 0, -2), BodiedDummy.new())
	await _frames(2)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	# The ray to the far enemy passes through the close one's body; the
	# group members are excluded, so it still counts as visible.
	assert_true(_candidate_at(candidates, far.position).is_visible)
	assert_true(_candidate_at(candidates, close.position).is_visible)


func test_dead_enemies_are_skipped() -> void:
	_add_enemy(Vector3(0, 0, -2), DeadDummy.new())
	var alive := _add_enemy(Vector3(1, 0, -2), Node3D.new())
	await _frames(2)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	assert_eq(candidates.size(), 1)
	assert_true(candidates[0].position.is_equal_approx(alive.position))


func test_downed_and_staggered_enemies_are_candidates_but_not_standing() -> void:
	var downed := _add_enemy(Vector3(0, 0, -2), DownedDummy.new())
	var staggered := _add_enemy(Vector3(1, 0, -2), StaggeredDummy.new())
	var standing := _add_enemy(Vector3(2, 0, -2), Node3D.new())
	await _frames(2)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	assert_eq(candidates.size(), 3)
	assert_false(_candidate_at(candidates, downed.position).is_standing)
	assert_false(_candidate_at(candidates, staggered.position).is_standing)
	assert_true(_candidate_at(candidates, standing.position).is_standing)


func test_non_node3d_group_members_are_skipped() -> void:
	var stray := Node.new()
	add_child_autofree(stray)
	stray.add_to_group(TEST_GROUP)
	_add_enemy(Vector3(0, 0, -2), Node3D.new())
	await _frames(2)
	var candidates: Array[LockOnCandidate] = _scanner.scan(_observer)
	assert_eq(candidates.size(), 1)


class DeadDummy:
	extends Node3D

	func is_dead() -> bool:
		return true


class BodiedDummy:
	## A group member with a body, so that without the exclusion it would
	## block the sight ray to another enemy.
	extends StaticBody3D

	func _init() -> void:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		shape.shape = box
		add_child(shape)


class DownedDummy:
	extends Node3D

	func is_downed() -> bool:
		return true


class StaggeredDummy:
	extends Node3D

	var is_staggered: bool = true
