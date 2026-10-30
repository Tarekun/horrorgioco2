"""Generates scenes/levels/hotel_miramare.tscn, the graybox of the slice's hotel.

Layout from docs/design/slice.md: x runs west to east (0..30 m, the plans'
metre ruler), z runs north (sea, -7) to south (street, +7). The corridor is
z -1..1 on every floor. Floors: basement -3.2, GF 0, 1F 3.2, 2F 6.4; 3 m
ceilings under 0.2 m slabs.

Doors, props and lights are listed below with the ids from the doc. The
scene is generated whole: rerunning this overwrites anything edited by hand
in it, so once the level is being populated (#71), edit the scene instead.

To regenerate, from the project root:

    python3 tools/generate_hotel_graybox.py --no-navmesh
    godot --headless --path . -s res://tools/bake_navmesh.gd -- hotel_miramare
    python3 tools/generate_hotel_graybox.py

The first run leaves the navmesh out, so the bake doesn't load the old one;
the last puts the freshly baked one back. Pass a path to write elsewhere.
"""

import math
import os
import sys

STOREY = 3.2
CEILING = 3.0
SLAB = 0.2
WALL = 0.2
DOOR_W = 1.4
DOOR_H = 2.4
# The stair flights run from the floor landing (z 1..RUN_START) to the half
# landing (z RUN_END..7).
RUN_START, RUN_END = 2.7, 5.3
FLOORS = [("Basement", -3.2), ("GroundFloor", 0.0), ("FirstFloor", 3.2), ("SecondFloor", 6.4)]
Y = dict(FLOORS)


def f(v):
    v = round(v, 4)
    if v == int(v):
        return str(int(v))
    return ("%.4f" % v).rstrip("0").rstrip(".")


def transform(origin, basis=None):
    b = basis or ((1, 0, 0), (0, 1, 0), (0, 0, 1))
    # `basis` holds the axes (columns); the text format lists the rows.
    vals = [b[c][r] for r in range(3) for c in range(3)] + list(origin)
    return "Transform3D(%s)" % ", ".join(f(v) for v in vals)


# Basis columns (X, Y, Z axes). Doors in a wall along z: local X -> world -Z.
TURNED = ((0, 0, -1), (0, 1, 0), (1, 0, 0))


class Scene:
    def __init__(self):
        self.ext = []
        self.subs = []
        self.nodes = []
        self.sizes = {}
        self.names = {}

    def add_ext(self, kind, path, rid):
        self.ext.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, rid))

    def material(self, rid, color, extra=""):
        self.subs.append(
            '[sub_resource type="StandardMaterial3D" id="%s"]\nalbedo_color = Color(%s, 1)\nroughness = 0.9%s'
            % (rid, ", ".join(f(c) for c in color), extra)
        )

    def _size(self, size):
        key = tuple(round(s, 4) for s in size)
        if key not in self.sizes:
            i = len(self.sizes)
            vec = "Vector3(%s)" % ", ".join(f(s) for s in key)
            self.subs.append('[sub_resource type="BoxShape3D" id="Shape_%d"]\nsize = %s' % (i, vec))
            self.subs.append('[sub_resource type="BoxMesh" id="Mesh_%d"]\nsize = %s' % (i, vec))
            self.sizes[key] = i
        return self.sizes[key]

    def unique(self, parent, name):
        key = (parent, name)
        n = self.names.get(key, 0) + 1
        self.names[key] = n
        return name if n == 1 else "%s%d" % (name, n)

    def node(self, name, kind, parent, props=(), instance=None, node_paths=None):
        head = '[node name="%s"' % name
        if kind:
            head += ' type="%s"' % kind
        head += ' parent="%s"' % parent if parent is not None else ""
        if node_paths:
            head += " node_paths=PackedStringArray(%s)" % ", ".join('"%s"' % p for p in node_paths)
        if instance:
            head += ' instance=ExtResource("%s")' % instance
        head += "]"
        self.nodes.append("\n".join([head, *props]))

    def group(self, path):
        parent, _, name = path.rpartition("/")
        self.node(name, "Node3D", parent or ".")

    def box(self, parent, name, x0, x1, y0, y1, z0, z1, mat="Mat_wall"):
        """A solid box from corner to corner, as a StaticBody3D with mesh and shape."""
        size = (x1 - x0, y1 - y0, z1 - z0)
        center = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
        self.body(parent, name, center, size, mat)

    def body(self, parent, name, center, size, mat, basis=None):
        i = self._size(size)
        name = self.unique(parent, name)
        self.node(name, "StaticBody3D", parent, ["transform = " + transform(center, basis)])
        path = parent + "/" + name
        self.node("Mesh", "MeshInstance3D", path, ['mesh = SubResource("Mesh_%d")' % i, 'surface_material_override/0 = SubResource("%s")' % mat])
        self.node("Shape", "CollisionShape3D", path, ['shape = SubResource("Shape_%d")' % i])

    def text(self):
        out = ["[gd_scene load_steps=%d format=3]" % (len(self.ext) + len(self.subs) + 1), ""]
        out += [e for e in self.ext] + [""]
        for s in self.subs:
            out += [s, ""]
        for n in self.nodes:
            out += [n, ""]
        return "\n".join(out).rstrip() + "\n"


S = Scene()


def wall_x(parent, name, z, x0, x1, y, gaps=(), h=CEILING):
    """A wall along x at z, from x0 to x1, with doorways [(centre x, width)]."""
    edges = sorted(gaps)
    start = x0
    for cx, w in edges:
        if cx - w / 2 > start:
            S.box(parent, name, start, cx - w / 2, y, y + h, z - WALL / 2, z + WALL / 2)
        S.box(parent, name + "Lintel", cx - w / 2, cx + w / 2, y + DOOR_H, y + h, z - WALL / 2, z + WALL / 2)
        start = cx + w / 2
    if x1 > start:
        S.box(parent, name, start, x1, y, y + h, z - WALL / 2, z + WALL / 2)


def wall_z(parent, name, x, z0, z1, y, gaps=(), h=CEILING):
    """A wall along z at x, from z0 to z1, with doorways [(centre z, width)]."""
    start = z0
    for cz, w in sorted(gaps):
        if cz - w / 2 > start:
            S.box(parent, name, x - WALL / 2, x + WALL / 2, y, y + h, start, cz - w / 2)
        S.box(parent, name + "Lintel", x - WALL / 2, x + WALL / 2, y + DOOR_H, y + h, cz - w / 2, cz + w / 2)
        start = cz + w / 2
    if z1 > start:
        S.box(parent, name, x - WALL / 2, x + WALL / 2, y, y + h, start, z1)


def slab(parent, name, top, hole):
    """A floor slab over the footprint whose top is at `top`; `hole` leaves the stair shaft open."""
    b = top - SLAB
    if not hole:
        S.box(parent, name, -0.1, 30.1, b, top, -7.1, 7.1, "Mat_floor")
        return
    # The shaft is x 0.1..5.9, z RUN_START..6.9; the landing stays.
    S.box(parent, name, -0.1, 30.1, b, top, -7.1, RUN_START, "Mat_floor")
    S.box(parent, name, 5.9, 30.1, b, top, RUN_START, 7.1, "Mat_floor")
    S.box(parent, name, -0.1, 0.1, b, top, RUN_START, 7.1, "Mat_floor")
    S.box(parent, name, 0.1, 5.9, b, top, 6.9, 7.1, "Mat_floor")


# --- Resources ----------------------------------------------------------------

S.add_ext("PackedScene", "res://scenes/player/player.tscn", "1")
S.add_ext("Environment", "res://assets/data/atmosphere_environment.tres", "2")
S.add_ext("AudioStream", "res://assets/audio/ambience_drone.wav", "3")
S.add_ext("Script", "res://scripts/audio/ambience_player.gd", "4")
S.add_ext("PackedScene", "res://scenes/levels/door.tscn", "5")
WITH_NAVMESH = "--no-navmesh" not in sys.argv
if WITH_NAVMESH:
    S.add_ext("NavigationMesh", "res://assets/data/hotel_miramare_navmesh.res", "6")

S.material("Mat_wall", (0.45, 0.43, 0.4))
S.material("Mat_floor", (0.22, 0.22, 0.24))
S.material("Mat_prop", (0.35, 0.3, 0.25))
S.material("Mat_metal", (0.2, 0.2, 0.22), "\nmetallic = 0.5")
S.material("Mat_chute", (0.85, 0.68, 0.08))
S.material("Mat_sheet", (0.75, 0.74, 0.7))
S.subs.append('[sub_resource type="FogMaterial" id="FogMaterial_sea"]\ndensity = 0.12\nalbedo = Color(0.6, 0.66, 0.74, 1)')

S.node("HotelMiramare", "Node3D", None)
S.node("WorldEnvironment", "WorldEnvironment", ".", ['environment = ExtResource("2")'])
S.node("Ambience", "AudioStreamPlayer", ".", ['stream = ExtResource("3")', "volume_db = -8.0", 'bus = &"Ambience"', 'script = ExtResource("4")'])

# --- Structure ------------------------------------------------------------------

S.group("Structure")
for floor, _ in FLOORS:
    S.group("Structure/" + floor)
S.group("Structure/Stairs")
S.group("Structure/Lift")
S.group("Structure/Outside")

# Door positions per floor, on the corridor walls (z -1 north, z 1 south).
CORRIDOR_NORTH_GAPS = {
    "Basement": [6.0, 15.0, 27.0],
    "GroundFloor": [9.0],
    "FirstFloor": [3.0, 9.0, 15.0, 27.0],
    "SecondFloor": [3.0, 9.0, 15.0, 27.0],
}
CORRIDOR_SOUTH_GAPS = {
    "Basement": [3.0, 9.0, 15.0, 27.0],
    "GroundFloor": [3.0, 9.0, 15.0, 21.0, 27.0],
    "FirstFloor": [3.0, 9.0, 15.0, 27.0],
    "SecondFloor": [3.0, 9.0, 15.0, 27.0],
}

for floor, y in FLOORS:
    p = "Structure/" + floor
    slab(p, "Floor", y, hole=floor != "Basement")
    # Outside walls. The front door (GF) and room 22's balcony (2F) open north.
    north_gaps = {"GroundFloor": [(26.0, DOOR_W)], "SecondFloor": [(27.0, DOOR_W)]}.get(floor, [])
    wall_x(p, "WallNorth", -7, -0.1, 30.1, y, north_gaps)
    wall_x(p, "WallSouth", 7, -0.1, 30.1, y)
    wall_z(p, "WallWest", 0, -6.9, 6.9, y)
    wall_z(p, "WallEast", 30, -6.9, 6.9, y)
    # Corridor walls. GF: the dining room's wall only; the lobby is open.
    # 1F and 2F: the lift hall (x 18..24) is open to the corridor.
    gaps = [(x, DOOR_W) for x in CORRIDOR_NORTH_GAPS[floor]]
    if floor == "GroundFloor":
        wall_x(p, "WallCorridorNorth", -1, 0.1, 18.1, y, gaps)
    elif floor == "Basement":
        wall_x(p, "WallCorridorNorth", -1, 0.1, 29.9, y, gaps)
    else:
        wall_x(p, "WallCorridorNorth", -1, 0.1, 18.1, y, [g for g in gaps if g[0] < 18])
        wall_x(p, "WallCorridorNorth", -1, 23.9, 29.9, y, [g for g in gaps if g[0] > 24])
    wall_x(p, "WallCorridorSouth", 1, 0.1, 29.9, y, [(x, DOOR_W) for x in CORRIDOR_SOUTH_GAPS[floor]])
    # Walls between the rooms.
    north_walls = {
        "Basement": [12, 18, 24],
        "GroundFloor": [18],
        "FirstFloor": [6, 12, 18, 24],
        "SecondFloor": [6, 12, 18, 24],
    }[floor]
    for x in north_walls:
        door = [(-3.5, DOOR_W)] if floor == "GroundFloor" and x == 18 else []
        wall_z(p, "WallRooms", x, -6.9, -1.1, y, door)
    for x in [6, 12, 18, 24]:
        wall_z(p, "WallRooms", x, 1.1, 6.9, y)

# Room 22's and room 21's bathrooms, in the corner by the room door.
y2 = Y["SecondFloor"]
wall_z("Structure/SecondFloor", "WallBathroom22", 26.2, -3.4, -1.1, y2)
wall_x("Structure/SecondFloor", "WallBathroom22", -3.4, 24.1, 26.3, y2, [(25.15, 1.0)])
wall_z("Structure/SecondFloor", "WallBathroom21", 26.2, 1.1, 3.4, y2)
wall_x("Structure/SecondFloor", "WallBathroom21", 3.4, 24.1, 26.3, y2, [(25.15, 1.0)])
# Room 22's balcony, with frosted dividers on both sides.
S.box("Structure/SecondFloor", "Balcony", 24.6, 29.9, y2 - SLAB, y2, -8.6, -7.1, "Mat_floor")
S.box("Structure/SecondFloor", "BalconyRailing", 24.6, 29.9, y2, y2 + 1.1, -8.6, -8.5)
S.box("Structure/SecondFloor", "BalconyDivider", 24.6, 24.7, y2, y2 + 2.0, -8.5, -7.1)
S.box("Structure/SecondFloor", "BalconyDivider", 29.8, 29.9, y2, y2 + 2.0, -8.5, -7.1)

# The roof over 2F.
slab("Structure/SecondFloor", "Roof", y2 + CEILING + SLAB, hole=False)

# Stairs: a switchback in the west stairwell (x 0..6, z 1..7), from the
# basement to 2F. On each floor the landing is z 1..2.7; going up takes the
# west lane south to a half landing (z 5.3..6.9), then the east lane north.
RISE = STOREY / 2
ANGLE = math.atan2(RISE, RUN_END - RUN_START)
LENGTH = math.hypot(RISE, RUN_END - RUN_START) + 0.1


def ramp(name, lane_x, y_low, rising_south):
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    if rising_south:
        basis = ((1, 0, 0), (0, c, -s), (0, s, c))
    else:
        basis = ((1, 0, 0), (0, c, s), (0, -s, c))
    normal = basis[1]
    top_mid = (lane_x, y_low + RISE / 2, (RUN_START + RUN_END) / 2)
    center = tuple(t - n * SLAB / 2 for t, n in zip(top_mid, normal))
    S.body("Structure/Stairs", name, center, (2.8, SLAB, LENGTH), "Mat_floor", basis)


S.box("Structure/Stairs", "CentreWall", 2.9, 3.1, Y["Basement"], y2 + CEILING, RUN_START, RUN_END)
for floor, y in FLOORS[:-1]:
    ramp("Ramp", 1.5, y, rising_south=True)
    if floor == "Basement":
        # Solid under the first half landing and the east flight above it.
        S.box("Structure/Stairs", "HalfLanding", 0.1, 5.9, y, y + RISE, RUN_END, 6.9, "Mat_floor")
        S.box("Structure/Stairs", "Under", 3.1, 5.9, y, y + RISE, RUN_START, RUN_END, "Mat_floor")
    else:
        S.box("Structure/Stairs", "HalfLanding", 0.1, 5.9, y + RISE - SLAB, y + RISE, RUN_END, 6.9, "Mat_floor")
    ramp("Ramp", 4.5, y + RISE, rising_south=False)
# 2F is the top: a railing over the west lane's drop.
S.box("Structure/Stairs", "Railing", 0.1, 2.9, y2, y2 + 1.1, RUN_START - 0.1, RUN_START)

# The lift: a solid core in the lift hall (x 18..24) through every floor.
S.box("Structure/Lift", "LiftCore", 19.5, 22.5, Y["Basement"], y2 + CEILING, -6.9, -4.8, "Mat_metal")

# Outside: the seafront in the fog, north of the hotel at GF level.
S.box("Structure/Outside", "Seafront", -10, 40, -0.2, 0, -30, -7.1, "Mat_floor")
S.node("FogBank", "FogVolume", "Structure/Outside", ["transform = " + transform((15, 1.5, -18)), "size = Vector3(50, 3, 22)", 'material = SubResource("FogMaterial_sea")'])

# --- Props ----------------------------------------------------------------------

S.group("Props")
for floor, _ in FLOORS:
    S.group("Props/" + floor)


def prop(floor, name, x0, x1, z0, z1, h0, h1, mat="Mat_prop"):
    y = Y[floor]
    S.box("Props/" + floor, name, x0, x1, y + h0, y + h1, z0, z1, mat)


for floor in ["GroundFloor", "FirstFloor", "SecondFloor"]:
    prop(floor, "LiftDoors", 20.3, 21.7, -4.8, -4.7, 0, 2.2, "Mat_metal")

# 2F
prop("SecondFloor", "Bed", 27.9, 29.9, -4.9, -4.0, 0, 0.5)
prop("SecondFloor", "Bed", 27.9, 29.9, -4.0, -3.1, 0, 0.5)
prop("SecondFloor", "Nightstand", 29.4, 29.9, -5.6, -5.0, 0, 0.6)
prop("SecondFloor", "Desk", 24.1, 24.7, -6.2, -4.6, 0, 0.75)
prop("SecondFloor", "BathroomCabinet", 24.1, 24.3, -2.6, -2.0, 1.2, 1.7)
prop("SecondFloor", "BlockadeRoom28", 2.2, 3.8, -1.05, -0.95, 1.1, 1.3)
prop("SecondFloor", "ChairRoom28", 2.75, 3.25, -4.25, -3.75, 0, 0.9)
prop("SecondFloor", "CoatStandRoom26", 8.8, 9.2, -6.6, -6.2, 0, 1.8)
prop("SecondFloor", "TrayRoom26", 9.8, 10.3, -0.9, -0.5, 0, 0.06)
prop("SecondFloor", "Bed", 28.0, 29.9, 4.0, 5.0, 0, 0.5)
prop("SecondFloor", "Shower", 24.2, 25.0, 1.2, 2.0, 0, 0.1)

# 1F
prop("FirstFloor", "KeyCabinet", 0.1, 0.45, -4.6, -3.4, 0.9, 2.1, "Mat_metal")
prop("FirstFloor", "LinenTrolley", 3.6, 4.6, -6.0, -5.4, 0, 1.0)
prop("FirstFloor", "Bed", 27.9, 29.9, -4.9, -4.0, 0, 0.5)
prop("FirstFloor", "Bed", 27.9, 29.9, -4.0, -3.1, 0, 0.5)
prop("FirstFloor", "Nightstand", 29.4, 29.9, -5.6, -5.0, 0, 0.6)
prop("FirstFloor", "Bed", 10.0, 11.9, -5.0, -4.0, 0, 0.5)
prop("FirstFloor", "Wardrobe", 17.3, 17.9, 3.0, 4.5, 0, 2.0)
prop("FirstFloor", "Scaffolding", 6.2, 7.0, 1.8, 6.8, 0, 2.4, "Mat_metal")
prop("FirstFloor", "ChuteTop", 8.6, 9.4, 4.1, 4.9, 0, 1.0, "Mat_chute")

# GF
for x in [3.0, 9.0, 15.0]:
    for z in [-5.0, -2.8]:
        prop("GroundFloor", "DiningTable", x - 0.6, x + 0.6, z - 0.6, z + 0.6, 0, 0.75)
prop("GroundFloor", "ReceptionDesk", 19.5, 25.0, -2.5, -0.5, 0, 1.1)
prop("GroundFloor", "ClockWall", 29.8, 29.9, -6.0, -2.0, 1.6, 2.6)
prop("GroundFloor", "KeyBoard", 23.0, 24.6, 0.8, 0.9, 1.2, 2.0)
prop("GroundFloor", "ObstacleSunbeds", 2.0, 4.0, 0.15, 0.9, 0, 2.0)
prop("GroundFloor", "Skip", 7.5, 10.5, 3.5, 5.5, 0, 1.2, "Mat_metal")
prop("GroundFloor", "ChuteBottom", 8.6, 9.4, 4.1, 4.9, 1.6, 3.0, "Mat_chute")
prop("GroundFloor", "KitchenCounter", 12.2, 17.8, 6.2, 6.9, 0, 0.9)
prop("GroundFloor", "Stove", 14.0, 15.2, 3.5, 4.5, 0, 0.9, "Mat_metal")
prop("GroundFloor", "OfficeDesk", 20.0, 22.0, 4.0, 5.0, 0, 0.75)
prop("GroundFloor", "OfficeWallCabinet", 23.7, 23.9, 2.5, 3.3, 1.2, 1.8)
prop("GroundFloor", "Sofa", 25.0, 28.0, 5.6, 6.6, 0, 0.8)
prop("GroundFloor", "Radio", 29.2, 29.8, 3.0, 3.4, 0, 0.9)

# Basement
for x in [0.7, 1.6, 2.5, 3.4]:
    prop("Basement", "WashingMachine", x, x + 0.7, -6.8, -6.1, 0, 0.9, "Mat_metal")
prop("Basement", "LinenCart", 6.5, 7.4, -6.2, -5.6, 0, 1.0)
prop("Basement", "LinenCart", 9.0, 9.9, -2.4, -1.8, 0, 1.0)
for x in [4.8, 7.0, 9.2]:
    prop("Basement", "Sheet", x, x + 1.6, -3.52, -3.48, 0.8, 2.3, "Mat_sheet")
prop("Basement", "Boilers", 15.4, 16.6, -6.0, -2.0, 0, 2.4, "Mat_metal")
prop("Basement", "Tank", 16.6, 17.9, -2.0, -1.1, 0, 1.6, "Mat_metal")
prop("Basement", "SwitchboardBasement", 13.6, 14.8, -6.9, -6.75, 0.8, 2.2, "Mat_metal")
prop("Basement", "CeilingPipes", 0.2, 29.8, 0.6, 0.75, 2.6, 2.75, "Mat_metal")
prop("Basement", "ShutterStaff", 17.93, 18.07, -0.9, 0.9, 0, CEILING, "Mat_metal")
prop("Basement", "ShutterButton", 17.3, 17.5, 0.85, 0.9, 1.1, 1.3, "Mat_metal")
prop("Basement", "Lockers", 24.1, 24.6, -6.5, -2.0, 0, 2.0, "Mat_metal")
prop("Basement", "Lockers", 29.4, 29.9, -6.5, -4.0, 0, 2.0, "Mat_metal")
prop("Basement", "PorterLocker", 29.4, 29.9, -4.0, -3.4, 0, 2.0, "Mat_metal")
prop("Basement", "Lockers", 29.4, 29.9, -3.4, -2.0, 0, 2.0, "Mat_metal")
prop("Basement", "StaffTable", 26.0, 28.0, 3.5, 4.7, 0, 0.75)
prop("Basement", "Hotplate", 29.3, 29.9, 5.0, 6.0, 0, 0.9, "Mat_metal")

# --- Lights ---------------------------------------------------------------------

S.group("Lights")
for floor in ["SecondFloor", "GroundFloor", "Basement"]:
    S.group("Lights/" + floor)


def lamp(parent, name, pos, energy, rng, color=(1, 0.82, 0.6), shadow=False):
    props = [
        "transform = " + transform(pos),
        "light_color = Color(%s, 1)" % ", ".join(f(c) for c in color),
        "light_energy = %s" % f(energy),
        "omni_range = %s" % f(rng),
    ]
    if shadow:
        props.append("shadow_enabled = true")
    S.node(S.unique(parent, name), "OmniLight3D", parent, props)


# 2F: every lamp on, except room 26's.
for x in [3, 9, 15, 21, 27]:
    lamp("Lights/SecondFloor", "CorridorLamp", (x, y2 + 2.7, 0), 1.0, 5.0, shadow=True)
for name, x, z in [("LampRoom22", 27.5, -4.5), ("LampRoom28", 3, -4), ("LampLiftHall", 21, -3), ("LampRoom21", 27.5, 4.5)]:
    lamp("Lights/SecondFloor", name, (x, y2 + 2.6, z), 1.0, 6.0)
# GF: only the porter's desk lamp.
lamp("Lights/GroundFloor", "DeskLamp", (24.3, 1.5, -1.0), 1.2, 5.0, shadow=True)
# Basement: the boiler room's lights, off until the power comes back.
S.node("BoilerRoom", "Node3D", "Lights/Basement", ["visible = false"])
for z in [-5.5, -2.5]:
    lamp("Lights/Basement/BoilerRoom", "Lamp", (14.5, Y["Basement"] + 2.7, z), 1.4, 6.0, (0.85, 0.9, 1.0), shadow=True)

# --- Doors ----------------------------------------------------------------------

S.group("Doors")
for floor, _ in FLOORS:
    S.group("Doors/" + floor)

# (floor, node, id, x, z, locked, key, message, turned)
DOORS = [
    ("SecondFloor", "DoorRoom21", "door_room_21", 27, 1, False, None, None),
    ("SecondFloor", "DoorRoom22", "door_room_22", 27, -1, False, None, None),
    ("SecondFloor", "DoorRoom23", "door_room_23", 15, 1, True, None, None),
    ("SecondFloor", "DoorRoom24", "door_room_24", 15, -1, True, None, "Do not disturb."),
    ("SecondFloor", "DoorRoom25", "door_room_25", 9, 1, True, None, None),
    ("SecondFloor", "DoorRoom26", "door_room_26", 9, -1, False, None, None),
    ("SecondFloor", "DoorStairs2F", "door_stairs_2f", 3, 1, True, "key_stairs", None),
    ("FirstFloor", "DoorLinenRoom", "door_linen_room", 3, -1, False, None, None),
    ("FirstFloor", "DoorRoom11", "door_room_11", 27, 1, True, None, None),
    ("FirstFloor", "DoorRoom12", "door_room_12", 27, -1, False, None, None),
    ("FirstFloor", "DoorRoom13", "door_room_13", 15, 1, False, None, None),
    ("FirstFloor", "DoorRoom14", "door_room_14", 15, -1, True, None, None),
    ("FirstFloor", "DoorRoom15", "door_room_15", 9, 1, False, None, None),
    ("FirstFloor", "DoorRoom16", "door_room_16", 9, -1, True, "key_room_16", None),
    ("FirstFloor", "DoorStairs1F", "door_stairs_1f", 3, 1, True, "key_stairs", None),
    ("GroundFloor", "DoorStairsGF", "door_stairs_gf", 3, 1, True, None, "Something heavy on the other side."),
    ("GroundFloor", "DoorBuildingSite", "door_building_site_gf", 9, 1, False, None, None),
    ("GroundFloor", "DoorKitchen", "door_kitchen", 15, 1, False, None, None),
    ("GroundFloor", "DoorDiningCorridor", "door_dining_corridor", 9, -1, False, None, None),
    ("GroundFloor", "DoorDiningLobby", "door_dining_lobby", 18, -3.5, False, None, None),
    ("GroundFloor", "DoorOfficeLobby", "door_office_lobby", 21, 1, False, None, None),
    ("GroundFloor", "DoorTVRoom", "door_tv_room", 27, 1, False, None, None),
    ("GroundFloor", "DoorFront", "door_front", 26, -7, True, "key_front_door", None),
    ("Basement", "DoorBasement", "door_basement", 3, 1, True, "key_basement", "Chained shut."),
    ("Basement", "DoorLaundry", "door_laundry", 6, -1, False, None, None),
    ("Basement", "DoorBoilerRoom", "door_boiler_room", 15, -1, False, None, None),
    ("Basement", "DoorStorage", "door_storage", 9, 1, True, None, None),
    ("Basement", "DoorPantry", "door_pantry", 15, 1, True, None, None),
    ("Basement", "DoorStaffRoom", "door_staff_room", 27, 1, False, None, None),
    ("Basement", "DoorChangingRoom", "door_changing_room", 27, -1, False, None, None),
]

for floor, name, door_id, x, z, locked, key, message in DOORS:
    turned = name == "DoorDiningLobby"
    props = ["transform = " + transform((x, Y[floor], z), TURNED if turned else None)]
    if locked:
        props.append("is_locked = true")
    if message:
        props.append('locked_message = "%s"' % message)
    if key:
        props.append('key_id = &"%s"' % key)
    props.append('door_id = &"%s"' % door_id)
    if name == "DoorStairsGF":
        props.append('metadata/blocked_by = &"obstacle_sunbeds"')
    S.node(name, None, "Doors/" + floor, props, instance="5")

# --- Navigation and player ----------------------------------------------------

S.node("NavigationRegion3D", "NavigationRegion3D", ".", ['navigation_mesh = ExtResource("6")'] if WITH_NAVMESH else [])
SPAWN = (26.8, y2 + 0.1, -4.0)
S.node("PlayerSpawn", "Marker3D", ".", ["transform = " + transform(SPAWN)])
S.node("Player", None, ".", ["transform = " + transform(SPAWN)], instance="1")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
paths = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
out_path = paths[0] if paths else os.path.join(ROOT, "scenes", "levels", "hotel_miramare.tscn")
with open(out_path, "w") as out:
    out.write(S.text())
print("Wrote %s: %d nodes" % (out_path, len(S.nodes)))
