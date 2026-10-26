## Loads every GDScript file and scene in the project and exits non-zero if any fails to load.
## Run with: godot --headless --path . --script res://tools/check_scripts.gd
extends SceneTree

const SKIPPED_DIRS: Array[String] = [".godot", ".git"]


## Runs in _initialize, not _init, so the autoloads exist when scripts that use them compile.
func _initialize() -> void:
	var failures: Array[String] = []
	var checked := 0
	for path in _find_files("res://"):
		checked += 1
		if not _loads_cleanly(path):
			failures.append(path)

	print("Checked %d scripts and scenes." % checked)
	for path in failures:
		printerr("Failed to load: %s" % path)
	quit(1 if failures else 0)


func _loads_cleanly(path: String) -> bool:
	var resource := load(path)
	if resource == null:
		return false
	if resource is Script:
		return (resource as Script).can_instantiate()
	if resource is PackedScene:
		return (resource as PackedScene).can_instantiate()
	return true


func _find_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	for dir_name in DirAccess.get_directories_at(dir_path):
		if dir_name not in SKIPPED_DIRS:
			files.append_array(_find_files(dir_path.path_join(dir_name)))
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() in ["gd", "tscn"]:
			files.append(dir_path.path_join(file_name))
	return files
