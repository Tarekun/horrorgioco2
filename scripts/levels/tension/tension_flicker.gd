## A tension action that flickers a floor's lamps once and leaves them on.
##
## The hotel's lamps are baked into its lightmap (light_bake_mode static): their
## energy still lights dynamic objects such as the player and the doors, but not
## the lightmapped walls and floors, which keep their baked light. So the flicker
## works three ways at once, step by step through `levels`:
## - the energy of every Light3D under `lights_path`, for dynamic objects;
## - the emission of the glowing shades under `lamps_path`, so the lamps
##   themselves go dark;
## - the exposure of the current camera, so the whole view dims with them,
##   lightmapped surfaces included.
## Everything is put back as it was after the last step.
##
## The paths name the level's groups by name, so a rerun of tools/dress_hotel.gd,
## which rebuilds those groups with the same names, keeps them working. Missing
## nodes are skipped.

class_name TensionFlicker
extends TensionAction

## The group whose lights flicker (the hotel's Lights/SecondFloor).
@export var lights_path: NodePath

## The group whose glowing lamp shades flicker (the hotel's Props/SecondFloor).
@export var lamps_path: NodePath

## Brightness at each step, 1 being as lit and 0 out. The lamps return to 1
## after the last step.
@export var levels: PackedFloat32Array = PackedFloat32Array([0.1, 0.7, 0.0, 0.5, 0.05, 1.0])

## Seconds each step lasts.
@export var step_seconds: float = 0.07

## How much the whole view darkens with the lamps fully out: 0 not at all, 1 to black.
@export_range(0.0, 1.0) var screen_dim: float = 0.6

var _lights: Array[Light3D] = []
var _energies: Array[float] = []
var _meshes: Array[MeshInstance3D] = []
var _surfaces: Array[int] = []
var _originals: Array[Material] = []
var _dimmed: Array[StandardMaterial3D] = []
var _emissions: Array[float] = []
var _camera: Camera3D
var _camera_attributes: CameraAttributes
var _exposure: CameraAttributes
var _sequence: Tween


## Whether a flicker is under way.
func is_flickering() -> bool:
	return _sequence != null


## Sets every lamp to `level` of its brightness (1 as lit, 0 out). Only works
## during a flicker, which knows what to put back.
func set_level(level: float) -> void:
	for i in _lights.size():
		if is_instance_valid(_lights[i]):
			_lights[i].light_energy = _energies[i] * level
	for i in _dimmed.size():
		_dimmed[i].emission_energy_multiplier = _emissions[i] * level
	if _exposure:
		_exposure.exposure_multiplier = 1.0 - screen_dim * (1.0 - level)


func _start() -> void:
	_collect_lights()
	_collect_lamps()
	_dim_camera()
	_sequence = create_tween()
	for level: float in levels:
		_sequence.tween_callback(set_level.bind(level))
		_sequence.tween_interval(step_seconds)
	_sequence.tween_callback(_end)


func _end() -> void:
	if _sequence:
		_sequence.kill()
		_sequence = null
	for i in _lights.size():
		if is_instance_valid(_lights[i]):
			_lights[i].light_energy = _energies[i]
	for i in _meshes.size():
		if is_instance_valid(_meshes[i]):
			_meshes[i].set_surface_override_material(_surfaces[i], _originals[i])
	if is_instance_valid(_camera):
		_camera.attributes = _camera_attributes
	_lights.clear()
	_energies.clear()
	_meshes.clear()
	_surfaces.clear()
	_originals.clear()
	_dimmed.clear()
	_emissions.clear()
	_camera = null
	_camera_attributes = null
	_exposure = null


func _collect_lights() -> void:
	var group: Node = get_node_or_null(lights_path) if not lights_path.is_empty() else null
	if group == null:
		return
	for node: Node in group.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		_lights.append(light)
		_energies.append(light.light_energy)


## Gives each glowing shade its own copy of its material to dim, so the lamps of
## other floors sharing the material keep glowing.
func _collect_lamps() -> void:
	var group: Node = get_node_or_null(lamps_path) if not lamps_path.is_empty() else null
	if group == null:
		return
	var copies: Dictionary[Material, StandardMaterial3D] = {}
	for node: Node in group.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.get_surface_override_material_count():
			var original := mesh.get_surface_override_material(surface) as StandardMaterial3D
			if original == null or not original.emission_enabled:
				continue
			if not copies.has(original):
				var copy := original.duplicate() as StandardMaterial3D
				copies[original] = copy
				_dimmed.append(copy)
				_emissions.append(copy.emission_energy_multiplier)
			_meshes.append(mesh)
			_surfaces.append(surface)
			_originals.append(original)
			mesh.set_surface_override_material(surface, copies[original])


## Gives the current camera exposure attributes of its own to dim, keeping the
## ones it had to put back.
func _dim_camera() -> void:
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	_camera_attributes = _camera.attributes
	if _camera_attributes:
		_exposure = _camera_attributes.duplicate() as CameraAttributes
	else:
		_exposure = CameraAttributesPractical.new()
	_camera.attributes = _exposure
