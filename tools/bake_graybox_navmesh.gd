## Bakes the graybox level's navigation mesh from its collision geometry and
## saves it to assets/data/graybox_navmesh.res. Run it again after changing the
## level's walls or doors:
##
##   godot --headless --path . -s res://tools/bake_graybox_navmesh.gd

extends SceneTree

const LEVEL_PATH: String = "res://scenes/levels/graybox_level.tscn"
const OUTPUT_PATH: String = "res://assets/data/graybox_navmesh.res"


func _initialize() -> void:
	# Parsing needs the level inside a running tree.
	await process_frame
	var level := (load(LEVEL_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(level)

	var navmesh := NavigationMesh.new()
	navmesh.agent_radius = 0.5
	navmesh.agent_height = 2.0
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navmesh.geometry_collision_mask = CombatLayers.WORLD

	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(navmesh, source, level)
	NavigationServer3D.bake_from_source_geometry_data(navmesh, source)

	var error: Error = ResourceSaver.save(navmesh, OUTPUT_PATH)
	print("Baked %d polygons, saved with result %d" % [navmesh.get_polygon_count(), error])
	quit(0 if error == OK and navmesh.get_polygon_count() > 0 else 1)
