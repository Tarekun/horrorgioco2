## Checks the environment textures in assets/textures/ and the shared materials in
## assets/materials/ against docs/design/visual-style.md, and each texture's CC0 entry
## in assets/sources.json (see tools/build_assets.py).

extends GutTest

const TEXTURES_DIR: String = "res://assets/textures/"
const MATERIALS_DIR: String = "res://assets/materials/"
const TEXTURE_EXTENSIONS: Array[String] = ["jpg", "png"]

## Environment tiles are 256 px, or 512 for large hero surfaces.
const MAX_TEXTURE_SIZE: int = 512


func test_every_texture_has_a_cc0_source() -> void:
	var sources: Dictionary[String, Dictionary] = AssetRules.sources("textures")
	for path in _texture_paths():
		var name: String = path.get_file().get_basename()
		assert_has(sources, name, "%s is not in %s" % [path, AssetRules.SOURCES_PATH])
		if sources.has(name):
			assert_eq(AssetRules.source_problem(sources[name]), "", name)


func test_every_source_has_been_built() -> void:
	for name in AssetRules.sources("textures"):
		var built: bool = TEXTURE_EXTENSIONS.any(
			func(extension: String) -> bool:
				return FileAccess.file_exists(TEXTURES_DIR.path_join("%s.%s" % [name, extension]))
		)
		assert_true(built, "%s is in the manifest but not in %s" % [name, TEXTURES_DIR])


func test_textures_are_within_size_budget() -> void:
	for path in _texture_paths():
		var texture := load(path) as Texture2D
		assert_not_null(texture, "%s did not load" % path)
		if texture == null:
			continue
		var size := Vector2i(texture.get_width(), texture.get_height())
		assert_lte(maxi(size.x, size.y), MAX_TEXTURE_SIZE, "%s is %s px" % [path, size])
		assert_true(
			_is_power_of_two(size.x) and _is_power_of_two(size.y), "%s is %s" % [path, size]
		)


func test_textures_import_vram_compressed_with_mipmaps() -> void:
	for path in _texture_paths():
		assert_eq(AssetRules.import_problem(path), "", path)


func test_materials_are_albedo_only() -> void:
	var paths: Array[String] = _material_paths()
	assert_gt(paths.size(), 0, "no materials in %s" % MATERIALS_DIR)
	for path in paths:
		assert_eq(AssetRules.material_problem(load(path) as Material), "", path)


func test_materials_use_the_hotel_textures() -> void:
	for path in _material_paths():
		var material := load(path) as StandardMaterial3D
		if material == null:
			continue
		var texture: Texture2D = material.albedo_texture
		assert_not_null(texture, "%s has no albedo texture" % path)
		if texture != null:
			assert_string_starts_with(texture.resource_path, TEXTURES_DIR, path)


func test_materials_filter_trilinear_and_anisotropic() -> void:
	# The retro filter (#100) turns anisotropic filtering off through the viewport.
	for path in _material_paths():
		var material := load(path) as StandardMaterial3D
		if material != null:
			assert_eq(
				material.texture_filter,
				BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,
				path
			)


func test_detects_powers_of_two() -> void:
	assert_true(_is_power_of_two(256))
	assert_false(_is_power_of_two(338))


func _texture_paths() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at(TEXTURES_DIR):
		if file.get_extension() in TEXTURE_EXTENSIONS:
			paths.append(TEXTURES_DIR.path_join(file))
	return paths


func _material_paths() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at(MATERIALS_DIR):
		if file.get_extension() == "tres":
			paths.append(MATERIALS_DIR.path_join(file))
	return paths


func _is_power_of_two(value: int) -> bool:
	return value > 0 and (value & (value - 1)) == 0
