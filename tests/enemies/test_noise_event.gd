extends GutTest


class Listener:
	extends Node
	var heard: Array[Vector4] = []

	func hear_noise(position: Vector3, radius: float) -> void:
		heard.append(Vector4(position.x, position.y, position.z, radius))


func test_is_audible_within_the_radius() -> void:
	assert_true(NoiseEvent.is_audible(Vector3.ZERO, Vector3(0, 0, 5), 6.0))
	assert_true(NoiseEvent.is_audible(Vector3.ZERO, Vector3(0, 0, 6), 6.0))
	assert_false(NoiseEvent.is_audible(Vector3.ZERO, Vector3(0, 0, 6.5), 6.0))


func test_zero_radius_is_never_audible() -> void:
	assert_false(NoiseEvent.is_audible(Vector3.ZERO, Vector3.ZERO, 0.0))


func test_emit_reaches_the_hearing_group() -> void:
	var listener := Listener.new()
	listener.add_to_group(NoiseEvent.HEARING_GROUP)
	add_child_autofree(listener)
	NoiseEvent.emit_noise(get_tree(), Vector3(1, 0, 2), 8.0)
	assert_eq(listener.heard.size(), 1)
	assert_eq(listener.heard[0], Vector4(1, 0, 2, 8))


func test_a_silent_noise_is_not_emitted() -> void:
	var listener := Listener.new()
	listener.add_to_group(NoiseEvent.HEARING_GROUP)
	add_child_autofree(listener)
	NoiseEvent.emit_noise(get_tree(), Vector3.ZERO, 0.0)
	assert_eq(listener.heard.size(), 0)


func test_spec_radii() -> void:
	assert_eq(NoiseEvent.MELEE_HIT_RADIUS, 8.0)
	assert_eq(NoiseEvent.SPRINT_FOOTSTEP_RADIUS, 6.0)
	assert_eq(NoiseEvent.RUN_FOOTSTEP_RADIUS, 3.0)
	assert_eq(NoiseEvent.PISTOL_SHOT_RADIUS, 25.0)
	assert_eq(NoiseEvent.SHOTGUN_SHOT_RADIUS, 30.0)
