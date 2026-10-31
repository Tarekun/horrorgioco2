"""Builds the hotel's modular kit and its simple props as glTF, within docs/design/visual-style.md.

Runs inside the pinned Blender (.blender-version, installed by tools/install_blender.sh):

    blender --background --factory-startup --python tools/make_kit.py -- \\
        PIECE OUT_DIR [--variants wallpaper,brick]

tools/build_assets.py runs it for every model entry with "make" in
assets/sources.json. PIECE is one of the builders in PIECES. It writes
OUT_DIR/<piece>.gltf, or with --variants one OUT_DIR/<piece>_<variant>.gltf
per variant: a shared material for kit pieces, a number or a sign for the
pieces that list their own.

The kit sits on a 2 m grid, 3 m from floor to ceiling and 3.2 m from floor to
floor, as in the graybox (docs/design/slice.md). Sizes are in metres and axes
are Godot's (Y up, -Z forward):

- floor and ceiling are 2 x 2 m, with the origin at their centre;
- wall is half a wall: 2 m wide, 3 m high and 0.1 m thick, finished on its
  front (+Z), with the origin at the bottom centre of its back. A wall
  between two rooms is two pieces back to back on the grid line, so each
  side gets its own material;
- wall_door has a 1.6 x 2.5 m opening that door_frame lines down to the
  1.4 x 2.4 m of scenes/levels/door.tscn; door_frame is centred on the grid
  line, through both halves. wall_window has a 1.2 x 1.4 m opening, 0.9 m up;
- stairs is one 2.8 m wide flight rising half a storey (1.6 m) over 2.6 m
  towards -Z, from the origin at the foot of its first riser, and
  stair_landing the 2.9 x 1.6 m slab between flights, with the origin at
  the centre of its top.

UVs are planar in metres, so a texture lines up across neighbouring pieces;
each material's uv1_scale sets how many metres one repeat covers. Surfaces
that take a shared material are named after it, and build_assets.py maps
them onto assets/materials/<name>.tres on import; the rest (linen, brass,
lamp shades, lettering) get a flat colour. Objects named *-convcolonly
become convex colliders in Godot and aren't drawn.
"""

import argparse
import math
import os
import sys

import bmesh
import bpy
import mathutils

Vector = mathutils.Vector

STOREY = 3.0
CELL = 2.0
HALF_WALL = 0.1
DOOR_OPENING = (1.6, 2.5)
DOOR_CLEAR = (1.4, 2.4)
WINDOW_OPENING = (1.2, 1.4, 0.9)
STEPS = 10
STEP_RISE = 0.16
STEP_RUN = 0.26
FLIGHT_WIDTH = 2.8

# Flat colours for surfaces that don't take a shared material:
# (linear RGB, roughness, metallic).
COLOURS = {
    "linen": ((0.72, 0.69, 0.62), 0.95, 0.0),
    "blanket": ((0.32, 0.42, 0.4), 0.95, 0.0),
    "brass": ((0.5, 0.33, 0.1), 0.4, 0.8),
    "lamp_shade": ((0.75, 0.62, 0.42), 0.9, 0.0),
    "opal_glass": ((0.8, 0.78, 0.72), 0.3, 0.0),
    "green_glass": ((0.03, 0.2, 0.08), 0.3, 0.0),
    "enamel": ((0.78, 0.76, 0.7), 0.5, 0.0),
    "card": ((0.75, 0.68, 0.5), 0.95, 0.0),
    "lettering": ((0.02, 0.02, 0.02), 0.8, 0.0),
    "red_lettering": ((0.45, 0.03, 0.02), 0.8, 0.0),
}

# Each sign: its lines, its plate (width, height), plate and lettering
# colours, and whether it hangs from a cord (out of order, do not disturb)
# or is screwed to the wall.
SIGNS = {
    "out_of_order": (["FUORI", "SERVIZIO"], (0.36, 0.22), "card", "red_lettering", True),
    "do_not_disturb": (["NON", "DISTUR-", "BARE"], (0.16, 0.24), "card", "lettering", True),
    "stairs": (["SCALE"], (0.36, 0.1), "enamel", "lettering", False),
    "lift": (["ASCENSORE"], (0.36, 0.1), "enamel", "lettering", False),
    "reception": (["RICEVIMENTO"], (0.5, 0.1), "enamel", "lettering", False),
    "private": (["PRIVATO"], (0.3, 0.1), "enamel", "red_lettering", False),
}


def main():
    args = parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])
    builder = PIECES[args.piece]
    variants = args.variants.split(",") if args.variants else [None]
    for variant in variants:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        name = args.piece if variant is None else f"{args.piece}_{variant}"
        builder() if variant is None else builder(variant)
        path = os.path.join(args.out_dir, name + ".gltf")
        export(path)
        print(f"make_kit: {path}: {count_triangles()} triangles")


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="make_kit.py", description=__doc__.split("\n")[0])
    parser.add_argument("piece", choices=sorted(PIECES), help="piece to build")
    parser.add_argument("out_dir", help="folder to write the glTF files to")
    parser.add_argument("--variants", help="comma-separated variants to build")
    return parser.parse_args(argv)


class Shape:
    """Faces of one object, in Godot's axes, each with a material name."""

    def __init__(self):
        self.faces = []

    def face(self, points, normal, material):
        points = [Vector(p) for p in points]
        actual = (points[1] - points[0]).cross(points[2] - points[0])
        if actual.dot(Vector(normal)) < 0:
            points.reverse()
        self.faces.append((points, Vector(normal).normalized(), material))

    def box(self, low, high, material, sides="+x -x +y -y +z -z"):
        (x0, y0, z0), (x1, y1, z1) = low, high
        quads = {
            "+x": ([(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)], (1, 0, 0)),
            "-x": ([(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)], (-1, 0, 0)),
            "+y": ([(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)], (0, 1, 0)),
            "-y": ([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], (0, -1, 0)),
            "+z": ([(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], (0, 0, 1)),
            "-z": ([(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)], (0, 0, -1)),
        }
        for side in sides.split():
            self.face(*quads[side], material)

    def prism(self, centre, y0, y1, r0, r1, sides, material, caps="", inside=False):
        """A faceted cylinder or cone about the Y axis, radius r0 at y0 and r1 at y1."""
        cx, cz = centre
        ring = [
            (math.cos(2 * math.pi * i / sides), math.sin(2 * math.pi * i / sides))
            for i in range(sides)
        ]
        for i in range(sides):
            (ax, az), (bx, bz) = ring[i], ring[(i + 1) % sides]
            quad = [
                (cx + ax * r0, y0, cz + az * r0),
                (cx + bx * r0, y0, cz + bz * r0),
                (cx + bx * r1, y1, cz + bz * r1),
                (cx + ax * r1, y1, cz + az * r1),
            ]
            mid = ((ax + bx) / 2, (az + bz) / 2)
            self.face(quad, (mid[0], 0, mid[1]), material)
            if inside:
                self.face(quad, (-mid[0], 0, -mid[1]), material)
        if "bottom" in caps:
            self.face([(cx + x * r0, y0, cz + z * r0) for x, z in ring], (0, -1, 0), material)
        if "top" in caps:
            self.face([(cx + x * r1, y1, cz + z * r1) for x, z in ring], (0, 1, 0), material)

    def extrude(self, profile, half, material):
        """A convex (z, y) profile extruded from -half to half along X."""
        centre = Vector((0, sum(y for _, y in profile), sum(z for z, _ in profile))) / len(profile)
        for (z0, y0), (z1, y1) in zip(profile, profile[1:] + profile[:1]):
            outward = Vector((0, (y0 + y1) / 2, (z0 + z1) / 2)) - centre
            quad = [(-half, y0, z0), (half, y0, z0), (half, y1, z1), (-half, y1, z1)]
            self.face(quad, outward, material)
        for side in (-1, 1):
            self.face([(side * half, y, z) for z, y in profile], (side, 0, 0), material)

    def build(self, name):
        mesh = bpy.data.meshes.new(name)
        verts, polygons = [], []
        for points, _, _ in self.faces:
            polygons.append(list(range(len(verts), len(verts) + len(points))))
            verts.extend(to_blender(p) for p in points)
        mesh.from_pydata(verts, [], polygons)
        names = sorted({material for _, _, material in self.faces})
        for material in names:
            mesh.materials.append(get_material(material))
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for polygon, (points, normal, material) in zip(mesh.polygons, self.faces):
            polygon.material_index = names.index(material)
            for loop_index, point in zip(polygon.loop_indices, points):
                u, v = planar_uv(point, normal)
                # Blender's V runs up and glTF's down; the exporter flips it.
                uv_layer.data[loop_index].uv = (u, -v)
        mesh.validate()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def to_blender(point):
    # Godot is Y up, -Z forward; Blender is Z up, +Y forward. The glTF
    # exporter turns this back into Godot's axes.
    x, y, z = point
    return (x, -z, y)


def planar_uv(point, normal):
    """Projects a point onto the plane its face mostly faces, in metres, upright."""
    x, y, z = point
    axis = max(range(3), key=lambda i: abs(normal[i]))
    if axis == 1:
        return (x, z) if normal.y > 0 else (x, -z)
    if axis == 2:
        return (x, -y) if normal.z > 0 else (-x, -y)
    return (-z, -y) if normal.x > 0 else (z, -y)


def get_material(name):
    material = bpy.data.materials.get(name)
    if material:
        return material
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    shader = material.node_tree.nodes["Principled BSDF"]
    # A shared material only needs its name: Godot swaps in the .tres.
    colour, roughness, metallic = COLOURS.get(name, ((0.5, 0.5, 0.5), 0.9, 0.0))
    shader.inputs["Base Color"].default_value = (*colour, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    return material


def collider(name, low, high):
    """A box Godot turns into a convex collider."""
    shape = Shape()
    shape.box(low, high, "collider")
    return collider_from(name, shape)


def collider_from(name, shape):
    obj = shape.build(f"{name}-convcolonly")
    obj.data.materials.clear()
    obj.data.uv_layers.remove(obj.data.uv_layers[0])
    return obj


# Kit pieces.


def floor(material):
    shape = Shape()
    shape.box((-1, 0, -1), (1, 0, 1), material, "+y")
    shape.build("Mesh")
    collider("Collision", (-1, -0.2, -1), (1, 0, 1))


def ceiling(material):
    shape = Shape()
    shape.box((-1, 0, -1), (1, 0, 1), material, "-y")
    shape.build("Mesh")


def wall(material):
    shape = Shape()
    shape.box((-1, 0, 0), (1, STOREY, HALF_WALL), material, "+z +x -x")
    shape.build("Mesh")
    collider("Collision", (-1, 0, 0), (1, STOREY, HALF_WALL))


def wall_door(material):
    width, height = DOOR_OPENING
    wall_with_opening(material, width, 0.0, height)
    for side in (-1, 1):
        low, high = sorted((side * width / 2, side * 1.0))
        name = "CollisionLeft" if side < 0 else "CollisionRight"
        collider(name, (low, 0, 0), (high, STOREY, HALF_WALL))
    collider("CollisionTop", (-width / 2, height, 0), (width / 2, STOREY, HALF_WALL))


def wall_window(material):
    width, height, sill = WINDOW_OPENING
    wall_with_opening(material, width, sill, sill + height)
    collider("Collision", (-1, 0, 0), (1, STOREY, HALF_WALL))


def wall_with_opening(material, width, bottom, top):
    shape = Shape()
    x0, x1, depth = -width / 2, width / 2, HALF_WALL
    shape.box((-1, 0, 0), (x0, STOREY, depth), material, "+z -x +x")
    shape.box((x1, 0, 0), (1, STOREY, depth), material, "+z +x -x")
    shape.box((x0, top, 0), (x1, STOREY, depth), material, "+z -y")
    if bottom > 0:
        shape.box((x0, 0, 0), (x1, bottom, depth), material, "+z +y")
    shape.build("Mesh")


def door_frame():
    shape = Shape()
    outer, inner = DOOR_OPENING[0] / 2 + 0.08, DOOR_CLEAR[0] / 2
    head, top = DOOR_CLEAR[1], DOOR_OPENING[1] + 0.08
    depth = HALF_WALL + 0.02
    shape.box((-outer, 0, -depth), (-inner, head, depth), "door", "+x -x +z -z")
    shape.box((inner, 0, -depth), (outer, head, depth), "door", "+x -x +z -z")
    shape.box((-outer, head, -depth), (outer, top, depth), "door", "+x -x -y +z -z")
    shape.build("Mesh")
    collider("CollisionLeft", (-outer, 0, -depth), (-inner, head, depth))
    collider("CollisionRight", (inner, 0, -depth), (outer, head, depth))


def stairs(material):
    shape = Shape()
    half = FLIGHT_WIDTH / 2
    run, rise = STEPS * STEP_RUN, STEPS * STEP_RISE
    profile = [(0.0, 0.0)]
    for i in range(STEPS):
        z, y = -i * STEP_RUN, (i + 1) * STEP_RISE
        shape.box((-half, i * STEP_RISE, z), (half, y, z), material, "+z")
        shape.box((-half, y, z - STEP_RUN), (half, y, z), material, "+y")
        profile += [(z, y), (z - STEP_RUN, y)]
    # The slab underneath, parallel to the flight and 0.16 m thick at the top.
    underside = [(-run, rise - STEP_RISE), (-STEP_RUN, 0.0)]
    profile += underside
    for side in (-1, 1):
        shape.face([(side * half, y, z) for z, y in profile], (side, 0, 0), material)
    (z0, y0), (z1, y1) = underside
    slope = Vector((0, y0 - y1, z0 - z1))
    shape.face(
        [(-half, y0, z0), (half, y0, z0), (half, y1, z1), (-half, y1, z1)],
        slope.cross(Vector((1, 0, 0))),
        material,
    )
    shape.build("Mesh")
    # Walk up a smooth ramp rather than catch on every step.
    ramp = Shape()
    ramp.face([(-half, 0, 0), (half, 0, 0), (half, rise, -run), (-half, rise, -run)], (0, 1, 1), "")
    ramp.face([(-half, 0, 0), (half, 0, 0), (half, y1, z1), (-half, y1, z1)], (0, -1, 0), "")
    ramp.face(
        [(-half, rise, -run), (half, rise, -run), (half, y0, z0), (-half, y0, z0)], (0, 0, -1), ""
    )
    ramp.face([(-half, y0, z0), (half, y0, z0), (half, y1, z1), (-half, y1, z1)], (0, -1, -1), "")
    collider_from("Collision", ramp)


def stair_landing(material):
    shape = Shape()
    low, high = (-1.45, -0.2, -0.8), (1.45, 0.0, 0.8)
    shape.box(low, high, material, "+y -y +z -z +x -x")
    shape.build("Mesh")
    collider("Collision", low, high)


# Props.


def bed():
    shape = Shape()
    for x in (-0.43, 0.39):
        for z in (-0.98, 0.94):
            shape.box((x, 0, z), (x + 0.04, 0.15, z + 0.04), "door", "+x -x +z -z")
    shape.box((-0.45, 0.15, -1.0), (0.45, 0.3, 1.0), "door", "+x -x +z -z -y")
    shape.box((-0.47, 0.0, -1.04), (0.47, 0.95, -1.0), "door", "+x -x +y +z -z")
    shape.box((-0.47, 0.0, 1.0), (0.47, 0.55, 1.04), "door", "+x -x +y +z -z")
    shape.box((-0.44, 0.3, -0.99), (0.44, 0.5, 0.99), "linen", "+y +x -x")
    shape.box((-0.46, 0.25, -0.35), (0.46, 0.53, 1.0), "blanket", "+y +x -x +z -z")
    shape.box((-0.32, 0.5, -0.95), (0.32, 0.62, -0.6), "linen", "+y +x -x +z -z")
    shape.build("Mesh")
    collider("Collision", (-0.47, 0, -1.04), (0.47, 0.6, 1.04))
    collider("CollisionHead", (-0.47, 0, -1.04), (0.47, 0.95, -1.0))


def wardrobe():
    shape = Shape()
    shape.box((-0.48, 0, -0.28), (0.48, 0.08, 0.27), "door", "+z +x -x")
    shape.box((-0.5, 0.08, -0.3), (0.5, 2.0, 0.3), "door", "+x -x")
    shape.box((-0.53, 2.0, -0.33), (0.53, 2.06, 0.33), "door", "+y +x -x +z -z -y")
    for x0, x1 in ((-0.5, -0.005), (0.005, 0.5)):
        shape.box((x0, 0.08, 0.3), (x1, 2.0, 0.32), "door", "+z +x -x")
    shape.box((-0.5, 0.08, 0.3), (0.5, 2.0, 0.3), "door", "+z")
    for x in (-0.06, 0.04):
        shape.box((x, 1.0, 0.32), (x + 0.02, 1.2, 0.34), "brass", "+z +x -x +y -y")
    shape.build("Mesh")
    collider("Collision", (-0.53, 0, -0.33), (0.53, 2.06, 0.34))


def reception_desk():
    """The porter's desk: a U, open at the back, 2.2 m deep so that the porter
    stands out of melee reach (docs/design/slice.md)."""
    shape = Shape()
    panel, top = "wood_panelling", "door"
    width, front, back, height = 1.5, 1.0, -1.2, 1.1
    shape.box((-width, 0, front - 0.6), (width, height, front), panel, "+z -z")
    for side in (-1, 1):
        x0, x1 = sorted((side * width, side * (width - 0.5)))
        shape.box((x0, 0, back), (x1, height, front), panel, "+x -x -z")
        low, high = (x0 - 0.02, height, back - 0.02), (x1 + 0.02, height + 0.04, front + 0.02)
        shape.box(low, high, top, "+y +x -x -z")
        collider("CollisionLeft" if side < 0 else "CollisionRight", (low[0], 0, low[2]), high)
    counter = ((-width, height, front - 0.62), (width, height + 0.04, front + 0.05))
    shape.box(*counter, top, "+y -y +z -z")
    shape.box((-width + 0.5, 0.72, front - 0.9), (width - 0.5, 0.76, front - 0.6), top, "+y -y -z")
    shape.build("Mesh")
    collider("CollisionFront", (-width, 0, counter[0][2]), counter[1])


def desk_lamp():
    """A banker's lamp, for the porter's desk."""
    shape = Shape()
    shape.prism((0, 0), 0.0, 0.03, 0.09, 0.08, 8, "brass", caps="top")
    shape.prism((0, 0), 0.03, 0.3, 0.012, 0.012, 6, "brass")
    shape.extrude([(0.11, 0.28), (-0.11, 0.28), (-0.06, 0.36), (0.06, 0.36)], 0.16, "green_glass")
    shape.build("Mesh")


def bedside_lamp():
    shape = Shape()
    shape.prism((0, 0), 0.0, 0.02, 0.08, 0.08, 8, "brass", caps="top")
    shape.prism((0, 0), 0.02, 0.22, 0.05, 0.03, 8, "enamel")
    shape.prism((0, 0), 0.2, 0.4, 0.15, 0.09, 10, "lamp_shade", inside=True)
    shape.build("Mesh")


def ceiling_lamp():
    """Hangs from its origin, at the ceiling."""
    shape = Shape()
    shape.prism((0, 0), -0.02, 0.0, 0.06, 0.06, 8, "brass", caps="bottom")
    shape.prism((0, 0), -0.4, -0.02, 0.01, 0.01, 6, "brass")
    shape.prism((0, 0), -0.55, -0.4, 0.22, 0.05, 12, "opal_glass", inside=True)
    shape.build("Mesh")


def room_number(number):
    """Brass numerals for a room door, with the origin at their back centre."""
    lettering("Mesh", [number], 0.14, "brass", depth=0.006)


def sign(kind):
    lines, (width, height), plate, ink, hangs = SIGNS[kind]
    shape = Shape()
    low, high = (-width / 2, -height / 2, 0), (width / 2, height / 2, 0.005)
    shape.box(low, high, plate, "+z -z +x -x +y -y")
    if hangs:
        # A cord over a hook or a door handle, from the plate's top corners.
        top = height / 2
        for side in (-1, 1):
            x = side * width * 0.4
            shape.box((x - 0.002, top, 0.002), (x + 0.002, top + 0.08, 0.004), "lettering", "+z -z")
    shape.build("Mesh")
    size = min(height * 0.6 / len(lines), width * 0.85 / max(len(line) for line in lines) * 1.6)
    lettering("Lettering", lines, size, ink, z=0.006)


def lettering(name, lines, size, material, depth=0.0, z=0.0):
    """Flat or extruded text facing +Z, centred on the origin."""
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = "\n".join(lines)
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    curve.space_line = 0.9
    curve.resolution_u = 2
    curve.extrude = depth / 2
    obj = bpy.data.objects.new(name, curve)
    bpy.context.scene.collection.objects.link(obj)
    # Text lies in Blender's XY plane; stand it up to face Godot's +Z (-Y).
    obj.rotation_euler = (math.radians(90), 0, 0)
    obj.location = (0, -(z + depth / 2), 0)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj.select_set(False)
    obj.data.materials.append(get_material(material))
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    if depth == 0.0:
        # Blender fills some glyphs (I, T) facing backwards; turn them all to
        # the front, or Godot culls them.
        for face in bm.faces:
            if face.normal.z < 0:
                face.normal_flip()
    bm.to_mesh(obj.data)
    bm.free()


PIECES = {
    "floor": floor,
    "ceiling": ceiling,
    "wall": wall,
    "wall_door": wall_door,
    "wall_window": wall_window,
    "door_frame": door_frame,
    "stairs": stairs,
    "stair_landing": stair_landing,
    "bed": bed,
    "wardrobe": wardrobe,
    "reception_desk": reception_desk,
    "desk_lamp": desk_lamp,
    "bedside_lamp": bedside_lamp,
    "ceiling_lamp": ceiling_lamp,
    "room_number": room_number,
    "sign": sign,
}


def count_triangles():
    total = 0
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and not obj.name.endswith("-convcolonly"):
            obj.data.calc_loop_triangles()
            total += len(obj.data.loop_triangles)
    return total


def export(path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(path),
        export_format="GLTF_SEPARATE",
        export_yup=True,
        export_apply=True,
        export_extras=False,
        export_cameras=False,
        export_lights=False,
    )


if __name__ == "__main__":
    main()
