## Checks every model in assets/models/ against the budgets in docs/design/visual-style.md.
## A model's budget comes from its category, the folder under assets/models/ it sits in, and
## each model needs a CC0 entry in assets/sources.json (see tools/build_assets.py).

extends GutTest

const MODELS_DIR: String = "res://assets/models/"
const SOURCES_PATH: String = "res://assets/sources.json"
const MODEL_EXTENSIONS: Array[String] = ["gltf", "glb"]

## Most triangles a model of each category may have.
const MAX_TRIANGLES: Dictionary[String, int] = {
	"characters": 6000,
	"locals": 4000,
	"monsters": 4000,
	"bosses": 8000,
	"props": 500,
	"hero_props": 1500,
	# visual-style.md sets no budget per kit piece; a wall or stair piece stays near a hero prop.
	"environment": 1500,
}

## Longest texture side, in pixels, for each category.
const MAX_TEXTURE_SIZE: Dictionary[String, int] = {
	"characters": 512,
	"locals": 512,
	"monsters": 512,
	"bosses": 512,
	"props": 256,
	"hero_props": 256,
	"environment": 512,
}

## Texture import mode for VRAM compression (ResourceImporterTexture's compress/mode).
const COMPRESS_VRAM: int = 2


func test_budget_tables_cover_the_same_categories() -> void:
	assert_eq(MAX_TRIANGLES.keys(), MAX_TEXTURE_SIZE.keys())


func test_counts_triangles_of_every_mesh() -> void:
	var root := Node3D.new()
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	root.add_child(box)
	var nested := MeshInstance3D.new()
	nested.mesh = QuadMesh.new()
	box.add_child(nested)
	assert_eq(_count_triangles(root), 14)
	root.free()


func test_every_model_is_in_a_category() -> void:
	for path in _model_paths():
		assert_has(MAX_TRIANGLES, _category(path), "%s is not in a category folder" % path)


func test_models_are_within_triangle_budget() -> void:
	for path in _model_paths():
		var model := _instantiate(path)
		var triangles: int = _count_triangles(model)
		var budget: int = MAX_TRIANGLES.get(_category(path), 0)
		assert_between(triangles, 1, budget, "%s has %d triangles" % [path, triangles])
		model.free()


func test_materials_are_albedo_only() -> void:
	for path in _model_paths():
		var model := _instantiate(path)
		for material in _materials(model):
			var name: String = "%s (%s)" % [path, material.resource_name]
			assert_true(material is StandardMaterial3D, "%s is not a StandardMaterial3D" % name)
			var standard := material as StandardMaterial3D
			if standard == null:
				continue
			assert_false(standard.normal_enabled, "%s uses a normal map" % name)
			assert_null(standard.roughness_texture, "%s has a roughness map" % name)
			assert_null(standard.metallic_texture, "%s has a metallic map" % name)
			assert_false(standard.ao_enabled, "%s uses an occlusion map" % name)
			assert_false(standard.heightmap_enabled, "%s uses a height map" % name)
		model.free()


func test_textures_are_within_size_budget() -> void:
	for path in _model_paths():
		var model := _instantiate(path)
		var budget: int = MAX_TEXTURE_SIZE.get(_category(path), 0)
		for texture in _textures(model):
			var size: int = maxi(texture.get_width(), texture.get_height())
			assert_lte(size, budget, "%s is %d px" % [texture.resource_path, size])
		model.free()


func test_textures_import_vram_compressed_with_mipmaps() -> void:
	for path in _model_paths():
		var model := _instantiate(path)
		for texture in _textures(model):
			var config := ConfigFile.new()
			var import_path: String = texture.resource_path + ".import"
			assert_eq(config.load(import_path), OK, "%s is missing" % import_path)
			assert_eq(config.get_value("params", "compress/mode", 0), COMPRESS_VRAM, import_path)
			assert_true(config.get_value("params", "mipmaps/generate", false), import_path)
		model.free()


func test_every_model_has_a_cc0_source() -> void:
	var sources: Dictionary[String, Dictionary] = _sources()
	for path in _model_paths():
		var name: String = path.get_file().get_basename()
		assert_has(sources, name, "%s is not in %s" % [path, SOURCES_PATH])
		if not sources.has(name):
			continue
		var entry: Dictionary = sources[name]
		assert_eq(entry.get("category"), _category(path), "%s category" % name)
		assert_eq(entry.get("license"), "CC0", "%s license" % name)
		assert_string_starts_with(str(entry.get("source", "")), "https://", "%s source" % name)


func _model_paths(dir: String = MODELS_DIR) -> Array[String]:
	var paths: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		paths.append_array(_model_paths(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in MODEL_EXTENSIONS:
			paths.append(dir.path_join(file))
	return paths


func _category(path: String) -> String:
	return path.trim_prefix(MODELS_DIR).get_slice("/", 0)


func _instantiate(path: String) -> Node:
	var scene := load(path) as PackedScene
	assert_not_null(scene, "%s did not load" % path)
	return scene.instantiate() if scene else Node.new()


func _mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root as MeshInstance3D)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node as MeshInstance3D)
	return meshes


func _count_triangles(root: Node) -> int:
	var total: int = 0
	for instance in _mesh_instances(root):
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += (indices.size() if not indices.is_empty() else vertices.size()) / 3
	return total


func _materials(root: Node) -> Array[Material]:
	var materials: Array[Material] = []
	for instance in _mesh_instances(root):
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material: Material = instance.get_active_material(surface)
			if material != null and material not in materials:
				materials.append(material)
	return materials


func _textures(root: Node) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for material in _materials(root):
		var standard := material as StandardMaterial3D
		if standard == null:
			continue
		for texture: Texture2D in [standard.albedo_texture, standard.emission_texture]:
			if texture != null and texture not in textures:
				textures.append(texture)
	return textures


func _sources() -> Dictionary[String, Dictionary]:
	var sources: Dictionary[String, Dictionary] = {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCES_PATH))
	assert_true(data is Dictionary, "%s is not a JSON object" % SOURCES_PATH)
	if data is Dictionary:
		for entry: Dictionary in (data as Dictionary).get("models", []):
			sources[str(entry.get("name"))] = entry
	return sources
