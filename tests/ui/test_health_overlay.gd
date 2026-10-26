extends GutTest

const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/health_overlay.tscn")

var _overlay: HealthOverlay


func before_each() -> void:
	_overlay = OVERLAY_SCENE.instantiate() as HealthOverlay
	add_child_autofree(_overlay)


func test_is_hidden_when_there_is_no_cue() -> void:
	assert_false(_overlay.overlay_rect.visible)


func test_eases_to_its_targets_and_shows() -> void:
	_overlay.set_targets(0.6, 0.4)
	_overlay.tick(0.2)
	assert_gt(_overlay.vignette, 0.0)
	assert_lt(_overlay.vignette, 0.6)
	assert_true(_overlay.overlay_rect.visible)
	_overlay.tick(5.0)
	assert_almost_eq(_overlay.vignette, 0.6, 0.001)
	assert_almost_eq(_overlay.desaturation, 0.4, 0.001)
	var shader_material := _overlay.overlay_rect.material as ShaderMaterial
	assert_almost_eq(float(shader_material.get_shader_parameter(&"vignette")), 0.6, 0.001)
	assert_almost_eq(float(shader_material.get_shader_parameter(&"desaturation")), 0.4, 0.001)


func test_hides_again_once_the_cues_fade_out() -> void:
	_overlay.set_targets(0.6, 0.4)
	_overlay.tick(5.0)
	_overlay.set_targets(0.0, 0.0)
	_overlay.tick(5.0)
	assert_false(_overlay.overlay_rect.visible)


func test_targets_are_clamped() -> void:
	_overlay.set_targets(3.0, -1.0)
	_overlay.tick(10.0)
	assert_eq(_overlay.vignette, 1.0)
	assert_eq(_overlay.desaturation, 0.0)


func test_does_not_block_mouse_input() -> void:
	assert_eq(_overlay.overlay_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
