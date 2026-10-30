## Bakes a level's navigation mesh from its collision geometry, with the doors
## shut, and saves it next to the other data resources. Run it again after
## changing a level's walls, doors or solid props:
##
##   godot --headless --path . -s res://tools/bake_navmesh.gd -- hotel_miramare
##
## With no level named, it bakes every level in LEVELS.

extends SceneTree

## Level name: [scene, navmesh it bakes to].
const LEVELS: Dictionary[String, Array] = {
	"graybox_level":
	[
		"res://scenes/levels/graybox_level.tscn",
		"res://assets/data/graybox_navmesh.res",
	],
	"hotel_miramare":
	[
		"res://scenes/levels/hotel_miramare.tscn",
		"res://assets/data/hotel_miramare_navmesh.res",
	],
}


func _initialize() -> void:
	# Parsing needs the level inside a running tree.
	await process_frame
	var names: PackedStringArray = OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(LEVELS.keys())
	var failed: bool = false
	for level_name: String in names:
		if not LEVELS.has(level_name):
			printerr("Unknown level %s; known: %s" % [level_name, ", ".join(LEVELS.keys())])
			failed = true
			continue
		var paths: Array = LEVELS[level_name]
		if not _bake(paths[0], paths[1]):
			failed = true
	quit(1 if failed else 0)


func _bake(level_path: String, output_path: String) -> bool:
	var level := (load(level_path) as PackedScene).instantiate() as Node3D
	root.add_child(level)
	# Shut the doors that start open, so the navmesh stops at every doorway.
	# Matched by property: naming Door would compile it, and it needs autoloads.
	for node: Node in level.find_children("*", "", true, false):
		if node.get(&"starts_open") == true:
			(node.get(&"hinge") as Node3D).rotation.y = 0.0

	var navmesh := NavigationMesh.new()
	navmesh.agent_radius = 0.5
	navmesh.agent_height = 2.0
	# Layers keep stacked floors and stair flights from sharing regions.
	navmesh.sample_partition_type = NavigationMesh.SAMPLE_PARTITION_LAYERS
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navmesh.geometry_collision_mask = CombatLayers.WORLD

	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(navmesh, source, level)
	NavigationServer3D.bake_from_source_geometry_data(navmesh, source)
	level.free()

	var error: Error = ResourceSaver.save(navmesh, output_path)
	print(
		(
			"%s: baked %d polygons, saved with result %d"
			% [level_path, navmesh.get_polygon_count(), error]
		)
	)
	return error == OK and navmesh.get_polygon_count() > 0
