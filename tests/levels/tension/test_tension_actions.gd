## Tests for the tension actions: sounds, particles, swaying, turning and
## revealing.

extends GutTest

const ONE_SHOT: AudioStream = preload("res://assets/audio/creak.wav")
const LOOP: AudioStream = preload("res://assets/audio/phone_ring.wav")


func test_a_sound_plays_on_its_bus_and_a_loop_stops_after_its_duration() -> void:
	var sound := TensionSound.new()
	sound.stream = LOOP
	sound.duration = 0.2
	add_child_autofree(sound)
	assert_eq(sound.get_player().bus, AudioBuses.SFX)
	assert_false(sound.is_playing())
	sound.run()
	assert_true(sound.is_playing())
	await wait_seconds(0.35)
	assert_false(sound.is_playing(), "stopped after its duration")


func test_a_sound_can_be_stopped_and_routed_to_ambience() -> void:
	var sound := TensionSound.new()
	sound.stream = LOOP
	sound.bus = AudioBuses.AMBIENCE
	add_child_autofree(sound)
	assert_eq(sound.get_player().bus, AudioBuses.AMBIENCE)
	sound.run()
	sound.stop()
	assert_false(sound.is_playing())


func test_a_travelling_sound_moves_while_it_plays() -> void:
	var sound := TensionSound.new()
	sound.stream = ONE_SHOT
	sound.travel = Vector3(-4, 0, 0)
	add_child_autofree(sound)
	sound.run()
	await wait_seconds(ONE_SHOT.get_length() + 0.2)
	assert_almost_eq(sound.get_player().position.x, -4.0, 0.01)


func test_particles_emit_for_their_duration() -> void:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	add_child_autofree(particles)
	var action := TensionParticles.new()
	action.particles = particles
	action.duration = 0.2
	add_child_autofree(action)
	action.run()
	assert_true(particles.emitting)
	await wait_seconds(0.35)
	assert_false(particles.emitting)


func test_the_sway_angle_leans_swings_and_dies_away() -> void:
	assert_almost_eq(TensionSway.angle_at(0.0, 10.0, 0.0, 2.0, 0.0), 0.0, 0.001)
	assert_almost_eq(TensionSway.angle_at(0.5, 10.0, 0.0, 2.0, 0.0), 10.0, 0.001, "peak")
	assert_almost_eq(TensionSway.angle_at(1.5, 10.0, 0.0, 2.0, 0.0), -10.0, 0.001)
	assert_almost_eq(TensionSway.angle_at(2.0, 0.0, -6.0, 2.0, 0.0), -6.0, 0.001, "lean")
	assert_almost_eq(TensionSway.angle_at(4.5, 10.0, 0.0, 2.0, 4.0), 0.0, 0.001, "at rest")
	assert_almost_eq(TensionSway.angle_at(100.5, 10.0, 0.0, 2.0, 0.0), 10.0, 0.01, "for good")


func test_a_sway_comes_back_to_rest() -> void:
	var target := Node3D.new()
	add_child_autofree(target)
	var sway := TensionSway.new()
	sway.target = target
	sway.period = 0.2
	sway.degrees = 20.0
	sway.duration = 0.3
	add_child_autofree(sway)
	sway.run()
	await wait_seconds(0.05)
	assert_ne(target.basis, Basis.IDENTITY, "swinging")
	await wait_seconds(0.4)
	assert_eq(target.basis, Basis.IDENTITY, "back at rest")


func test_a_turn_ends_turned() -> void:
	var hinge := Node3D.new()
	add_child_autofree(hinge)
	var turn := TensionTurn.new()
	turn.target = hinge
	turn.degrees = -75.0
	turn.duration = 0.2
	add_child_autofree(turn)
	turn.run()
	await wait_seconds(0.35)
	assert_almost_eq(rad_to_deg(hinge.rotation.y), -75.0, 0.5)


func test_a_reveal_shows_and_hides() -> void:
	var flame := Node3D.new()
	flame.visible = false
	add_child_autofree(flame)
	var reveal := TensionReveal.new()
	reveal.targets = [flame]
	add_child_autofree(reveal)
	reveal.run()
	assert_true(flame.visible)
	reveal.stop()
	assert_false(flame.visible)
