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
- wall is half a wall: 2 m wide, a storey (3.2 m) high and 0.1 m thick,
  finished on its front (+Z), with the origin at the bottom centre of its
  back. It reaches the next floor up, so a stairwell has no gap between
  storeys; in a room the ceiling hides the top. A wall between two rooms is
  two pieces back to back on the grid line, so each side gets its own
  material;
- wall_door has a 1.6 x 2.5 m opening that door_frame lines down to the
  1.4 x 2.4 m of scenes/levels/door.tscn; door_frame is centred on the grid
  line, through both halves. wall_window has a 1.2 x 1.4 m opening, 0.9 m up;
- stairs is one 2.8 m wide flight rising half a storey (1.6 m) over 2.6 m
  towards -Z, from the origin at the foot of its first riser, and
  stair_landing the 2.9 x 1.7 m slab between flights, with the origin at
  the centre of its top. stair_wall is the 2.6 m wall between the two
  flights of a switchback, finished on both sides;
- props stand on their origin with their front to +Z; those hung on a wall
  have the origin at the bottom centre of their back.

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

STOREY = 3.2
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
    "steel": ((0.42, 0.43, 0.44), 0.4, 0.8),
    "dark_steel": ((0.07, 0.07, 0.08), 0.6, 0.5),
    "galvanised": ((0.32, 0.33, 0.33), 0.6, 0.6),
    "locker_grey": ((0.26, 0.29, 0.29), 0.5, 0.3),
    "cabinet_green": ((0.1, 0.17, 0.13), 0.6, 0.3),
    "boiler_paint": ((0.06, 0.09, 0.07), 0.7, 0.3),
    "raw_wood": ((0.42, 0.3, 0.17), 0.9, 0.0),
    "chute_yellow": ((0.72, 0.48, 0.02), 0.6, 0.0),
    "skip_paint": ((0.5, 0.17, 0.03), 0.7, 0.2),
    "rubble": ((0.28, 0.25, 0.22), 1.0, 0.0),
    "canvas": ((0.38, 0.36, 0.3), 0.95, 0.0),
    "canvas_blue": ((0.06, 0.17, 0.4), 0.9, 0.0),
    "canvas_orange": ((0.6, 0.2, 0.04), 0.9, 0.0),
    "white_paint": ((0.7, 0.7, 0.66), 0.7, 0.0),
    "coat": ((0.05, 0.05, 0.06), 0.95, 0.0),
    "fabric": ((0.3, 0.25, 0.17), 0.95, 0.0),
    "curtain": ((0.45, 0.2, 0.06), 0.95, 0.0),
    "frosted_glass": ((0.55, 0.6, 0.62), 0.3, 0.0),
    "dusk_glass": ((0.1, 0.12, 0.2), 0.15, 0.0),
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

    def rod(self, start, end, radius, sides, material, caps=""):
        """A faceted cylinder from start to end, in any direction."""
        start, end = Vector(start), Vector(end)
        axis = (end - start).normalized()
        up = Vector((0, 1, 0)) if abs(axis.y) < 0.9 else Vector((1, 0, 0))
        u = axis.cross(up).normalized()
        v = axis.cross(u)
        ring = [
            u * math.cos(2 * math.pi * i / sides) + v * math.sin(2 * math.pi * i / sides)
            for i in range(sides)
        ]
        for a, b in zip(ring, ring[1:] + ring[:1]):
            quad = [start + a * radius, start + b * radius, end + b * radius, end + a * radius]
            self.face(quad, a + b, material)
        if "start" in caps:
            self.face([start + r * radius for r in ring], -axis, material)
        if "end" in caps:
            self.face([end + r * radius for r in ring], axis, material)

    def turn(self, first, angle, pivot):
        """Turns the faces from index first on by angle (degrees) about a vertical
        axis through pivot (x, z), as a hinge does."""
        rotation = mathutils.Matrix.Rotation(math.radians(angle), 3, "Y")
        centre = Vector((pivot[0], 0, pivot[1]))
        for i in range(first, len(self.faces)):
            points, normal, material = self.faces[i]
            points = [rotation @ (p - centre) + centre for p in points]
            self.faces[i] = (points, rotation @ normal, material)

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
    low, high = (-1.45, -0.2, -0.85), (1.45, 0.0, 0.85)
    shape.box(low, high, material, "+y -y +z -z +x -x")
    shape.build("Mesh")
    collider("Collision", low, high)


def stair_wall(material):
    shape = Shape()
    low, high = (-HALF_WALL, 0, -1.3), (HALF_WALL, STOREY, 1.3)
    shape.box(low, high, material, "+x -x +z -z")
    shape.build("Mesh")
    collider("Collision", low, high)


def railing():
    """One metre of balustrade along X, centred on its origin; railings join end to end."""
    shape = Shape()
    shape.box((-0.5, 0, -0.02), (-0.46, 1.05, 0.02), "dark_steel", "+x -x +z -z")
    shape.box((-0.5, 1.05, -0.03), (0.5, 1.1, 0.03), "dark_steel", "+y -y +z -z")
    shape.box((-0.5, 0.1, -0.01), (0.5, 0.13, 0.01), "dark_steel", "+y -y +z -z")
    for x in (-0.27, -0.06, 0.15, 0.36):
        shape.box((x, 0.13, -0.008), (x + 0.016, 1.05, 0.008), "dark_steel", "+x -x +z -z")
    shape.build("Mesh")
    collider("Collision", (-0.5, 0, -0.03), (0.5, 1.1, 0.03))


def window_frame():
    """A wooden window for wall_window's opening, through both halves of the wall, with
    the origin at the bottom centre of the opening on the grid line. The glass is dark
    and doesn't let the eye out, so it shows dusk whatever is behind it."""
    shape = Shape()
    width, height, _ = WINDOW_OPENING
    x, d = width / 2, HALF_WALL + 0.01
    shape.box((-x, 0, -d), (-x + 0.07, height, d), "door", "+x +z -z")
    shape.box((x - 0.07, 0, -d), (x, height, d), "door", "-x +z -z")
    shape.box((-x, height - 0.07, -d), (x, height, d), "door", "-y +z -z")
    shape.box((-x - 0.05, -0.04, -d - 0.06), (x + 0.05, 0.04, d + 0.06), "door")
    shape.box((-0.03, 0.04, -0.04), (0.03, height - 0.07, 0.04), "door", "+x -x +z -z")
    shape.box((-x + 0.07, 0.95, -0.04), (x - 0.07, 1.01, 0.04), "door", "+y -y +z -z")
    shape.box((-x + 0.07, 0.04, -0.005), (x - 0.07, height - 0.07, 0.005), "dusk_glass", "+z -z")
    shape.build("Mesh")


def curtain():
    """A drawn curtain, 1.4 m wide and 2.4 m long in eight pleats, hanging from a rail at
    its origin; front at +Z."""
    shape = Shape()
    pleats = 8
    xs = [-0.7 + 1.4 * i / pleats for i in range(pleats + 1)]
    for i, (x0, x1) in enumerate(zip(xs, xs[1:])):
        z0, z1 = (0.0, 0.06) if i % 2 == 0 else (0.06, 0.0)
        quad = [(x0, -2.4, z0), (x1, -2.4, z1), (x1, -0.05, z1), (x0, -0.05, z0)]
        normal = Vector((z0 - z1, 0, x1 - x0))
        shape.face(quad, normal, "curtain")
        shape.face(quad, -normal, "curtain")
    shape.rod((-0.8, -0.03, 0.03), (0.8, -0.03, 0.03), 0.012, 6, "brass")
    shape.build("Mesh")


def balcony_divider():
    """A frosted glass screen in a steel frame between two balconies, 1.9 m wide (X)
    and 2 m high."""
    shape = Shape()
    shape.box((-0.95, 0, -0.03), (-0.9, 2.0, 0.03), "dark_steel", "+x -x +y +z -z")
    shape.box((0.9, 0, -0.03), (0.95, 2.0, 0.03), "dark_steel", "+x -x +y +z -z")
    shape.box((-0.9, 1.95, -0.03), (0.9, 2.0, 0.03), "dark_steel", "+y -y +z -z")
    shape.box((-0.9, 0.05, -0.01), (0.9, 1.95, 0.01), "frosted_glass", "+z -z")
    shape.build("Mesh")
    collider("Collision", (-0.95, 0, -0.03), (0.95, 2.0, 0.03))


def lift_doors():
    """Steel lift doors in their frame, on the face of the lift shaft's wall, with the
    call button to the right."""
    shape = Shape()
    shape.box((-0.72, 0, 0), (-0.6, 2.22, 0.06), "steel", "+z +x -x +y")
    shape.box((0.6, 0, 0), (0.72, 2.22, 0.06), "steel", "+z +x -x +y")
    shape.box((-0.6, 2.1, 0), (0.6, 2.22, 0.06), "steel", "+z -y +y")
    for x0, x1 in ((-0.6, -0.004), (0.004, 0.6)):
        shape.box((x0, 0, 0), (x1, 2.1, 0.03), "steel", "+z +x -x")
    shape.box((0.85, 1.0, 0), (0.97, 1.3, 0.02), "steel", "+z +x -x +y -y")
    shape.rod((0.91, 1.15, 0.02), (0.91, 1.15, 0.03), 0.02, 8, "brass", caps="end")
    shape.build("Mesh")
    collider("Collision", (-0.72, 0, 0), (0.72, 2.22, 0.06))


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


def desk():
    """A writing desk, 1.4 m wide, 0.65 m deep and 0.75 m high, drawers on the right."""
    shape = Shape()
    shape.box((-0.7, 0.72, -0.33), (0.7, 0.75, 0.33), "door")
    shape.box((0.25, 0, -0.3), (0.68, 0.72, 0.3), "door", "+x -x +z -z")
    for y in (0.04, 0.27, 0.5):
        shape.box((0.27, y, 0.3), (0.66, y + 0.2, 0.32), "door", "+z +x -x +y -y")
        shape.box((0.43, y + 0.09, 0.32), (0.5, y + 0.11, 0.34), "brass", "+z +y -y")
    for z in (-0.3, 0.26):
        shape.box((-0.68, 0, z), (-0.64, 0.72, z + 0.04), "door", "+x -x +z -z")
    shape.box((-0.66, 0.35, -0.31), (0.25, 0.72, -0.29), "door", "+z -z")
    shape.build("Mesh")
    collider("Collision", (-0.7, 0, -0.33), (0.7, 0.75, 0.33))


def wall_cabinet():
    """A small wall cabinet, 0.5 m wide, 0.6 m high and 0.2 m deep."""
    shape = Shape()
    shape.box((-0.25, 0, 0), (0.25, 0.6, 0.2), "enamel", "+x -x +y -y +z")
    shape.box((-0.004, 0.02, 0.2), (0.004, 0.58, 0.201), "lettering", "+z")
    shape.box((0.03, 0.28, 0.2), (0.05, 0.34, 0.22), "brass", "+z +x -x +y -y")
    shape.build("Mesh")
    collider("Collision", (-0.25, 0, 0), (0.25, 0.6, 0.2))


def alarm_clock():
    """A wind-up alarm clock with two bells, 15 cm high; face at +Z."""
    shape = Shape()
    shape.rod((0, 0.07, -0.02), (0, 0.07, 0.02), 0.055, 12, "brass", caps="start")
    shape.rod((0, 0.07, 0.02), (0, 0.07, 0.021), 0.05, 12, "enamel", caps="end")
    shape.box((-0.003, 0.068, 0.021), (0.003, 0.105, 0.023), "lettering", "+z")
    shape.box((-0.003, 0.068, 0.021), (0.03, 0.074, 0.023), "lettering", "+z")
    for side in (-1, 1):
        shape.prism((side * 0.04, 0), 0.12, 0.15, 0.03, 0.012, 8, "brass", caps="top")
        shape.box((side * 0.04 - 0.008, 0, -0.008), (side * 0.04 + 0.008, 0.02, 0.008), "brass")
    shape.build("Mesh")


def coat_stand():
    """A bentwood coat stand with a coat left on it."""
    shape = Shape()
    shape.prism((0, 0), 0.0, 1.8, 0.022, 0.018, 6, "door", caps="top")
    for i in range(3):
        a = 2 * math.pi * i / 3
        shape.rod((0, 0.3, 0), (0.3 * math.cos(a), 0.0, 0.3 * math.sin(a)), 0.015, 5, "door")
        shape.rod((0, 1.65, 0), (0.15 * math.cos(a), 1.75, 0.15 * math.sin(a)), 0.01, 5, "door")
    shape.box((-0.2, 0.75, 0.03), (0.2, 1.65, 0.22), "coat", "+x -x +z -z -y")
    shape.prism((0, 0.12), 1.65, 1.72, 0.2, 0.06, 6, "coat", caps="top")
    shape.build("Mesh")
    collider("Collision", (-0.3, 0, -0.3), (0.3, 1.8, 0.3))


def room_service_tray():
    """A room-service tray left on the floor: a covered plate, a glass and a napkin."""
    shape = Shape()
    shape.box((-0.25, 0, -0.18), (0.25, 0.02, 0.18), "steel", "+y +x -x +z -z")
    shape.prism((-0.08, 0), 0.02, 0.03, 0.12, 0.12, 10, "enamel", caps="top")
    shape.prism((-0.08, 0), 0.03, 0.12, 0.11, 0.05, 10, "steel", caps="top")
    shape.prism((-0.08, 0), 0.12, 0.14, 0.012, 0.012, 6, "steel", caps="top")
    shape.prism((0.14, 0.06), 0.02, 0.13, 0.03, 0.035, 8, "opal_glass", caps="top")
    shape.box((0.07, 0.02, -0.14), (0.21, 0.03, -0.03), "linen", "+y +x -x +z -z")
    shape.build("Mesh")


def key_cabinet():
    """The housekeeping key cabinet, 1.2 m square and 0.35 m deep, with a combination
    lock on its door; hung on a wall."""
    shape = Shape()
    shape.box((-0.6, 0, 0), (0.6, 1.2, 0.33), "cabinet_green", "+x -x +y -y +z")
    shape.box((-0.004, 0.02, 0.33), (0.004, 1.18, 0.331), "dark_steel", "+z")
    shape.box((0.38, 0.5, 0.33), (0.52, 0.72, 0.35), "steel", "+z +x -x +y -y")
    for x in (0.4, 0.445, 0.49):
        shape.rod((x, 0.65, 0.35), (x, 0.65, 0.365), 0.016, 8, "brass", caps="end")
    shape.box((0.42, 0.53, 0.35), (0.48, 0.56, 0.37), "dark_steel", "+z +y -y")
    shape.build("Mesh")
    collider("Collision", (-0.6, 0, 0), (0.6, 1.2, 0.37))


def key_board():
    """The board of room keys behind the reception desk, 1.6 x 0.8 m: two rows of
    brass hooks, some keys missing; hung on a wall."""
    shape = Shape()
    shape.box((-0.8, 0, 0), (0.8, 0.8, 0.03), "door", "+z +x -x +y -y")
    missing = {(0, 2), (1, 5)}
    for row, y in enumerate((0.45, 0.08)):
        for i in range(7):
            x = -0.6 + i * 0.2
            hook = ((x - 0.006, y + 0.2, 0.03), (x + 0.006, y + 0.21, 0.07))
            shape.box(*hook, "brass", "+y -y +x -x +z")
            if (row, i) not in missing:
                key = ((x - 0.006, y + 0.13, 0.05), (x + 0.006, y + 0.2, 0.056))
                shape.box(*key, "brass", "+z +x -x")
                tag = ((x - 0.025, y + 0.02, 0.045), (x + 0.025, y + 0.13, 0.055))
                shape.box(*tag, "card", "+z +x -x -y")
    shape.build("Mesh")


def linen_cart():
    """A housekeeping trolley 1 m high: a steel frame, a canvas bag and clean linen on top."""
    shape = Shape()
    for x in (-0.45, 0.42):
        for z in (-0.25, 0.22):
            shape.box((x, 0.1, z), (x + 0.03, 1.0, z + 0.03), "steel", "+x -x +z -z")
            shape.box((x, 0, z), (x + 0.03, 0.1, z + 0.03), "dark_steel", "+x -x +z -z")
    shape.box((-0.47, 0.1, -0.27), (0.47, 0.15, 0.27), "steel")
    shape.box((-0.43, 0.15, -0.23), (0.43, 0.9, 0.23), "canvas", "+x -x +z -z")
    shape.box((-0.45, 0.9, -0.25), (0.45, 1.0, 0.25), "linen", "+y +x -x +z -z")
    shape.build("Mesh")
    collider("Collision", (-0.47, 0, -0.27), (0.47, 1.0, 0.27))


def scaffolding():
    """One bay of builders' scaffolding, 2.5 m long (X) and 0.8 m deep, decked at 2.4 m."""
    shape = Shape()
    tube = 0.025
    for x in (-1.2, 1.2):
        for z in (-0.35, 0.35):
            shape.rod((x, 0, z), (x, 2.6, z), tube, 6, "galvanised")
        for y in (1.2, 2.4):
            shape.rod((x, y, -0.4), (x, y, 0.4), tube, 6, "galvanised")
    for y in (1.2, 2.4):
        for z in (-0.35, 0.35):
            shape.rod((-1.25, y, z), (1.25, y, z), tube, 6, "galvanised")
    shape.rod((-1.2, 0.1, 0.35), (1.2, 2.4, 0.35), tube, 6, "galvanised")
    for z in (-0.36, -0.12, 0.12):
        shape.box((-1.25, 2.43, z), (1.25, 2.47, z + 0.23), "raw_wood", "+y -y +z -z")
    shape.box((-1.25, 2.47, 0.33), (1.25, 2.62, 0.36), "raw_wood", "+z -z +y")
    shape.build("Mesh")
    collider("Collision", (-1.25, 0, -0.4), (1.25, 2.62, 0.4))


def rubble_chute():
    """One 1 m segment of a builders' rubble chute, a yellow cone that hooks into the next."""
    shape = Shape()
    shape.prism((0, 0), 0.0, 1.0, 0.3, 0.38, 10, "chute_yellow", inside=True)
    shape.prism((0, 0), 0.88, 1.0, 0.41, 0.41, 10, "chute_yellow", caps="bottom")
    for a in (0, math.pi):
        x, z = 0.41 * math.cos(a), 0.41 * math.sin(a)
        shape.rod((x, 1.0, z), (x * 0.9, 1.35, z * 0.9), 0.008, 4, "dark_steel")
    shape.build("Mesh")
    collider("Collision", (-0.41, 0, -0.41), (0.41, 1.0, 0.41))


def skip():
    """A builders' skip full of rubble and dust sheets, 3 m long (X), 2 m wide, 1.2 m high."""
    shape = Shape()
    shape.extrude([(-0.8, 0.0), (0.8, 0.0), (1.0, 1.2), (-1.0, 1.2)], 1.5, "skip_paint")
    shape.box((-1.45, 1.2, -0.95), (1.45, 1.22, 0.95), "rubble", "+y")
    shape.box((-0.9, 1.2, -0.5), (0.3, 1.42, 0.4), "rubble", "+y +x -x +z -z")
    shape.box((0.2, 1.2, -0.75), (1.15, 1.34, 0.15), "rubble", "+y +x -x +z -z")
    shape.box((-1.25, 1.2, 0.15), (-0.35, 1.3, 0.8), "linen", "+y +x -x +z -z")
    for x in (-1.0, 1.0):
        shape.box((x - 0.06, 0.3, -1.02), (x + 0.06, 1.1, 1.02), "skip_paint", "+x -x +z -z")
    shape.build("Mesh")
    collider("Collision", (-1.5, 0, -1.0), (1.5, 1.42, 1.0))


def sunbed_stack():
    """The beach concession's folding sunbeds stacked on end, three deep, with two closed
    umbrellas: 2 m wide and 0.75 m deep."""
    shape = Shape()
    canvases = ("canvas_blue", "canvas_orange")
    for i, x in enumerate((-0.66, 0.0, 0.66)):
        for j, z in enumerate((-0.25, 0.0, 0.25)):
            lean = 0.08 * (j - 1)
            for side in (-1, 1):
                foot = (x + side * 0.3, 0.0, z)
                shape.rod(foot, (x + side * 0.3, 1.9, z + lean), 0.015, 5, "white_paint")
            canvas = canvases[(i + j) % 2]
            quad = [(x - 0.28, 0.12, z), (x + 0.28, 0.12, z), (x + 0.28, 1.8, z + lean),
                    (x - 0.28, 1.8, z + lean)]
            shape.face(quad, (0, 0, 1), canvas)
            shape.face(quad, (0, 0, -1), canvas)
    for x in (0.95, -0.95):
        shape.rod((x, 0.0, 0.3), (x * 0.97, 2.1, 0.32), 0.02, 5, "white_paint")
        shape.prism((x, 0.31), 1.1, 1.6, 0.02, 0.08, 6, "canvas_orange")
        shape.prism((x, 0.31), 1.6, 2.05, 0.08, 0.02, 6, "canvas_orange")
    shape.build("Mesh")
    collider("Collision", (-1.0, 0, -0.375), (1.0, 2.0, 0.375))


def kitchen_counter():
    """A 2 m run of kitchen cupboards under a steel top, 0.65 m deep and 0.9 m high."""
    shape = Shape()
    shape.box((-1.0, 0, 0), (1.0, 0.1, 0.55), "dark_steel", "+z")
    shape.box((-1.0, 0.1, 0), (1.0, 0.86, 0.6), "enamel", "+z +x -x")
    for i in range(4):
        x0 = -0.98 + i * 0.49
        shape.box((x0, 0.14, 0.6), (x0 + 0.47, 0.82, 0.62), "door", "+z +x -x +y -y")
        shape.box((x0 + 0.2, 0.74, 0.62), (x0 + 0.27, 0.76, 0.64), "brass", "+z +y -y")
    shape.box((-1.0, 0.86, 0), (1.0, 0.9, 0.65), "steel", "+y -y +z +x -x")
    shape.build("Mesh")
    collider("Collision", (-1.0, 0, 0), (1.0, 0.9, 0.65))


def stove():
    """A restaurant range, 1.2 m wide and 0.9 m deep, with a pot left on it."""
    shape = Shape()
    shape.box((-0.6, 0, -0.45), (0.6, 0.86, 0.45), "steel", "+x -x +z -z")
    shape.box((-0.6, 0.86, -0.45), (0.6, 0.88, 0.45), "dark_steel", "+y +x -x +z -z")
    for x in (-0.3, 0.3):
        for z in (-0.2, 0.2):
            shape.prism((x, z), 0.88, 0.9, 0.12, 0.12, 8, "dark_steel", caps="top")
    shape.box((-0.5, 0.15, 0.45), (0.5, 0.65, 0.46), "dark_steel", "+z")
    shape.rod((-0.4, 0.72, 0.5), (0.4, 0.72, 0.5), 0.015, 6, "steel")
    shape.prism((0.3, 0.2), 0.9, 1.1, 0.13, 0.13, 10, "steel", caps="top")
    shape.build("Mesh")
    collider("Collision", (-0.6, 0, -0.45), (0.6, 0.9, 0.5))


def hotplate():
    """A two-ring electric hotplate, for a counter."""
    shape = Shape()
    shape.box((-0.25, 0, -0.18), (0.25, 0.06, 0.18), "enamel", "+y +x -x +z -z")
    for x in (-0.12, 0.12):
        shape.prism((x, 0), 0.06, 0.07, 0.09, 0.09, 8, "dark_steel", caps="top")
    shape.build("Mesh")


def radio():
    """A radiogram: a cabinet radio on short legs, 0.9 m high, with a cloth grille and a dial."""
    shape = Shape()
    for x in (-0.28, 0.24):
        for z in (-0.16, 0.12):
            shape.box((x, 0, z), (x + 0.04, 0.15, z + 0.04), "door", "+x -x +z -z")
    shape.box((-0.32, 0.15, -0.2), (0.32, 0.9, 0.2), "door")
    shape.box((-0.25, 0.3, 0.2), (0.25, 0.62, 0.21), "fabric", "+z")
    shape.box((-0.22, 0.7, 0.2), (0.12, 0.8, 0.21), "enamel", "+z")
    for x in (0.17, 0.25):
        shape.rod((x, 0.75, 0.2), (x, 0.75, 0.23), 0.025, 8, "brass", caps="end")
    shape.build("Mesh")
    collider("Collision", (-0.32, 0, -0.2), (0.32, 0.9, 0.23))


def washing_machine():
    """An industrial front-loading washing machine, 0.7 m square and 0.9 m high."""
    shape = Shape()
    shape.box((-0.35, 0, -0.35), (0.35, 0.9, 0.35), "enamel", "+x -x +y +z -z")
    shape.rod((0, 0.42, 0.35), (0, 0.42, 0.38), 0.18, 12, "steel")
    shape.rod((0, 0.42, 0.35), (0, 0.42, 0.37), 0.14, 12, "dusk_glass", caps="end")
    shape.box((-0.33, 0.76, 0.35), (0.33, 0.87, 0.37), "steel", "+z +y")
    shape.build("Mesh")
    collider("Collision", (-0.35, 0, -0.35), (0.35, 0.9, 0.38))


def hanging_sheet():
    """A bed sheet pegged on a washing line, 1.6 m wide and 1.5 m long, on 2 m of line
    (X) at 2.3 m."""
    shape = Shape()
    shape.rod((-1.0, 2.32, 0), (1.0, 2.32, 0), 0.005, 4, "lettering")
    sag = [(-0.8, 2.3, 0.0), (0.0, 2.3, 0.02), (0.8, 2.3, 0.0)]
    for (x0, y0, z0), (x1, y1, z1) in zip(sag, sag[1:]):
        quad = [(x0, 0.8, z0), (x1, 0.8, z1), (x1, y1, z1), (x0, y0, z0)]
        normal = Vector((z0 - z1, 0, x1 - x0))
        shape.face(quad, normal, "linen")
        shape.face(quad, -normal, "linen")
    for x in (-0.75, 0.0, 0.75):
        shape.box((x - 0.01, 2.26, -0.01), (x + 0.01, 2.36, 0.03), "raw_wood", "+x -x +z -z")
    shape.build("Mesh")


def boiler():
    """An old boiler: a drum 1.2 m across and 2.2 m high, with a flue to the ceiling."""
    shape = Shape()
    shape.prism((0, 0), 0.0, 0.1, 0.64, 0.64, 12, "dark_steel", caps="top")
    shape.prism((0, 0), 0.1, 2.0, 0.6, 0.6, 12, "boiler_paint")
    shape.prism((0, 0), 2.0, 2.2, 0.6, 0.35, 12, "boiler_paint", caps="top")
    shape.prism((0, 0), 2.2, 3.0, 0.12, 0.12, 8, "dark_steel")
    shape.box((-0.2, 0.35, 0.55), (0.2, 0.8, 0.64), "dark_steel", "+z +x -x +y -y")
    shape.rod((0.0, 1.5, 0.58), (0.0, 1.5, 0.66), 0.08, 8, "brass", caps="end")
    shape.rod((0.6, 1.7, 0.0), (1.0, 1.7, 0.0), 0.06, 6, "dark_steel")
    shape.build("Mesh")
    collider("Collision", (-0.64, 0, -0.64), (0.64, 2.2, 0.64))


def water_tank():
    """A tall galvanised expansion tank, 0.9 m across and 1.6 m high."""
    shape = Shape()
    shape.prism((0, 0), 0.0, 1.6, 0.45, 0.45, 12, "galvanised", caps="top")
    for y in (0.4, 1.2):
        shape.prism((0, 0), y, y + 0.05, 0.47, 0.47, 12, "dark_steel")
    shape.rod((0.0, 1.6, 0.0), (0.0, 3.0, 0.0), 0.04, 6, "dark_steel")
    shape.build("Mesh")
    collider("Collision", (-0.47, 0, -0.47), (0.47, 1.6, 0.47))


def switchboard():
    """The hotel's main switchboard, 1.2 x 1.4 m: a steel cabinet with the main lever,
    fuses and two dials; hung on a wall."""
    shape = Shape()
    shape.box((-0.6, 0, 0), (0.6, 1.4, 0.15), "locker_grey", "+x -x +y -y +z")
    shape.box((0.25, 0.55, 0.15), (0.45, 0.95, 0.2), "dark_steel", "+z +x -x +y -y")
    shape.rod((0.35, 0.75, 0.2), (0.35, 0.95, 0.38), 0.02, 6, "dark_steel")
    shape.box((0.3, 0.93, 0.36), (0.4, 0.98, 0.41), "red_lettering")
    for row, y in enumerate((0.25, 0.45)):
        for i in range(5):
            x = -0.5 + i * 0.13
            shape.box((x, y, 0.15), (x + 0.07, y + 0.12, 0.19), "enamel", "+z +x -x +y -y")
    for x in (-0.38, -0.08):
        shape.rod((x, 1.05, 0.15), (x, 1.05, 0.18), 0.1, 10, "enamel", caps="end")
    shape.build("Mesh")
    collider("Collision", (-0.6, 0, 0), (0.6, 1.4, 0.2))


def ceiling_pipes():
    """Two pipes and a conduit along 2 m of ceiling (X), hanging from their origin at the
    ceiling, with a strap at the middle."""
    shape = Shape()
    shape.rod((-1.0, -0.15, 0.0), (1.0, -0.15, 0.0), 0.07, 8, "galvanised")
    shape.rod((-1.0, -0.17, 0.2), (1.0, -0.17, 0.2), 0.045, 8, "dark_steel")
    shape.rod((-1.0, -0.08, -0.15), (1.0, -0.08, -0.15), 0.02, 6, "dark_steel")
    shape.box((-0.02, -0.23, -0.18), (0.02, 0.0, 0.27), "dark_steel", "+x -x -y")
    shape.build("Mesh")


def roller_shutter():
    """A steel roller shutter, down: 2 m wide (X) and 3 m high, its box at the top."""
    shape = Shape()
    for side in (-1, 1):
        x0, x1 = sorted((side * 1.0, side * 0.92))
        shape.box((x0, 0, -0.06), (x1, 3.0, 0.06), "dark_steel", "+x -x +z -z")
    for i in range(16):
        y0, d = i * 0.16, 0.02 + 0.01 * (i % 2)
        shape.box((-0.92, y0, -d), (0.92, y0 + 0.16, d), "galvanised", "+z -z -y")
    shape.box((-1.0, 2.56, -0.2), (1.0, 3.0, 0.2), "dark_steel", "+z -z -y")
    shape.build("Mesh")
    collider("Collision", (-1.0, 0, -0.06), (1.0, 3.0, 0.06))


def wall_button():
    """A push-button box for the roller shutter, up and down; hung on a wall."""
    shape = Shape()
    shape.box((-0.06, 0, 0), (0.06, 0.2, 0.05), "locker_grey", "+x -x +y -y +z")
    shape.rod((0, 0.14, 0.05), (0, 0.14, 0.065), 0.02, 8, "green_glass", caps="end")
    shape.rod((0, 0.06, 0.05), (0, 0.06, 0.065), 0.02, 8, "red_lettering", caps="end")
    shape.build("Mesh")


def locker(state):
    """A steel staff locker, 0.5 m wide and deep and 1.9 m high. 'ajar' leaves the door
    open, hinged on the right, with the porter's coat inside."""
    shape = Shape()
    shape.box((-0.25, 0, -0.25), (0.25, 1.9, 0.23), "locker_grey", "+x -x +y")
    if state == "ajar":
        # The inside, facing in.
        x0, y0, z0, x1, y1, z1 = -0.23, 0.05, -0.23, 0.23, 1.85, 0.23
        inside = "dark_steel"
        shape.face([(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)], (0, 0, 1), inside)
        shape.face([(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)], (1, 0, 0), inside)
        shape.face([(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)], (-1, 0, 0), inside)
        shape.face([(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)], (0, -1, 0), inside)
        shape.face([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], (0, 1, 0), inside)
        for a, b in ((-0.25, -0.23), (0.23, 0.25)):
            shape.box((a, 0, 0.23), (b, 1.9, 0.25), "locker_grey", "+z")
        shape.box((-0.23, 0, 0.23), (0.23, 0.05, 0.25), "locker_grey", "+z")
        shape.box((-0.23, 1.85, 0.23), (0.23, 1.9, 0.25), "locker_grey", "+z")
        shape.rod((-0.2, 1.75, -0.05), (0.2, 1.75, -0.05), 0.01, 4, "steel")
        shape.box((-0.17, 0.75, -0.15), (0.17, 1.7, 0.03), "coat", "+x -x +z -z -y +y")
    first = len(shape.faces)
    shape.box((-0.25, 0.02, 0.23), (0.25, 1.88, 0.25), "locker_grey", "+z -z +x -x +y -y")
    for y in (1.55, 1.62, 1.69):
        shape.box((-0.15, y, 0.25), (0.15, y + 0.03, 0.255), "dark_steel", "+z +y")
    shape.box((-0.22, 0.95, 0.25), (-0.19, 1.1, 0.27), "steel", "+z +x -x +y -y")
    if state == "ajar":
        shape.turn(first, 70, (0.25, 0.25))
    shape.build("Mesh")
    collider("Collision", (-0.25, 0, -0.25), (0.25, 1.9, 0.25))


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
    "stair_wall": stair_wall,
    "railing": railing,
    "window_frame": window_frame,
    "curtain": curtain,
    "balcony_divider": balcony_divider,
    "lift_doors": lift_doors,
    "bed": bed,
    "wardrobe": wardrobe,
    "reception_desk": reception_desk,
    "desk_lamp": desk_lamp,
    "bedside_lamp": bedside_lamp,
    "ceiling_lamp": ceiling_lamp,
    "room_number": room_number,
    "sign": sign,
    "desk": desk,
    "wall_cabinet": wall_cabinet,
    "alarm_clock": alarm_clock,
    "coat_stand": coat_stand,
    "room_service_tray": room_service_tray,
    "key_cabinet": key_cabinet,
    "key_board": key_board,
    "linen_cart": linen_cart,
    "scaffolding": scaffolding,
    "rubble_chute": rubble_chute,
    "skip": skip,
    "sunbed_stack": sunbed_stack,
    "kitchen_counter": kitchen_counter,
    "stove": stove,
    "hotplate": hotplate,
    "radio": radio,
    "washing_machine": washing_machine,
    "hanging_sheet": hanging_sheet,
    "boiler": boiler,
    "water_tank": water_tank,
    "switchboard": switchboard,
    "ceiling_pipes": ceiling_pipes,
    "roller_shutter": roller_shutter,
    "wall_button": wall_button,
    "locker": locker,
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
