## Tests for the test level: environment wiring, player and dark interior.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/test_level.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const ENVIRONMENT_PATH: String = "res://assets/data/atmosphere_environment.tres"

var _level: Node3D


func before_each() -> void:
	_level = LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(_level)


func test_environment_enables_volumetric_and_depth_fog() -> void:
	var env := load(ENVIRONMENT_PATH) as Environment
	assert_not_null(env)
	assert_true(env.volumetric_fog_enabled, "volumetric fog")
	assert_true(env.fog_enabled, "depth fog")
	assert_gt(env.volumetric_fog_density, 0.0)


func test_environment_is_dark_so_the_flashlight_leads() -> void:
	var env := load(ENVIRONMENT_PATH) as Environment
	assert_lt(env.ambient_light_energy, 0.3, "low ambient")
	assert_lt(env.tonemap_exposure, 1.0, "dark exposure")
	assert_ne(env.tonemap_mode, Environment.TONE_MAPPER_LINEAR, "filmic or similar tonemap")


func test_environment_avoids_effects_that_are_off_by_default() -> void:
	var env := load(ENVIRONMENT_PATH) as Environment
	assert_false(env.ssr_enabled, "SSR off")
	assert_false(env.sdfgi_enabled, "SDFGI off")
	assert_false(env.ssao_enabled, "SSAO off")
	assert_false(env.glow_enabled, "glow off")


func test_level_uses_the_shared_environment_resource() -> void:
	var world_env := _level.get_node("WorldEnvironment") as WorldEnvironment
	assert_not_null(world_env.environment)
	assert_eq(world_env.environment.resource_path, ENVIRONMENT_PATH)


func test_level_has_player_with_camera_and_outdoor_fog() -> void:
	var player := _level.get_node("Player") as Player
	assert_not_null(player)
	assert_not_null(player.camera_controller)
	assert_eq(_level.get_node("Outdoors").find_children("*", "FogVolume", true, false).size(), 1)


func test_main_scene_contains_the_test_level() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	assert_not_null(main.get_node_or_null("TestLevel/WorldEnvironment"))
