## Checks every model in assets/models/ against the budgets in docs/design/visual-style.md.
## A model's budget comes from its category, the folder under assets/models/ it sits in.
## Each model's own folder is named after its entry in assets/sources.json, which is either
## a CC0 source or tools/make_kit.py (see tools/build_assets.py).

extends GutTest

const MODELS_DIR: String = "res://assets/models/"
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
			assert_eq(AssetRules.material_problem(material), "", name)
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
			var texture_path: String = texture.resource_path
			assert_eq(AssetRules.import_problem(texture_path), "", texture_path)
		model.free()


func test_shared_materials_are_used() -> void:
	# A surface named after a shared material must get the .tres on import,
	# not the flat grey the generator gives it.
	for path in _model_paths():
		var model := _instantiate(path)
		for material in _materials(model):
			var shared: String = AssetRules.MATERIALS_DIR.path_join(
				material.resource_name + ".tres"
			)
			if ResourceLoader.exists(shared):
				assert_eq(material.resource_path, shared, path)
		model.free()


func test_every_model_has_a_source() -> void:
	var sources: Dictionary[String, Dictionary] = AssetRules.sources("models")
	for path in _model_paths():
		var name: String = _entry_name(path)
		assert_has(sources, name, "%s is not in %s" % [path, AssetRules.SOURCES_PATH])
		if not sources.has(name):
			continue
		var entry: Dictionary = sources[name]
		assert_eq(entry.get("category"), _category(path), "%s category" % name)
		assert_eq(AssetRules.source_problem(entry), "", name)


func test_every_source_has_been_built() -> void:
	var built: Dictionary[String, bool] = {}
	for path in _model_paths():
		built[_entry_name(path)] = true
	for name in AssetRules.sources("models"):
		assert_true(built.has(name), "%s is in the manifest but not in %s" % [name, MODELS_DIR])


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


## The manifest entry a model comes from: the folder it sits in.
func _entry_name(path: String) -> String:
	return path.get_base_dir().get_file()


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
