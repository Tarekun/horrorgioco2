## Tests for the red edge flash.

extends GutTest

const OVERLAY_SCENE: PackedScene = preload("res://scenes/ui/damage_overlay.tscn")

var _overlay: DamageOverlay


func before_each() -> void:
	_overlay = OVERLAY_SCENE.instantiate() as DamageOverlay
	add_child_autofree(_overlay)


func _shader_intensity() -> float:
	var shader_material := _overlay.flash_rect.material as ShaderMaterial
	return shader_material.get_shader_parameter(&"intensity")


func test_starts_invisible() -> void:
	assert_eq(_overlay.intensity, 0.0)
	assert_false(_overlay.flash_rect.visible)


func test_flash_drives_the_shader_and_shows_the_rect() -> void:
	_overlay.flash(0.7)
	assert_true(_overlay.flash_rect.visible)
	assert_almost_eq(_shader_intensity(), 0.7, 0.001)


func test_flash_fades_out() -> void:
	_overlay.flash(0.5)
	_overlay._process(0.1)
	assert_almost_eq(_overlay.intensity, 0.25, 0.001)
	_overlay._process(1.0)
	assert_eq(_overlay.intensity, 0.0)
	assert_false(_overlay.flash_rect.visible)


func test_weaker_flash_does_not_cut_a_stronger_one() -> void:
	_overlay.flash(0.8)
	_overlay.flash(0.3)
	assert_almost_eq(_overlay.intensity, 0.8, 0.001)


func test_strength_is_clamped() -> void:
	_overlay.flash(5.0)
	assert_eq(_overlay.intensity, 1.0)


func test_faded_never_goes_below_zero() -> void:
	assert_eq(DamageOverlay.faded(0.1, 2.5, 1.0), 0.0)


func test_the_flash_does_not_block_mouse_input() -> void:
	assert_eq(_overlay.flash_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
