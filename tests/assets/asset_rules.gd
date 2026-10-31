## Rules shared by the asset tests: the CC0 records in assets/sources.json and the
## import settings every texture needs (see tools/build_assets.py).

class_name AssetRules
extends RefCounted

const SOURCES_PATH: String = "res://assets/sources.json"

## Texture import mode for VRAM compression (ResourceImporterTexture's compress/mode).
const COMPRESS_VRAM: int = 2


## The entries of one section of the manifest ("models" or "textures"), by name.
static func sources(section: String) -> Dictionary[String, Dictionary]:
	var entries: Dictionary[String, Dictionary] = {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCES_PATH))
	if data is Dictionary:
		for entry: Dictionary in (data as Dictionary).get(section, []):
			entries[str(entry.get("name"))] = entry
	return entries


## Why an entry isn't a valid CC0 record, or "" if it is.
static func source_problem(entry: Dictionary) -> String:
	if entry.get("license") != "CC0":
		return "license is %s, not CC0" % entry.get("license")
	if not str(entry.get("source", "")).begins_with("https://"):
		return "has no source URL"
	if str(entry.get("author", "")).is_empty():
		return "has no author"
	return ""


## Why a texture won't import VRAM compressed with mipmaps, or "" if it will.
static func import_problem(texture_path: String) -> String:
	var config := ConfigFile.new()
	if config.load(texture_path + ".import") != OK:
		return "has no .import file"
	if config.get_value("params", "compress/mode", 0) != COMPRESS_VRAM:
		return "isn't VRAM compressed"
	if not config.get_value("params", "mipmaps/generate", false):
		return "has no mipmaps"
	return ""


## Why a material isn't albedo only (docs/design/visual-style.md), or "" if it is.
static func material_problem(material: Material) -> String:
	var standard := material as StandardMaterial3D
	if standard == null:
		return "isn't a StandardMaterial3D"
	if standard.normal_enabled:
		return "uses a normal map"
	if standard.roughness_texture != null:
		return "has a roughness map"
	if standard.metallic_texture != null:
		return "has a metallic map"
	if standard.ao_enabled:
		return "uses an occlusion map"
	if standard.heightmap_enabled:
		return "uses a height map"
	return ""
