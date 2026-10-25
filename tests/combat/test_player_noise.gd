## The noise the player makes: footsteps by speed and melee hits.

extends CombatSceneTest

var _noise: PlayerNoise
var _heard: Array[float] = []


func before_each() -> void:
	await super.before_each()
	_noise = _player.get_node("PlayerNoise") as PlayerNoise
	_heard.clear()
	var listener := Node.new()
	listener.set_script(preload("res://tests/combat/noise_listener.gd"))
	listener.set(&"sink", _heard)
	listener.add_to_group(NoiseEvent.HEARING_GROUP)
	add_child_autofree(listener)


func test_walking_is_silent() -> void:
	assert_eq(_noise.footstep_radius(1.5), 0.0)


func test_running_makes_a_small_noise() -> void:
	assert_eq(_noise.footstep_radius(3.5), 3.0)


func test_sprinting_makes_a_bigger_noise() -> void:
	assert_eq(_noise.footstep_radius(5.5), 6.0)


func test_a_sprint_in_danger_health_is_still_a_sprint() -> void:
	var danger_sprint: float = _player.sprint_speed * HealthState.DANGER_SPEED_MULTIPLIER
	var danger_run: float = _player.run_speed * HealthState.DANGER_SPEED_MULTIPLIER
	assert_eq(_noise.footstep_radius(danger_sprint), _noise.sprint_radius)
	assert_eq(_noise.footstep_radius(danger_run), _noise.run_radius)


func test_footsteps_emit_noise_at_the_player() -> void:
	_player.model.footstep_taken.emit(5.5)
	assert_eq(_heard, [6.0] as Array[float])
	_player.model.footstep_taken.emit(1.5)
	assert_eq(_heard.size(), 1)


func test_a_melee_hit_is_loud() -> void:
	_combat.hit_landed.emit(_dummy.hurtbox, 8.0)
	assert_eq(_heard, [8.0] as Array[float])


func test_a_swing_that_dealt_nothing_is_quiet() -> void:
	_combat.hit_landed.emit(_dummy.hurtbox, 0.0)
	assert_eq(_heard.size(), 0)
