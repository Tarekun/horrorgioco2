## Bakes the LightmapGI of the scene in BAKE_LIGHTMAPS_SCENE, saves it and quits the
## editor. Godot only bakes lightmaps from the editor, so tools/bake_lightmaps.sh starts the
## editor with this plugin on and presses its Bake Lightmaps button. It does nothing when
## the variable isn't set.
@tool
extends EditorPlugin

const BUTTON_TEXT: String = "Bake Lightmaps"


func _enter_tree() -> void:
	var scene_path: String = OS.get_environment("BAKE_LIGHTMAPS_SCENE")
	if scene_path.is_empty():
		return
	# Let the editor finish starting up and importing.
	await get_tree().create_timer(3.0).timeout
	var error: Error = await _bake(scene_path)
	print("bake_lightmaps: %s: %s" % [scene_path, error_string(error)])
	get_tree().quit(0 if error == OK else 1)


func _bake(scene_path: String) -> Error:
	EditorInterface.open_scene_from_path(scene_path)
	await get_tree().process_frame
	var scene: Node = EditorInterface.get_edited_scene_root()
	if scene == null or scene.scene_file_path != scene_path:
		return ERR_CANT_OPEN
	var lightmaps: Array[Node] = scene.find_children("*", "LightmapGI", true, false)
	if lightmaps.size() != 1:
		return ERR_DOES_NOT_EXIST
	var lightmap := lightmaps[0] as LightmapGI
	if lightmap.light_data == null:
		# Without a file to bake into, the editor asks for one in a dialog.
		var data_path: String = scene_path.get_basename() + ".lmbake"
		var error: Error = ResourceSaver.save(LightmapGIData.new(), data_path)
		if error != OK:
			return error
		lightmap.light_data = load(data_path) as LightmapGIData
	EditorInterface.edit_node(lightmap)
	for i in 5:
		await get_tree().process_frame
	var button := _find_button(EditorInterface.get_base_control())
	if button == null:
		return ERR_UNAVAILABLE
	var started: int = Time.get_ticks_msec()
	button.pressed.emit()
	if lightmap.light_data.get_user_count() == 0:
		# The editor explains a failed bake in a dialog; pass it on.
		for dialog: Node in get_tree().root.find_children("*", "AcceptDialog", true, false):
			if (dialog as AcceptDialog).visible:
				var shown := dialog as AcceptDialog
				printerr(
					(
						"bake_lightmaps: %s %s: %s"
						% [shown.get_class(), shown.title, shown.dialog_text]
					)
				)
		return FAILED
	print("bake_lightmaps: baked in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	return EditorInterface.save_scene()


func _find_button(node: Node) -> Button:
	var button := node as Button
	if button and button.text == BUTTON_TEXT:
		return button
	for child: Node in node.get_children():
		var found: Button = _find_button(child)
		if found:
			return found
	return null
