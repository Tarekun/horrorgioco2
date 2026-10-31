"""Fits a downloaded model to the budgets in docs/design/visual-style.md and exports it as glTF.

Runs inside the pinned Blender (.blender-version, installed by tools/install_blender.sh):

    blender --background --factory-startup --python tools/process_model.py -- \\
        INPUT OUTPUT.gltf --triangles 400 --texture-size 256 [options]

INPUT is a .gltf, .glb, .fbx, .obj or .blend file. The script:

1. imports it into an empty scene;
2. fixes orientation and scale: --rotate turns it about the up axis (Godot
   characters face -Z, most CC0 characters face +Z, so pass 180 for them),
   --height scales it to that many metres tall, --scale multiplies it, and
   --origin bottom (the default) puts the bottom centre of its bounds at
   the origin;
3. decimates every mesh by the same ratio until the model is within
   --triangles (models already under it are left alone);
4. strips materials to albedo: the base colour (texture or flat colour),
   alpha and emission stay; normal, roughness, metallic, occlusion and every
   other map are dropped, and roughness and metallic become constants
   (--roughness, --metallic);
5. downscales every remaining texture so its longer side is at most
   --texture-size;
6. with --collision box, adds its bounding box as a convex collider (an
   object named *-convcolonly, which Godot doesn't draw), so that furniture
   blocks the player;
7. exports glTF (separate .gltf, .bin and textures named after it) with
   its animations; --actions keeps only the named ones, and --drop deletes
   the named objects first (a source's helper shapes).

The triangle count after decimation is printed; tests/assets/test_model_budgets.gd
checks the exported models against the budgets of their folder.
"""

import argparse
import math
import os
import sys

import bpy
import mathutils

IMPORTERS = {
    ".gltf": lambda path: bpy.ops.import_scene.gltf(filepath=path),
    ".glb": lambda path: bpy.ops.import_scene.gltf(filepath=path),
    ".fbx": lambda path: bpy.ops.import_scene.fbx(filepath=path),
    ".obj": lambda path: bpy.ops.wm.obj_import(filepath=path),
}
# Principled BSDF inputs kept when stripping a material to albedo.
KEPT_INPUTS = {"Base Color", "Alpha", "Emission Color", "Emission Strength"}
# Faces meeting at less than this angle, in degrees, count as flat and are
# merged before the budget decimation.
PLANAR_ANGLE = 5.0


def main():
    args = parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])
    load(args.input)
    drop_objects(args.drop)
    keep_actions(args.actions)
    transform(args.rotate, args.height, args.scale, args.origin)
    before = count_triangles()
    decimate(args.triangles)
    after = count_triangles()
    strip_materials(args.roughness, args.metallic)
    downscale_textures(args.texture_size)
    if args.collision == "box":
        add_box_collider("Collision")
    export(args.output)
    print(f"process_model: {args.input} -> {args.output}: {before} -> {after} triangles")


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="process_model.py", description=__doc__.split("\n")[0])
    parser.add_argument("input", help="model to process (.gltf, .glb, .fbx, .obj or .blend)")
    parser.add_argument("output", help="glTF file to write (.gltf)")
    parser.add_argument("--triangles", type=int, required=True, help="maximum triangle count")
    parser.add_argument("--texture-size", type=int, required=True, help="maximum texture side, px")
    parser.add_argument("--rotate", type=float, default=0.0, help="turn about the up axis, degrees")
    parser.add_argument("--height", type=float, help="scale uniformly to this height, metres")
    parser.add_argument("--scale", type=float, default=1.0, help="extra uniform scale factor")
    parser.add_argument(
        "--origin", choices=["bottom", "keep"], default="bottom", help="where to put the origin"
    )
    parser.add_argument("--drop", default="", help="comma-separated objects to delete")
    parser.add_argument("--actions", default="", help="comma-separated animations to keep")
    parser.add_argument("--roughness", type=float, default=0.8, help="constant roughness")
    parser.add_argument("--metallic", type=float, default=0.0, help="constant metallic")
    parser.add_argument(
        "--collision", choices=["none", "box"], default="none", help="collider to add"
    )
    args = parser.parse_args(argv)
    if not args.output.endswith(".gltf"):
        parser.error("OUTPUT must be a .gltf file")
    return args


def load(path):
    extension = os.path.splitext(path)[1].lower()
    if extension == ".blend":
        bpy.ops.wm.open_mainfile(filepath=path)
        return
    if extension not in IMPORTERS:
        sys.exit(f"process_model: unsupported format {extension}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    IMPORTERS[extension](os.path.abspath(path))


def drop_objects(names):
    for name in filter(None, names.split(",")):
        obj = bpy.data.objects.get(name)
        if obj is None:
            sys.exit(f"process_model: no object named {name} to drop")
        bpy.data.objects.remove(obj)


def keep_actions(names):
    wanted = set(filter(None, names.split(",")))
    if not wanted:
        return
    missing = wanted - {a.name for a in bpy.data.actions}
    if missing:
        sys.exit(f"process_model: no animation named {', '.join(sorted(missing))}")
    for action in list(bpy.data.actions):
        if action.name not in wanted:
            bpy.data.actions.remove(action)
    for obj in bpy.data.objects:
        if obj.animation_data:
            obj.animation_data.action = None
            for track in list(obj.animation_data.nla_tracks):
                if not any(strip.action and strip.action.name in wanted for strip in track.strips):
                    obj.animation_data.nla_tracks.remove(track)


def transform(rotate, height, scale, origin):
    roots = [o for o in bpy.context.scene.objects if o.parent is None]
    bpy.context.view_layer.update()
    low, high = bounds()
    factor = scale
    if height is not None:
        if high.z - low.z <= 0.0:
            sys.exit("process_model: the model has no height to scale")
        factor *= height / (high.z - low.z)
    # Blender is Z-up; the glTF exporter converts to Godot's Y-up.
    matrix = mathutils.Matrix.Rotation(math.radians(rotate), 4, "Z") @ mathutils.Matrix.Scale(
        factor, 4
    )
    if origin == "bottom":
        centre = mathutils.Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
        matrix = matrix @ mathutils.Matrix.Translation(-centre)
    for obj in roots:
        obj.matrix_world = matrix @ obj.matrix_world
    bpy.context.view_layer.update()


def bounds():
    meshes = mesh_objects()
    if not meshes:
        sys.exit("process_model: the input has no meshes")
    corners = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    low = mathutils.Vector([min(c[i] for c in corners) for i in range(3)])
    high = mathutils.Vector([max(c[i] for c in corners) for i in range(3)])
    return low, high


def mesh_objects():
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def count_triangles():
    total = 0
    for obj in mesh_objects():
        mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
        obj.to_mesh_clear()
    return total


def decimate(target):
    if count_triangles() <= target:
        return
    # Merging flat areas first costs no shape, leaving collapse fewer
    # triangles to remove from the silhouette.
    for obj in mesh_objects():
        modifier = obj.modifiers.new("Planar", "DECIMATE")
        modifier.decimate_type = "DISSOLVE"
        modifier.angle_limit = math.radians(PLANAR_ANGLE)
        apply_modifier(obj, "Planar")
    # Collapse decimation lands near, not exactly on, the requested ratio, so
    # tighten it until the model fits.
    ratio = 1.0
    for _ in range(8):
        current = count_triangles()
        if current <= target:
            break
        ratio *= target / current * 0.98
        for obj in mesh_objects():
            modifier = obj.modifiers.get("Budget") or obj.modifiers.new("Budget", "DECIMATE")
            modifier.decimate_type = "COLLAPSE"
            modifier.ratio = ratio
            modifier.use_collapse_triangulate = True
        bpy.context.view_layer.update()
    if count_triangles() > target:
        sys.exit(f"process_model: could not decimate below {target} triangles")
    for obj in mesh_objects():
        if "Budget" in obj.modifiers:
            apply_modifier(obj, "Budget")


def apply_modifier(obj, name):
    if obj.data.shape_keys:
        print(f"process_model: dropping shape keys of {obj.name} to decimate it")
        obj.shape_key_clear()
    with bpy.context.temp_override(object=obj):
        bpy.ops.object.modifier_apply(modifier=name)


def strip_materials(roughness, metallic):
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        tree = material.node_tree
        output = tree.get_output_node("ALL")
        shader = principled(output)
        if shader is None:
            print(f"process_model: {material.name} has no Principled BSDF, left as is")
            continue
        for socket in shader.inputs:
            if socket.name not in KEPT_INPUTS:
                for link in list(socket.links):
                    tree.links.remove(link)
        shader.inputs["Roughness"].default_value = roughness
        shader.inputs["Metallic"].default_value = metallic
        # Drop everything the stripped shader no longer reads, such as normal
        # map nodes and the importer's occlusion group.
        keep = upstream(output)
        for node in list(tree.nodes):
            if node not in keep:
                tree.nodes.remove(node)
    for image in list(bpy.data.images):
        if image.users == 0:
            bpy.data.images.remove(image)


def principled(output):
    if output is None or not output.inputs["Surface"].links:
        return None
    node = output.inputs["Surface"].links[0].from_node
    return node if node.type == "BSDF_PRINCIPLED" else None


def upstream(node):
    seen = {node}
    stack = [node]
    while stack:
        for socket in stack.pop().inputs:
            for link in socket.links:
                if link.from_node not in seen:
                    seen.add(link.from_node)
                    stack.append(link.from_node)
    return seen


def add_box_collider(name):
    low, high = bounds()
    mesh = bpy.data.meshes.new(name + "-convcolonly")
    corners = [(x, y, z) for x in (low.x, high.x) for y in (low.y, high.y) for z in (low.z, high.z)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    mesh.from_pydata(corners, [], faces)
    bpy.context.scene.collection.objects.link(bpy.data.objects.new(mesh.name, mesh))


def downscale_textures(size):
    for image in bpy.data.images:
        width, height = image.size
        if max(width, height) <= size:
            continue
        factor = size / max(width, height)
        image.scale(max(1, round(width * factor)), max(1, round(height * factor)))


def export(path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    # Name the textures after the model rather than after the source's files.
    stem = os.path.splitext(os.path.basename(path))[0]
    images = sorted(bpy.data.images, key=lambda i: i.name)
    for index, image in enumerate(images):
        # The exporter names images after their file path; packing first
        # keeps the downscaled pixels when the path changes.
        image.pack()
        name = stem if len(images) == 1 else f"{stem}_{index + 1}"
        image.filepath_raw = f"//{name}{os.path.splitext(image.filepath_raw)[1] or '.png'}"
    bpy.ops.export_scene.gltf(
        filepath=os.path.abspath(path),
        export_format="GLTF_SEPARATE",
        export_yup=True,
        export_apply=True,
        export_animations=True,
        export_extras=False,
        export_cameras=False,
        export_lights=False,
    )


if __name__ == "__main__":
    main()
