## Tests for the grain and vignette post-processing layer.

extends GutTest

const POST_SCENE: PackedScene = preload("res://scenes/effects/post_process.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _post: PostProcess


func before_each() -> void:
	_post = POST_SCENE.instantiate() as PostProcess
	add_child_autofree(_post)


func _material() -> ShaderMaterial:
	return _post.screen_rect.material as ShaderMaterial


func test_screen_rect_is_assigned_and_covers_the_screen() -> void:
	assert_not_null(_post.screen_rect, "screen_rect wired in the scene")
	assert_eq(_post.screen_rect.anchor_right, 1.0)
	assert_eq(_post.screen_rect.anchor_bottom, 1.0)
	assert_eq(_post.screen_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never eats input")


func test_shader_material_and_shader_are_present() -> void:
	assert_not_null(_material())
	assert_not_null(_material().shader)
	assert_string_contains(_material().shader.code, "grain_intensity")
	assert_string_contains(_material().shader.code, "vignette_intensity")


func test_defaults_reach_the_shader() -> void:
	assert_almost_eq(
		float(_material().get_shader_parameter(&"grain_intensity")), _post.grain_intensity, 0.0001
	)
	assert_almost_eq(
		float(_material().get_shader_parameter(&"vignette_intensity")),
		_post.vignette_intensity,
		0.0001
	)


func test_changing_exported_values_updates_the_shader() -> void:
	_post.grain_intensity = 0.2
	_post.vignette_intensity = 0.9
	_post.vignette_radius = 0.3
	_post.vignette_softness = 0.4
	assert_almost_eq(float(_material().get_shader_parameter(&"grain_intensity")), 0.2, 0.0001)
	assert_almost_eq(float(_material().get_shader_parameter(&"vignette_intensity")), 0.9, 0.0001)
	assert_almost_eq(float(_material().get_shader_parameter(&"vignette_radius")), 0.3, 0.0001)
	assert_almost_eq(float(_material().get_shader_parameter(&"vignette_softness")), 0.4, 0.0001)


func test_parameters_match_shader_uniforms() -> void:
	for key: StringName in _post.get_shader_parameters():
		assert_string_contains(_material().shader.code, "uniform float %s" % key)


func test_main_scene_applies_it_to_the_whole_game() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	assert_true(main.get_node_or_null("PostProcess") is PostProcess)
