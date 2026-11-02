## Tests for TensionFlicker: lights, glowing shades and the camera's exposure dip
## together, and all come back as they were.

extends GutTest

var _root: Node3D
var _light: OmniLight3D
var _lamp: MeshInstance3D
var _glow: StandardMaterial3D
var _camera: Camera3D
var _flicker: TensionFlicker


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)
	var lights := Node3D.new()
	lights.name = "Lights"
	_root.add_child(lights)
	_light = OmniLight3D.new()
	_light.light_energy = 2.0
	lights.add_child(_light)
	var lamps := Node3D.new()
	lamps.name = "Lamps"
	_root.add_child(lamps)
	_lamp = MeshInstance3D.new()
	_lamp.mesh = BoxMesh.new()
	_glow = StandardMaterial3D.new()
	_glow.emission_enabled = true
	_glow.emission_energy_multiplier = 1.5
	_lamp.set_surface_override_material(0, _glow)
	lamps.add_child(_lamp)
	_camera = Camera3D.new()
	_root.add_child(_camera)
	_camera.make_current()
	_flicker = TensionFlicker.new()
	_flicker.lights_path = ^"../Lights"
	_flicker.lamps_path = ^"../Lamps"
	_flicker.levels = PackedFloat32Array([0.0, 1.0])
	_flicker.step_seconds = 0.1
	_flicker.screen_dim = 0.5
	_root.add_child(_flicker)


func test_a_level_dims_lights_shades_and_view() -> void:
	_flicker.run()
	assert_true(_flicker.is_flickering())
	_flicker.set_level(0.25)
	assert_almost_eq(_light.light_energy, 0.5, 0.001)
	var dimmed := _lamp.get_surface_override_material(0) as StandardMaterial3D
	assert_ne(dimmed, _glow, "a copy of its own")
	assert_almost_eq(dimmed.emission_energy_multiplier, 0.375, 0.001)
	assert_almost_eq(_glow.emission_energy_multiplier, 1.5, 0.001, "the shared one untouched")
	assert_almost_eq(_camera.attributes.exposure_multiplier, 0.625, 0.001)


func test_everything_is_put_back_after_the_last_step() -> void:
	_flicker.run()
	await wait_seconds(0.4)
	assert_false(_flicker.is_flickering())
	assert_almost_eq(_light.light_energy, 2.0, 0.001)
	assert_eq(_lamp.get_surface_override_material(0), _glow)
	assert_null(_camera.attributes)


func test_missing_groups_are_skipped() -> void:
	_flicker.lights_path = ^"../Nowhere"
	_flicker.lamps_path = NodePath()
	_flicker.run()
	await wait_seconds(0.4)
	assert_almost_eq(_light.light_energy, 2.0, 0.001)
