## Waits for the navigation server in level tests. It updates regions and maps
## on background threads, so a fixed number of frames is enough on a fast
## machine but not on a slow one (CI): queries made too early still see the
## previous test's map, or none. These wait on the server's own iteration
## counters instead.

## Most physics frames to wait before giving up; the test's own asserts then fail.
const MAX_FRAMES: int = 300


## Waits until `region`'s navmesh is part of its map: the region has finished
## building its data, and the map has updated since.
static func wait_for_region(region: NavigationRegion3D) -> void:
	var tree: SceneTree = region.get_tree()
	var frames: int = 0
	while NavigationServer3D.region_get_iteration_id(region.get_rid()) == 0 and frames < MAX_FRAMES:
		await tree.physics_frame
		frames += 1
	await wait_for_map_update(tree, region.get_navigation_map())


## Waits until `map` finishes an update that started after this call, such as
## the one that takes in a door's navigation link being switched.
static func wait_for_map_update(tree: SceneTree, map: RID) -> void:
	var start: int = NavigationServer3D.map_get_iteration_id(map)
	var frames: int = 0
	while NavigationServer3D.map_get_iteration_id(map) == start and frames < MAX_FRAMES:
		await tree.physics_frame
		frames += 1
