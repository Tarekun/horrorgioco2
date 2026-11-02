extends GutTest

const FADE_SCENE: PackedScene = preload("res://scenes/ui/screen_fade.tscn")

var _fade: ScreenFade


func before_each() -> void:
	_fade = FADE_SCENE.instantiate() as ScreenFade
	add_child_autofree(_fade)


func after_each() -> void:
	get_tree().paused = false


func test_starts_clear() -> void:
	assert_false(_fade.is_dark())
	assert_false(_fade.rect.visible)


func test_covers_the_hud() -> void:
	var hint: CanvasLayer = (
		load("res://scenes/ui/interaction_hint.tscn").instantiate() as CanvasLayer
	)
	assert_gt(_fade.layer, hint.layer)
	hint.free()


func test_fade_out_goes_black_and_fade_in_comes_back() -> void:
	await _fade.fade_out(0.1)
	assert_true(_fade.is_dark())
	assert_eq(_fade.rect.color, Color.BLACK)
	await _fade.fade_in(0.1)
	assert_false(_fade.is_dark())
	assert_false(_fade.rect.visible, "doesn't hide anything once clear")


func test_a_fade_takes_its_time() -> void:
	_fade.fade_out(0.4)
	await wait_physics_frames(2)
	assert_true(_fade.rect.visible)
	assert_false(_fade.is_dark(), "still fading")


func test_no_duration_is_instant() -> void:
	_fade.fade_out(0.0)
	assert_true(_fade.is_dark())
	_fade.fade_in(0.0)
	assert_false(_fade.is_dark())


func test_fades_while_the_game_is_paused() -> void:
	get_tree().paused = true
	await _fade.fade_out(0.1)
	assert_true(_fade.is_dark())
