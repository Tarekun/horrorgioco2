## Dresses the hotel (scenes/levels/hotel_miramare.tscn) with the kit and props built by
## tools/make_kit.py: rebuilds its Structure, Props and Lights from the layout below and
## keeps every other node (doors, enemies, pickups, save spots, documents, the navmesh and
## the lightmap) as it is. Rerun it after changing the layout, then bake the navmesh and the
## lightmap again (see tools/README.md):
##
##   godot --headless --path . -s res://tools/dress_hotel.gd
##
## The layout is the graybox's (tools/generate_hotel_graybox.py, docs/design/slice.md): x
## runs west to east (0..30 m), z from the sea (-7) to the street (7), the corridor is
## z -1..1 and the floors are 3.2 m apart. The kit's 2 m grid splits each floor into cells.
## Every cell belongs to a space with its own floor, wall and ceiling materials, and a wall
## goes wherever two spaces meet, each half finished for the side it faces.

extends SceneTree

const LEVEL: String = "res://scenes/levels/hotel_miramare.tscn"
const KIT: String = "res://assets/models/environment/"
const PROPS: String = "res://assets/models/props/"
const CEILING: float = 3.0
const COLUMNS: int = 15
const ROWS: int = 7
## Spaces with nothing inside: the lift shaft, its machinery and the plumbing.
const SOLID: String = "solid"
const OUTSIDE: String = "outside"
const STAIRS: String = "stairs"
const CORRIDOR: String = "corridor"
## The outside of the walls above ground.
const FACADE: String = "painted_wall"
const WARM: Color = Color(1, 0.82, 0.6)
const COLD: Color = Color(0.85, 0.9, 1.0)
## Lamp shades and glass that glow when their lamp is on.
const GLOWING: Array[String] = ["opal_glass", "lamp_shade", "green_glass"]

const FLOORS: Dictionary[String, float] = {
	"Basement": -3.2,
	"GroundFloor": 0.0,
	"FirstFloor": 3.2,
	"SecondFloor": 6.4,
}

## Doorways per floor, as the middle of the wall they're in: a wall_door and a door_frame,
## for a door from the Doors group or none (room 28, the bathrooms, the balcony).
const DOORWAYS: Dictionary[String, Array] = {
	"Basement":
	[
		Vector2(7, -1),
		Vector2(15, -1),
		Vector2(27, -1),
		Vector2(3, 1),
		Vector2(9, 1),
		Vector2(15, 1),
		Vector2(27, 1),
	],
	"GroundFloor":
	[
		Vector2(9, -1),
		Vector2(18, -4),
		Vector2(27, -7),
		Vector2(3, 1),
		Vector2(9, 1),
		Vector2(15, 1),
		Vector2(21, 1),
		Vector2(27, 1),
	],
	"FirstFloor":
	[
		Vector2(3, -1),
		Vector2(9, -1),
		Vector2(15, -1),
		Vector2(27, -1),
		Vector2(3, 1),
		Vector2(9, 1),
		Vector2(15, 1),
		Vector2(27, 1),
		Vector2(25, -3),
		Vector2(25, 3),
	],
	"SecondFloor":
	[
		Vector2(3, -1),
		Vector2(9, -1),
		Vector2(15, -1),
		Vector2(27, -1),
		Vector2(3, 1),
		Vector2(9, 1),
		Vector2(15, 1),
		Vector2(27, 1),
		Vector2(25, -3),
		Vector2(25, 3),
		Vector2(27, -7),
	],
}

## Windows per floor, as the middle of the wall they're in.
const WINDOWS: Dictionary[String, Array] = {
	"Basement": [],
	"GroundFloor":
	[
		Vector2(3, -7),
		Vector2(9, -7),
		Vector2(15, -7),
		Vector2(19, -7),
		Vector2(23, -7),
		Vector2(29, -7),
		Vector2(9, 7),
		Vector2(15, 7),
		Vector2(21, 7),
		Vector2(27, 7),
		Vector2(0, 0),
		Vector2(30, 0),
	],
	"FirstFloor":
	[
		Vector2(3, -7),
		Vector2(9, -7),
		Vector2(15, -7),
		Vector2(19, -7),
		Vector2(23, -7),
		Vector2(25, -7),
		Vector2(27, -7),
		Vector2(29, -7),
		Vector2(9, 7),
		Vector2(15, 7),
		Vector2(27, 7),
		Vector2(0, 0),
		Vector2(30, 0),
	],
	"SecondFloor":
	[
		Vector2(3, -7),
		Vector2(9, -7),
		Vector2(15, -7),
		Vector2(19, -7),
		Vector2(23, -7),
		Vector2(25, -7),
		Vector2(29, -7),
		Vector2(9, 7),
		Vector2(15, 7),
		Vector2(27, 7),
		Vector2(0, 0),
		Vector2(30, 0),
	],
}

## Ceiling lamps per floor, [x, z]; the ones on the doc's lit floors are in LIT_LAMPS.
const LAMPS: Dictionary[String, Array] = {
	"Basement":
	[
		[3, 0],
		[9, 0],
		[15, 0],
		[21, 0],
		[27, 0],
		[3, -4],
		[9, -4],
		[27, -4],
		[9, 4],
		[15, 4],
		[27, 4],
	],
	"GroundFloor":
	[
		[3, 0],
		[9, 0],
		[15, 0],
		[21, -3],
		[26, -4],
		[27, 0],
		[3, -4],
		[9, -4],
		[15, -4],
		[15, 4],
		[21, 4],
		[27, 4],
	],
	"FirstFloor":
	[
		[9, 0],
		[15, 0],
		[21, 0],
		[27, 0],
		[3, 0],
		[9, -4],
		[15, -4],
		[21, -3],
		[27, -4],
		[3, -4],
		[15, 4],
		[27, 4],
		[25, -2],
		[25, 2],
	],
	"SecondFloor": [[15, -4], [9, 4], [15, 4], [25, -2], [25, 2]],
}

## The lamps that are on: [light name, floor, x, z, energy, range]. 2F is lit, the rest of
## the hotel is dark (docs/design/slice.md); the room 26 lamp is the one left off.
const LIT_LAMPS: Array[Array] = [
	["CorridorLamp", "SecondFloor", 3, 0, 1.0, 6.0],
	["CorridorLamp", "SecondFloor", 9, 0, 1.0, 6.0],
	["CorridorLamp", "SecondFloor", 15, 0, 1.0, 6.0],
	["CorridorLamp", "SecondFloor", 21, 0, 1.0, 6.0],
	["CorridorLamp", "SecondFloor", 27, 0, 1.0, 6.0],
	["LampRoom22", "SecondFloor", 27, -4, 1.0, 6.0],
	["LampRoom28", "SecondFloor", 3, -4, 1.0, 6.0],
	["LampLiftHall", "SecondFloor", 21, -3, 1.0, 6.0],
	["LampRoom21", "SecondFloor", 27, 4, 1.0, 6.0],
]

## Furniture and fittings per floor: [model, x, height, z, yaw] and an optional node name
## for the ones gameplay and tests look up. Models are a props folder or folder/variant.
const FURNITURE: Dictionary[String, Array] = {
	"SecondFloor":
	# Room 22, the start: twin beds, the clock (P1) on the nightstand, the desk with the
	[
		# registration card, the bathroom cabinet with a drink.
		["bed", 28.85, 0, -4.47, -90],
		["bed", 28.85, 0, -3.53, -90],
		["nightstand", 29.6, 0, -5.3, -90],
		["alarm_clock", 29.62, 0.615, -5.3, -90, "ClockRoom22"],
		["nightstand", 29.6, 0, -2.5, -90],
		["bedside_lamp", 29.6, 0.615, -2.5, -90],
		["desk", 24.43, 0, -5.4, 90],
		["painted_chair", 25.2, 0, -5.4, -90],
		["wardrobe", 29.56, 0, -1.65, -90],
		["wall_cabinet", 24.1, 1.1, -2.3, 90, "BathroomCabinet"],
		["room_number/room_number_22", 28.3, 1.7, -0.9, 0],
		# Room 21, door ajar, shower running.
		["bed", 28.85, 0, 4.5, -90],
		["nightstand", 29.6, 0, 5.85, -90],
		["wardrobe", 29.56, 0, 2.0, -90],
		["wall_cabinet", 24.1, 1.1, 2.3, 90],
		["room_number/room_number_21", 28.3, 1.7, 0.9, 180],
		# Room 28: no door, the stairs key on a chair facing the window.
		["painted_chair", 3, 0, -4, 180, "ChairRoom28"],
		["room_number/room_number_28", 4.3, 1.7, -0.9, 0],
		# Room 26: lamp off, a coat by the window, a tray outside the door.
		["bed", 7.14, 0, -4, 90],
		["wardrobe", 11.56, 0, -2.5, -90],
		["coat_stand", 10.4, 0, -6.4, 0, "CoatStandRoom26"],
		["room_service_tray", 10.1, 0, -0.7, 10, "TrayRoom26"],
		["room_number/room_number_26", 10.3, 1.7, -0.9, 0],
		# Room 24 never opens; rooms 23 and 25 are locked.
		["room_number/room_number_24", 16.3, 1.7, -0.9, 0],
		["sign/sign_do_not_disturb", 15.5, 1.15, -0.93, 0],
		["room_number/room_number_23", 16.3, 1.7, 0.9, 180],
		["room_number/room_number_25", 10.3, 1.7, 0.9, 180],
		["sign/sign_stairs", 3, 2.75, 0.89, 180],
		["curtain", 0.17, 2.45, -0.25, 90],
		["armchair", 19, 0, -6.3, 0],
		["armchair", 23, 0, -6.3, 0],
		# The balcony.
		["balcony_divider", 24.05, 0, -8.05, 90],
		["balcony_divider", 29.95, 0, -8.05, 90],
	],
	"FirstFloor":
	[
		# Linen room: the key cabinet (P1) and the trolley with a drink and a document.
		["key_cabinet", 0.1, 0.9, -4, 90, "KeyCabinet"],
		["linen_cart", 4.1, 0, -5.7, 0, "LinenTrolley"],
		["steel_shelves", 0.36, 0, -6.2, 90],
		["steel_shelves", 2.2, 0, -6.65, 0],
		# Room 16, with the postcard on the bed.
		["bed", 10.86, 0, -4.5, -90],
		["nightstand", 11.6, 0, -5.8, -90],
		["wardrobe", 6.44, 0, -3, 90],
		["room_number/room_number_16", 10.3, 1.7, -0.9, 0],
		["room_number/room_number_14", 16.3, 1.7, -0.9, 0],
		# Room 12, right under room 22, furnished the same.
		["bed", 28.85, 0, -4.47, -90],
		["bed", 28.85, 0, -3.53, -90],
		["nightstand", 29.6, 0, -5.3, -90],
		["nightstand", 29.6, 0, -2.5, -90],
		["desk", 24.43, 0, -5.4, 90],
		["painted_chair", 25.2, 0, -5.4, -90],
		["wardrobe", 29.56, 0, -1.65, -90],
		["wall_cabinet", 24.1, 1.1, -2.3, 90],
		["room_number/room_number_12", 28.3, 1.7, -0.9, 0],
		# Room 15, the building site: scaffolding, the steel pipe, the chute down to GF.
		["scaffolding", 6.6, 0, 3.05, 90, "Scaffolding"],
		["scaffolding", 6.6, 0, 5.55, 90],
		["rubble_chute", 9, 0, 4.5, 0, "ChuteTop"],
		["room_number/room_number_15", 10.3, 1.7, 0.9, 180],
		# Room 13, the wardrobe that creaks open.
		["wardrobe", 17.56, 0, 3.75, -90, "Wardrobe"],
		["bed", 13.14, 0, 5.2, 90],
		["nightstand", 12.4, 0, 6.6, 90],
		["room_number/room_number_13", 16.3, 1.7, 0.9, 180],
		["room_number/room_number_11", 28.3, 1.7, 0.9, 180],
		["sign/sign_stairs", 3, 2.75, 0.89, 180],
		["armchair", 19, 0, -6.3, 0],
	],
	"GroundFloor":
	[
		# Dining room, the tables set for the last dinner.
		["dining_table", 3, 0, -4, 0],
		["dining_table", 9, 0, -4, 0],
		["dining_table", 15, 0, -4, 0],
		["painted_chair", 2.4, 0, -5.1, 15],
		["painted_chair", 3.7, 0, -2.85, 170],
		["painted_chair", 8.3, 0, -5.0, -10],
		["painted_chair", 9.6, 0, -5.2, 20],
		["painted_chair", 8.5, 0, -2.9, 195],
		["painted_chair", 15.6, 0, -2.7, 160],
		["painted_chair", 14.4, 0, -5.15, 5],
		["cupboard", 0.47, 0, -4, 90],
		# Lobby: the porter's desk and lamp, the key board, the clock wall.
		["reception_desk", 22.5, 0, -1.3, 180, "ReceptionDesk"],
		["desk_lamp", 23.75, 1.14, -0.8, 160, "DeskLamp"],
		["key_board", 23.8, 1.2, 0.9, 180, "KeyBoard"],
		["sign/sign_reception", 22.5, 2.55, 0.89, 180],
		["sign/sign_private", 21, 2.75, 0.89, 180],
		["wall_clock", 29.88, 1.9, -6.0, -90],
		["wall_clock", 29.88, 1.9, -4.8, -90],
		["wall_clock", 29.88, 1.9, -3.6, -90],
		["wall_clock", 29.88, 1.9, -2.4, -90],
		["armchair", 24.2, 0, -6.3, 0],
		["armchair", 25.4, 0, -6.3, 0],
		# Corridor. The sunbeds stacked against the stairs door are the obstacle
		# (scenes/levels/sunbeds_obstacle.tscn), placed under Doors since they move.
		["sign/sign_stairs", 3, 2.75, 0.89, 180],
		# Building site under room 15: the skip and the chute's mouth.
		["skip", 9, 0, 4.5, 0, "Skip"],
		["rubble_chute", 9, 1.4, 4.5, 0],
		["rubble_chute", 9, 2.0, 4.5, 0, "ChuteBottom"],
		# Kitchen: a pot left on the stove.
		["kitchen_counter", 13, 0, 6.9, 180],
		["kitchen_counter", 15, 0, 6.9, 180],
		["kitchen_counter", 17, 0, 6.9, 180],
		["stove", 14.6, 0, 4.0, 0, "Stove"],
		["steel_shelves", 17.6, 0, 2.6, -90],
		# Back office, with the porter's log on the desk and the first aid kit.
		["desk", 21, 0, 4.5, 180, "OfficeDesk"],
		["painted_chair", 21, 0, 5.25, 190],
		["wall_cabinet", 23.9, 1.2, 2.9, -90, "OfficeWallCabinet"],
		["cupboard", 18.47, 0, 5.5, 90],
		# TV room, the radio playing the song.
		["sofa", 25.5, 0, 6.45, 180, "Sofa"],
		["nightstand", 25.2, 0, 1.4, 0],
		["television", 25.2, 0.615, 1.4, 0],
		["radio", 29.68, 0, 3.2, -90, "Radio"],
		["armchair", 28.7, 0, 5.4, -130],
	],
	"Basement":
	[
		# Laundry: washing machines, linen carts, sheets on lines.
		["washing_machine", 1.05, 0, -6.5, 0],
		["washing_machine", 1.95, 0, -6.5, 0],
		["washing_machine", 2.85, 0, -6.5, 0],
		["washing_machine", 3.75, 0, -6.5, 0],
		["linen_cart", 6.95, 0, -5.9, 20],
		["linen_cart", 9.45, 0, -2.1, -15],
		["hanging_sheet", 5.6, 0, -3.5, 0],
		["hanging_sheet", 7.8, 0, -3.5, 0],
		["hanging_sheet", 10.0, 0, -3.5, 0],
		["steel_shelves", 11.6, 0, -6.2, -90],
		# Boiler room: the boilers E1 hides behind, the switchboard facing the door.
		["boiler", 15.7, 0, -4.3, -90, "Boilers"],
		["boiler", 15.7, 0, -2.7, -90],
		["water_tank", 17.25, 0, -1.6, 0, "Tank"],
		["switchboard", 14.2, 0.8, -6.9, 0, "SwitchboardBasement"],
		# Corridor: pipes along the ceiling, the roller shutter and its button.
		["roller_shutter", 18, 0, 0, 90, "ShutterStaff"],
		["wall_button", 17.4, 1.1, 0.9, 180, "ShutterButton"],
		["sign/sign_private", 18.6, 2.0, -0.89, 0],
		# Changing room: two rows of lockers, the porter's ajar (K4).
		["locker/locker_ajar", 29.65, 0, -3.75, -90, "PorterLocker"],
		# Staff room: a table, chairs, a hotplate.
		["dining_table", 27, 0, 4.1, 0, "StaffTable"],
		["painted_chair", 26.4, 0, 3.15, 10],
		["painted_chair", 27.7, 0, 5.05, 175],
		["painted_chair", 28.6, 0, 3.2, -20],
		["kitchen_counter", 29.9, 0, 5.5, -90],
		["hotplate", 29.55, 0.9, 5.5, -90, "Hotplate"],
	],
}

var _root: Node3D
var _glow: Dictionary[String, StandardMaterial3D] = {}
var _failed: bool = false


func _initialize() -> void:
	var scene := load(LEVEL) as PackedScene
	_root = scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	var fog: Node = _root.get_node("Structure/Outside/FogBank")
	fog.get_parent().remove_child(fog)
	fog.owner = null
	for group_name: String in ["Structure", "Props", "Lights"]:
		var old: Node = _root.get_node_or_null(group_name)
		if old:
			_root.remove_child(old)
			old.free()

	var structure: Node3D = _group("Structure", _root)
	var props: Node3D = _group("Props", _root)
	for floor_name: String in FLOORS:
		var y: float = FLOORS[floor_name]
		_build_floor(floor_name, y, _group(floor_name, structure))
		var furniture: Node3D = _group(floor_name, props)
		_furnish(floor_name, y, furniture)
		_hang_lamps(floor_name, y, furniture)
	_build_stairs(_group("Stairs", structure))
	_build_lift(_group("Lift", structure), props)
	_build_balcony(structure.get_node("SecondFloor") as Node3D)
	_build_basement_fittings(props.get_node("Basement") as Node3D)
	var outside: Node3D = _group("Outside", structure)
	_build_seafront(outside)
	_add(fog, outside)
	_build_lights(_group("Lights", _root))
	_order_groups()
	_ensure_lightmap()

	if _failed:
		printerr("dress_hotel: a model is missing; %s is unchanged" % LEVEL)
		_root.free()
		quit(1)
		return
	var packed := PackedScene.new()
	var error: Error = packed.pack(_root)
	if error == OK:
		error = ResourceSaver.save(packed, LEVEL)
	print("dress_hotel: saved %s: %s" % [LEVEL, error_string(error)])
	_root.free()
	quit(0 if error == OK else 1)


## The space of every cell on a floor, [space, floor, walls, ceiling], by [column][row].
func _cells(floor_name: String) -> Array[Array]:
	var cells: Array[Array] = []
	for i in COLUMNS:
		var column: Array = []
		for j in ROWS:
			column.append([OUTSIDE, "", "", ""])
		cells.append(column)
	for room: Array in _rooms(floor_name):
		for i in COLUMNS:
			for j in ROWS:
				var centre := Vector2(1 + 2 * i, -6 + 2 * j)
				if centre.x > room[1] and centre.x < room[2] and centre.y > room[3]:
					if centre.y < room[4]:
						cells[i][j] = [room[0], room[5], room[6], room[7]]
	return cells


## Rooms of a floor: [space, x0, x1, z0, z1, floor, walls, ceiling]; later ones win.
func _rooms(floor_name: String) -> Array[Array]:
	if floor_name == "Basement":
		return [
			[CORRIDOR, 0, 30, -1, 1, "concrete_floor", "concrete_wall", "concrete_wall"],
			["laundry", 0, 12, -7, -1, "floor_tiles", "wall_tiles", "concrete_wall"],
			["boiler_room", 12, 18, -7, -1, "concrete_floor", "concrete_wall", "concrete_wall"],
			[SOLID, 18, 24, -7, -1, "", "", ""],
			["changing_room", 24, 30, -7, -1, "floor_tiles", "painted_wall", "concrete_wall"],
			[STAIRS, 0, 6, 1, 7, "concrete_floor", "concrete_wall", ""],
			["storage", 6, 12, 1, 7, "concrete_floor", "concrete_wall", "concrete_wall"],
			["pantry", 12, 18, 1, 7, "floor_tiles", "wall_tiles", "concrete_wall"],
			[SOLID, 18, 24, 1, 7, "", "", ""],
			["staff_room", 24, 30, 1, 7, "floor_tiles", "painted_wall", "concrete_wall"],
		]
	if floor_name == "GroundFloor":
		return [
			[CORRIDOR, 0, 30, -1, 1, "terrazzo", "painted_wall", "ceiling_plaster"],
			# The lobby is open to the corridor.
			[CORRIDOR, 18, 30, -7, 1, "terrazzo", "wood_panelling", "ceiling_tiles"],
			[SOLID, 20, 22, -7, -5, "", "", ""],
			["dining_room", 0, 18, -7, -1, "floor_tiles", "wallpaper", "ceiling_tiles"],
			[STAIRS, 0, 6, 1, 7, "terrazzo", "painted_wall", ""],
			["building_site", 6, 12, 1, 7, "concrete_floor", "stripped_plaster", "concrete_wall"],
			["kitchen", 12, 18, 1, 7, "floor_tiles", "wall_tiles", "ceiling_tiles"],
			["back_office", 18, 24, 1, 7, "carpet", "painted_wall", "ceiling_plaster"],
			["tv_room", 24, 30, 1, 7, "carpet", "wallpaper", "ceiling_plaster"],
		]
	var is_first: bool = floor_name == "FirstFloor"
	var number: int = 10 if is_first else 20
	var rooms: Array[Array] = [
		[CORRIDOR, 0, 30, -1, 1, "terrazzo", "painted_wall", "ceiling_plaster"],
		# The lift hall is open to the corridor.
		[CORRIDOR, 18, 24, -7, -1, "terrazzo", "wood_panelling", "ceiling_plaster"],
		[SOLID, 20, 22, -7, -5, "", "", ""],
		[STAIRS, 0, 6, 1, 7, "terrazzo", "painted_wall", "ceiling_plaster"],
		[SOLID, 18, 24, 1, 7, "", "", ""],
	]
	if is_first:
		rooms.append(["linen_room", 0, 6, -7, -1, "floor_tiles", "painted_wall", "ceiling_plaster"])
		rooms.append(["room_15", 6, 12, 1, 7, "concrete_floor", "brick", "concrete_wall"])
	else:
		rooms.append(["room_28", 0, 6, -7, -1, "carpet", "wallpaper", "ceiling_plaster"])
		rooms.append(["room_25", 6, 12, 1, 7, "carpet", "wallpaper", "ceiling_plaster"])
	for room: Array in [[6, -7, 6], [12, -7, 4], [24, -7, 2], [12, 1, 3], [24, 1, 1]]:
		var name: String = "room_%d" % (number + room[2])
		rooms.append([name, room[0], room[0] + 6, room[1], room[1] + 6])
		rooms[-1].append_array(["carpet", "wallpaper", "ceiling_plaster"])
	for z0: int in [-3, 1]:
		var bathroom: Array = ["bathroom_%d" % z0, 24, 26, z0, z0 + 2]
		rooms.append(bathroom + ["floor_tiles", "wall_tiles", "ceiling_plaster"])
	return rooms


func _build_floor(floor_name: String, y: float, parent: Node3D) -> void:
	var cells: Array[Array] = _cells(floor_name)
	for i in COLUMNS:
		for j in ROWS:
			var cell: Array = cells[i][j]
			var space: String = cell[0]
			if space in [SOLID, OUTSIDE]:
				continue
			var centre := Vector3(1 + 2 * i, y, -6 + 2 * j)
			if space != STAIRS or floor_name == "Basement":
				_kit("floor", cell[1], centre, 0, parent)
			if space != STAIRS or floor_name == "SecondFloor":
				_kit("ceiling", cell[3], centre + Vector3(0, CEILING, 0), 0, parent)
	# Walls on the lines x = 0, 2, .. 30 and z = -7, -5, .. 7.
	for i in COLUMNS + 1:
		for j in ROWS:
			var at := Vector3(2 * i, y, -6 + 2 * j)
			_wall(floor_name, _cell(cells, i - 1, j), _cell(cells, i, j), at, 90, parent)
	for j in ROWS + 1:
		for i in COLUMNS:
			var at := Vector3(1 + 2 * i, y, -7 + 2 * j)
			_wall(floor_name, _cell(cells, i, j - 1), _cell(cells, i, j), at, 0, parent)


func _cell(cells: Array[Array], i: int, j: int) -> Array:
	if i < 0 or i >= COLUMNS or j < 0 or j >= ROWS:
		return [OUTSIDE, "", "", ""]
	return cells[i][j]


## The wall between two cells: a half facing each side that is a room, or the facade facing
## outside. yaw turns a half to face the second cell.
func _wall(
	floor_name: String, first: Array, second: Array, at: Vector3, yaw: float, parent: Node3D
) -> void:
	if first[0] == second[0]:
		return
	var line := Vector2(at.x, at.z)
	var kind: String = "wall"
	if DOORWAYS[floor_name].has(line):
		kind = "wall_door"
	elif WINDOWS[floor_name].has(line):
		kind = "wall_window"
	var is_basement: bool = floor_name == "Basement"
	for side: Array in [[second, yaw], [first, yaw + 180]]:
		var cell: Array = side[0]
		var material: String = cell[2]
		if cell[0] == OUTSIDE:
			if is_basement:
				continue
			material = FACADE
		elif cell[0] == SOLID:
			continue
		_kit(kind, material, at, side[1], parent)
	if kind == "wall_door":
		_prop("door_frame", at, yaw, parent)
	elif kind == "wall_window":
		_prop("window_frame", at + Vector3(0, 0.9, 0), yaw, parent)


## A switchback from the basement to 2F in the west stairwell (x 0..6, z 1..7): on each
## floor the landing (z 1..2.7), the west flight up to the half landing (z 5.3..7), the east
## flight back up north to the next floor, and the wall between the two.
func _build_stairs(parent: Node3D) -> void:
	for floor_name: String in FLOORS:
		var y: float = FLOORS[floor_name]
		var is_basement: bool = floor_name == "Basement"
		var floor_material: String = "concrete_floor" if is_basement else "terrazzo"
		var wall_material: String = "concrete_wall" if is_basement else "painted_wall"
		_kit("stair_wall", wall_material, Vector3(3, y, 4), 0, parent)
		if not is_basement:
			for x: float in [1.55, 4.45]:
				_kit("stair_landing", "terrazzo", Vector3(x, y, 1.85), 0, parent)
		if floor_name == "SecondFloor":
			# Nothing above 2F: a railing over the drop of the flight going down.
			for x: float in [0.6, 1.6, 2.6]:
				_prop("railing", Vector3(x, y, 2.66), 0, parent)
			continue
		_kit("stairs", floor_material, Vector3(1.5, y, 2.7), 180, parent)
		for x: float in [1.55, 4.45]:
			_kit("stair_landing", floor_material, Vector3(x, y + 1.6, 6.15), 0, parent)
		_kit("stairs", floor_material, Vector3(4.5, y + 1.6, 5.3), 0, parent)


## The lift doors on every floor but the basement, on the shaft at x 20..22, z -7..-5,
## with their signs among the floor's props.
func _build_lift(parent: Node3D, props: Node3D) -> void:
	for floor_name: String in ["GroundFloor", "FirstFloor", "SecondFloor"]:
		var y: float = FLOORS[floor_name]
		var doors: Node3D = _prop("lift_doors", Vector3(21, y, -4.9), 0, parent)
		doors.name = "LiftDoors" + floor_name
		var furniture: Node3D = props.get_node(floor_name)
		_prop("sign/sign_out_of_order", Vector3(21, y + 1.5, -4.86), 0, furniture)
		_prop("sign/sign_lift", Vector3(21, y + 2.55, -4.895), 0, furniture)


## Room 22's balcony over the seafront, 2 m deep, with its railing.
func _build_balcony(parent: Node3D) -> void:
	var y: float = FLOORS["SecondFloor"]
	for x: float in [25, 27, 29]:
		_kit("floor", "terrazzo", Vector3(x, y, -8), 0, parent)
	for x: float in [24.5, 25.5, 26.5, 27.5, 28.5, 29.5]:
		_prop("railing", Vector3(x, y, -8.95), 0, parent)


## The lockers in the changing room and the pipes along the corridor ceiling.
func _build_basement_fittings(parent: Node3D) -> void:
	var y: float = FLOORS["Basement"]
	for k in 9:
		_prop("locker/locker_closed", Vector3(24.35, y, -6.25 + 0.5 * k), 90, parent)
	for z: float in [-6.25, -5.75, -5.25, -4.75, -4.25, -3.25, -2.75, -2.25]:
		_prop("locker/locker_closed", Vector3(29.65, y, z), -90, parent)
	for x in range(1, 30, 2):
		var at := Vector3(x, y + CEILING, 0.5)
		_prop("ceiling_pipes", at, 0, parent)


func _furnish(floor_name: String, y: float, parent: Node3D) -> void:
	for item: Array in FURNITURE[floor_name]:
		var at := Vector3(item[1], y + item[2], item[3])
		var node: Node3D = _prop(item[0], at, item[4], parent)
		if item.size() > 5:
			node.name = item[5]


func _hang_lamps(floor_name: String, y: float, parent: Node3D) -> void:
	for spot: Array in LAMPS[floor_name]:
		_prop("ceiling_lamp", Vector3(spot[0], y + CEILING, spot[1]), 0, parent)
	for lamp: Array in LIT_LAMPS:
		if lamp[1] == floor_name:
			var at := Vector3(lamp[2], y + CEILING, lamp[3])
			_light_up(_prop("ceiling_lamp", at, 0, parent))
	if floor_name == "SecondFloor":
		_light_up(parent.get_node("BedsideLamp") as Node3D)
	elif floor_name == "GroundFloor":
		_light_up(parent.get_node("DeskLamp") as Node3D)
	elif floor_name == "Basement":
		for z: float in [-5.5, -2.5]:
			_prop("ceiling_lamp", Vector3(14.5, y + CEILING, z), 0, parent)


## Lights, by floor as the doc has them: 2F all on and baked; GF only the porter's desk
## lamp; the boiler room's lamps off until the power comes back. The desk lamp and the
## boiler room are dynamic, for the porter's shadow and the power coming back on.
func _build_lights(parent: Node3D) -> void:
	var second: Node3D = _group("SecondFloor", parent)
	var y: float = FLOORS["SecondFloor"]
	for lamp: Array in LIT_LAMPS:
		var at := Vector3(lamp[2], y + 2.45, lamp[3])
		_light(lamp[0], at, lamp[4], lamp[5], WARM, Light3D.BAKE_STATIC, second)
	_light("LampBedside", Vector3(29.6, y + 1.0, -2.5), 0.5, 3.0, WARM, Light3D.BAKE_STATIC, second)
	var ground: Node3D = _group("GroundFloor", parent)
	_light("DeskLamp", Vector3(23.75, 1.45, -0.8), 1.2, 5.0, WARM, Light3D.BAKE_DYNAMIC, ground)
	var boiler_room: Node3D = _group("BoilerRoom", _group("Basement", parent))
	boiler_room.visible = false
	for z: float in [-5.5, -2.5]:
		var at := Vector3(14.5, FLOORS["Basement"] + 2.45, z)
		_light("Lamp", at, 1.4, 6.0, COLD, Light3D.BAKE_DYNAMIC, boiler_room)


func _light(
	name: String,
	at: Vector3,
	energy: float,
	reach: float,
	color: Color,
	bake_mode: Light3D.BakeMode,
	parent: Node3D
) -> void:
	var light := OmniLight3D.new()
	light.name = name
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.light_bake_mode = bake_mode
	light.shadow_enabled = true
	_add(light, parent)


## The seafront outside the front door, under the fog bank.
func _build_seafront(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Seafront"
	body.position = Vector3(15, 0, -18.55)
	_add(body, parent)
	var size := Vector2(50, 22.9)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var plane := PlaneMesh.new()
	plane.size = size
	var material := (load("res://assets/materials/concrete_floor.tres") as Material).duplicate()
	var paving := material as StandardMaterial3D
	paving.uv1_scale = Vector3(size.x, size.y, 1) * paving.uv1_scale.x
	plane.material = paving
	mesh.mesh = plane
	mesh.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	_add(mesh, body)
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	shape.shape = box
	shape.position.y = -0.1
	_add(shape, body)


## Makes a lamp's shade or glass glow, for a lamp that is on.
func _light_up(lamp: Node3D) -> void:
	_root.set_editable_instance(lamp, true)
	for node: Node in lamp.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		# The light sits in the shade, which would otherwise shadow the room.
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if material and material.resource_name in GLOWING:
				mesh_instance.set_surface_override_material(surface, _glowing(material))


func _glowing(material: StandardMaterial3D) -> StandardMaterial3D:
	if not _glow.has(material.resource_name):
		var glow := material.duplicate() as StandardMaterial3D
		glow.emission_enabled = true
		glow.emission = material.albedo_color * WARM
		glow.emission_energy_multiplier = 1.5
		_glow[material.resource_name] = glow
	return _glow[material.resource_name]


## Puts the rebuilt groups back where the old ones were, before the doors.
func _order_groups() -> void:
	var index: int = _root.get_node("Ambience").get_index() + 1
	for group_name: String in ["Structure", "Props", "Lights"]:
		_root.move_child(_root.get_node(group_name), index)
		index += 1


func _ensure_lightmap() -> void:
	if _root.has_node("LightmapGI"):
		return
	var lightmap := LightmapGI.new()
	lightmap.name = "LightmapGI"
	lightmap.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lightmap.bounces = 3
	lightmap.texel_scale = 0.5
	lightmap.max_texture_size = 4096
	lightmap.environment_mode = LightmapGI.ENVIRONMENT_MODE_DISABLED
	_add(lightmap, _root)
	_root.move_child(lightmap, _root.get_node("Lights").get_index() + 1)


## A kit piece in one of its materials, e.g. _kit("wall_door", "brick", ...).
func _kit(piece: String, material: String, at: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var path: String = "%s%s/%s_%s.gltf" % [KIT, piece, piece, material]
	return _place(path, at, yaw, parent)


## A prop or fitting by its folder under assets/models/props/ or environment/, or
## folder/variant.
func _prop(model: String, at: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var path: String = model if "/" in model else "%s/%s" % [model, model]
	if not ResourceLoader.exists(PROPS + path + ".gltf"):
		return _place(KIT + path + ".gltf", at, yaw, parent)
	return _place(PROPS + path + ".gltf", at, yaw, parent)


func _place(path: String, at: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var scene := load(path) as PackedScene
	if scene == null:
		_failed = true
		return _group("Missing", parent)
	var node := scene.instantiate() as Node3D
	node.name = path.get_file().get_basename().to_pascal_case()
	node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
	_add(node, parent)
	return node


func _group(name: String, parent: Node3D) -> Node3D:
	var group := Node3D.new()
	group.name = name
	_add(group, parent)
	return group


func _add(node: Node, parent: Node) -> void:
	parent.add_child(node, true)
	node.owner = _root
	for child: Node in node.find_children("*", "", true, false):
		if child.owner == null:
			child.owner = _root
