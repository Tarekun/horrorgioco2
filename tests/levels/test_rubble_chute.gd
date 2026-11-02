## Tests for the rubble chute from room 15 (1F) down to the GF building site,
## against "The chute" in docs/design/slice.md.

extends "res://tests/levels/hotel_level_test.gd"

## The GF building site and room 15 right above it: x 6..12, z 1..7.
const BUILDING_SITE: Rect2 = Rect2(6, 1, 6, 6)
const ROOM_15: Rect2 = BUILDING_SITE

## Where the player stands to use the chute's top in room 15, facing it.
const BY_THE_TOP: Vector3 = Vector3(9, FIRST_Y + 0.05, 3.5)

## Where the player stands on GF by the skip, facing the chute's mouth.
const BY_THE_MOUTH: Vector3 = Vector3(9, GROUND_Y + 0.05, 3.15)

## Most seconds a test waits for the slide to end.
const MAX_WAIT: float = 10.0

## How far from the navmesh a spot the player stands on may be.
const REACH_SLACK: float = 0.2

var _chute: RubbleChute
var _player: Player
var _interaction: PlayerInteraction


func before_each() -> void:
	await super.before_each()
	_chute = _level.get_node("RubbleChute") as RubbleChute
	_player = _level.get_node("Player") as Player
	_interaction = _player.get_node("PlayerInteraction") as PlayerInteraction
	# Short, so the tests don't sit through the whole sequence.
	_chute.fade_out_time = 0.05
	_chute.dark_time = 0.1
	_chute.fade_in_time = 0.05


func after_each() -> void:
	super.after_each()
	Input.action_release(&"move_forward")
	get_tree().paused = false


## Puts the player at `at` facing +Z, toward the chute.
func _stand(at: Vector3) -> void:
	_player.global_position = at
	_player.rotation.y = PI
	_player.velocity = Vector3.ZERO


## Waits until `predicate` is true. GUT's own waits stand still while the game
## is paused, so this counts frames, which go on.
func _wait_for(predicate: Callable) -> void:
	var frames: int = 0
	while not predicate.call() and frames < MAX_WAIT * 60:
		await get_tree().process_frame
		frames += 1


func _slide_down() -> void:
	_stand(BY_THE_TOP)
	_chute.interact(_player)
	await wait_for_signal(_chute.landed, MAX_WAIT)


func test_the_top_is_in_room_15_and_says_slide_down() -> void:
	var top: Vector3 = _chute.global_position
	assert_eq(_floor_of(top), FIRST_Y)
	assert_true(ROOM_15.has_point(Vector2(top.x, top.z)), "in room 15")
	assert_eq(_chute.get_prompt(), "Slide down.")
	assert_true(_chute.is_in_group(Interactable.GROUP))


func test_the_player_in_room_15_can_use_the_top() -> void:
	_stand(BY_THE_TOP)
	_interaction.update_focus()
	assert_eq(_interaction.focus, _chute, "the top, not the mouth on the floor below")
	assert_lt(_distance_from_floor(BY_THE_TOP), REACH_SLACK, "a spot the player can reach")


func test_sliding_puts_the_player_on_the_gf_navmesh_in_the_building_site() -> void:
	await _slide_down()
	var at: Vector3 = _player.global_position
	assert_eq(_floor_of(at), GROUND_Y, "on GF")
	assert_true(BUILDING_SITE.has_point(Vector2(at.x, at.z)), "in the building site: %s" % at)
	assert_lt(_distance_from_floor(at), 0.1, "on the navmesh")
	assert_almost_eq(at, _chute.landing.global_position, Vector3.ONE * 0.01)


func test_the_player_lands_facing_the_door_to_the_corridor() -> void:
	await _slide_down()
	var door: Door = _door(&"door_building_site_gf")
	var to_door: Vector3 = door.global_position - _player.global_position
	to_door.y = 0.0
	var forward: Vector3 = -_player.global_basis.z
	assert_lt(rad_to_deg(forward.angle_to(to_door)), 30.0)


func test_sliding_goes_dark_with_the_noise_and_locks_the_player() -> void:
	_stand(BY_THE_TOP)
	watch_signals(_chute)
	_chute.fade_out_time = 0.3
	_interaction.update_focus()
	assert_true(_interaction.interact())
	assert_signal_emitted(_chute, "slide_started")
	assert_true(_chute.is_sliding)
	assert_true(get_tree().paused, "the game is paused, so no input reaches the player")
	assert_true(_chute.slide_noise.playing, "the noise of the slide")
	var start: Vector3 = _player.global_position
	Input.action_press(&"move_forward")
	await wait_physics_frames(5)
	assert_eq(_player.global_position, start, "the player doesn't move meanwhile")
	Input.action_release(&"move_forward")
	await _wait_for(_chute.screen_fade.is_dark)
	assert_true(_chute.screen_fade.is_dark(), "the screen goes dark")
	assert_true(get_tree().paused)
	await wait_for_signal(_chute.landed, MAX_WAIT)
	assert_false(_chute.is_sliding)
	assert_false(get_tree().paused, "control comes back at the end")
	assert_false(_chute.screen_fade.is_dark())


func test_the_mouth_on_gf_cant_be_climbed() -> void:
	_stand(BY_THE_MOUTH)
	_interaction.update_focus()
	assert_eq(_interaction.focus, _chute.mouth, "the mouth, not the top on the floor above")
	watch_signals(_chute)
	var message: String = _chute.mouth.interact(_player)
	assert_eq(message, "No way back up that.")
	assert_signal_not_emitted(_chute, "slide_started")
	assert_false(get_tree().paused)
	assert_eq(_floor_of(_player.global_position), GROUND_Y, "still on GF")


func test_the_mouth_is_over_the_skip_in_the_building_site() -> void:
	var mouth: Vector3 = _chute.mouth.global_position
	assert_eq(_floor_of(mouth), GROUND_Y)
	assert_true(BUILDING_SITE.has_point(Vector2(mouth.x, mouth.z)))
	assert_lt(_distance_from_floor(BY_THE_MOUTH), REACH_SLACK, "a spot the player can reach")


func test_it_stays_usable() -> void:
	await _slide_down()
	assert_eq(_floor_of(_player.global_position), GROUND_Y)
	watch_signals(_chute)
	await _slide_down()
	assert_signal_emitted(_chute, "landed", "slides again")
	assert_eq(_floor_of(_player.global_position), GROUND_Y)
	assert_false(get_tree().paused)


func test_a_second_use_during_the_slide_does_nothing() -> void:
	_stand(BY_THE_TOP)
	watch_signals(_chute)
	_chute.interact(_player)
	_chute.interact(_player)
	assert_signal_emit_count(_chute, "slide_started", 1)
	await wait_for_signal(_chute.landed, MAX_WAIT)
	assert_false(get_tree().paused)


func test_sliding_leaves_a_pause_it_didnt_start() -> void:
	_stand(BY_THE_TOP)
	get_tree().paused = true
	_chute.interact(_player)
	await wait_for_signal(_chute.landed, MAX_WAIT)
	assert_true(get_tree().paused)
