## Tests for the Switchboard: throwing it once sets the power flag, the lights
## stutter on and the dormant enemy wakes; a loaded flag puts them in their end
## state straight away.

extends GutTest

const SWITCHBOARD_SCENE: PackedScene = preload("res://scenes/levels/switchboard.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const GROAN: AudioStream = preload("res://assets/audio/machinery_groan.wav")

var _flag: LevelFlag
var _lights: Node3D
var _enemy: Enemy
var _player: Player
var _machinery: AudioStreamPlayer3D


func before_each() -> void:
	SaveSystem.reset()
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_enemy = ENEMY_SCENE.instantiate() as Enemy
	_enemy.is_dormant = true
	_enemy.position = Vector3(3.0, 0.0, -3.0)
	add_child_autofree(_enemy)

	_flag = LevelFlag.new()
	_flag.flag_id = &"power_restored"
	add_child_autofree(_flag)
	_lights = Node3D.new()
	_lights.visible = false
	add_child_autofree(_lights)
	_machinery = AudioStreamPlayer3D.new()
	_machinery.stream = GROAN
	add_child_autofree(_machinery)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _make_switchboard() -> Switchboard:
	var switchboard := SWITCHBOARD_SCENE.instantiate() as Switchboard
	switchboard.power_flag = _flag
	switchboard.lights = _lights
	switchboard.enemy = _enemy
	switchboard.machinery_sound = _machinery
	switchboard.position = Vector3(0.0, 1.0, -1.0)
	add_child_autofree(switchboard)
	return switchboard


func _wait_for_lights(switchboard: Switchboard) -> void:
	await wait_for_signal(switchboard.lights_settled, switchboard.get_stutter_duration() + 2.0)


func test_is_an_interactable_with_its_prompt() -> void:
	var switchboard := _make_switchboard()
	assert_true(switchboard.is_in_group(Interactable.GROUP))
	assert_eq(switchboard.get_prompt(), "Throw the main switch.")
	assert_false(switchboard.is_thrown())


func test_throwing_it_sets_and_records_the_power() -> void:
	var switchboard := _make_switchboard()
	assert_eq(switchboard.interact(_player), "")
	assert_true(switchboard.is_thrown())
	assert_true(_flag.is_set)
	assert_eq(SaveSystem.world.get_state(&"power_restored"), {"is_set": true})


func test_the_lights_stutter_on() -> void:
	var switchboard := _make_switchboard()
	var seen: Array[bool] = []
	switchboard.interact(_player)
	var end: int = Time.get_ticks_msec() + int(switchboard.get_stutter_duration() * 1000.0) + 500
	while Time.get_ticks_msec() < end:
		if seen.is_empty() or seen.back() != _lights.visible:
			seen.append(_lights.visible)
		await get_tree().process_frame
	assert_true(_lights.visible, "on at the end")
	assert_gt(seen.count(false), 0, "goes off between flashes")
	assert_gt(seen.count(true), 1, "flashes more than once")


func test_the_enemy_wakes_alerted_once_the_lights_settle() -> void:
	var switchboard := _make_switchboard()
	switchboard.interact(_player)
	assert_true(_enemy.is_dormant, "still dormant while the lights stutter")
	await _wait_for_lights(switchboard)
	assert_true(_lights.visible)
	assert_false(_enemy.is_dormant)
	assert_true(_enemy.perception.is_alert(), "already alerted")


func test_it_plays_the_switch_and_the_machinery() -> void:
	var switchboard := _make_switchboard()
	var sound := switchboard.get_node("SwitchSound") as AudioStreamPlayer3D
	assert_not_null(sound.stream)
	switchboard.machinery_delay = 0.1
	switchboard.interact(_player)
	assert_true(sound.playing)
	await wait_seconds(0.3)
	assert_true(_machinery.playing)


func test_it_works_once() -> void:
	var switchboard := _make_switchboard()
	watch_signals(_flag)
	switchboard.interact(_player)
	assert_false(switchboard.is_in_group(Interactable.GROUP), "no prompt once thrown")
	switchboard.interact(_player)
	assert_signal_emit_count(_flag, "flag_set", 1)


func test_a_loaded_power_lights_the_room_and_wakes_the_enemy_as_placed() -> void:
	var switchboard := _make_switchboard()
	var placed: Vector3 = _enemy.global_position
	var sound := switchboard.get_node("SwitchSound") as AudioStreamPlayer3D
	_flag.load_state({"is_set": true})
	assert_true(_lights.visible, "on straight away")
	assert_false(switchboard.is_in_group(Interactable.GROUP))
	assert_false(_enemy.is_dormant)
	assert_false(_enemy.perception.is_alert(), "awake, not alerted")
	assert_eq(_enemy.global_position, placed)
	assert_false(sound.playing)
	assert_false(_machinery.playing)


func test_a_flag_set_before_it_is_ready_is_taken_as_loaded() -> void:
	_flag.load_state({"is_set": true})
	var switchboard := _make_switchboard()
	assert_true(_lights.visible)
	assert_false(_enemy.is_dormant)
	assert_false(switchboard.is_in_group(Interactable.GROUP))


func test_a_dead_enemy_stays_a_corpse_on_load() -> void:
	_make_switchboard()
	_enemy.load_state({"is_dead": true, "position": [3.0, 0.0, -3.0], "rotation": [0, 0, 0]})
	_flag.load_state({"is_set": true})
	await get_tree().physics_frame
	assert_true(_enemy.is_dead())
	assert_false(_enemy.is_chasing())


func test_the_power_survives_a_save_and_load() -> void:
	var switchboard := _make_switchboard()
	switchboard.interact(_player)
	var saved: WorldState = SaveSystem.world.copy()
	var level := Node3D.new()
	var flag := LevelFlag.new()
	flag.flag_id = &"power_restored"
	level.add_child(flag)
	var lights := Node3D.new()
	lights.visible = false
	level.add_child(lights)
	var loaded := SWITCHBOARD_SCENE.instantiate() as Switchboard
	loaded.power_flag = flag
	loaded.lights = lights
	level.add_child(loaded)
	add_child_autofree(level)

	saved.apply(level)

	assert_true(loaded.is_thrown())
	assert_true(lights.visible)
	assert_false(loaded.is_in_group(Interactable.GROUP))
