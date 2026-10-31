"""Fits a downloaded photo texture to docs/design/visual-style.md: one small albedo image.

Runs inside the pinned Blender (.blender-version, installed by tools/install_blender.sh):

    blender --background --factory-startup --python tools/process_texture.py -- \\
        COLOR OUTPUT.jpg --size 512 [--ao AO] [--ao-strength 1.0] [--saturation 0.8] [--levels 0.5,0.9]

COLOR is the source's colour (albedo/diffuse) map. The script:

1. downscales it so its longer side is at most --size, snapping each side
   to the nearest power of two;
2. bakes ambient occlusion into it, as PS2 games did: if --ao is given, the
   colour is multiplied by that map, blended in by --ao-strength;
3. desaturates it towards grey by --saturation (1 keeps the colour, 0 is
   grey), so materials can tint it to the palette with albedo_color;
4. with --levels LOW,HIGH, remaps its brightness range onto LOW..HIGH: a
   tint only darkens, so a dark source needs lifting before it can be
   tinted to a pastel;
5. saves it as OUTPUT (.jpg or .png).

Normal, roughness and other maps are never used: materials are albedo only.
"""

import argparse
import math
import os
import sys

import bpy
import numpy

# Rec. 709 luma weights, for desaturating.
LUMA = numpy.array([0.2126, 0.7152, 0.0722], dtype=numpy.float32)
JPEG_QUALITY = 90


def main():
    args = parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])
    color = load(args.color, args.size)
    pixels = read(color)
    if args.ao:
        ao = read(load(args.ao, args.size, color.size))
        occlusion = 1.0 - args.ao_strength * (1.0 - ao[..., :1])
        pixels[..., :3] *= occlusion
    grey = pixels[..., :3] @ LUMA
    pixels[..., :3] = grey[..., None] + args.saturation * (pixels[..., :3] - grey[..., None])
    if args.levels:
        pixels[..., :3] = remap(pixels[..., :3], pixels[..., :3] @ LUMA, *args.levels)
    write(color, numpy.clip(pixels, 0.0, 1.0), args.output)
    print(f"process_texture: {args.color} -> {args.output}: {color.size[0]}x{color.size[1]}")


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="process_texture.py", description=__doc__.split("\n")[0])
    parser.add_argument("color", help="colour map to process")
    parser.add_argument("output", help="image to write (.jpg or .png)")
    parser.add_argument("--size", type=int, required=True, help="maximum side, px")
    parser.add_argument("--ao", help="ambient occlusion map to bake in")
    parser.add_argument("--ao-strength", type=float, default=1.0, help="0 to 1")
    parser.add_argument("--saturation", type=float, default=1.0, help="0 (grey) to 1")
    parser.add_argument("--levels", type=levels, help="LOW,HIGH: brightness range to remap to")
    args = parser.parse_args(argv)
    if os.path.splitext(args.output)[1].lower() not in (".jpg", ".png"):
        parser.error("OUTPUT must be a .jpg or .png file")
    return args


def levels(text):
    low, high = (float(value) for value in text.split(","))
    if not 0.0 <= low < high <= 1.0:
        raise argparse.ArgumentTypeError("levels must be LOW,HIGH with 0 <= LOW < HIGH <= 1")
    return low, high


def remap(rgb, grey, low, high):
    # Stretch the image's own range (ignoring the darkest and brightest 1%)
    # onto LOW..HIGH, so a dark pattern becomes a light base a tint can colour.
    darkest, brightest = numpy.percentile(grey, [1, 99])
    scale = (high - low) / max(brightest - darkest, 1e-6)
    return low + (rgb - darkest) * scale


def load(path, size, exact=None):
    image = bpy.data.images.load(os.path.abspath(path))
    # Keep the stored values: the colour map is sRGB and the occlusion map
    # is data, and both are processed as they are.
    image.colorspace_settings.name = "Non-Color"
    width, height = image.size
    if exact is None:
        factor = min(1.0, size / max(width, height))
        exact = (power_of_two(width * factor), power_of_two(height * factor))
    if tuple(image.size) != tuple(exact):
        image.scale(exact[0], exact[1])
    return image


def power_of_two(length):
    # GPU texture compression and mipmaps want power-of-two sides, so a
    # non-square source is squashed slightly to the nearest one.
    return 2 ** max(0, round(math.log2(length)))


def read(image):
    pixels = numpy.empty(image.size[0] * image.size[1] * 4, dtype=numpy.float32)
    image.pixels.foreach_get(pixels)
    return pixels.reshape(image.size[1], image.size[0], 4)


def write(image, pixels, path):
    image.pixels.foreach_set(pixels.ravel())
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    scene = bpy.context.scene
    settings = scene.render.image_settings
    settings.file_format = "JPEG" if path.lower().endswith(".jpg") else "PNG"
    settings.color_mode = "RGB"
    settings.quality = JPEG_QUALITY
    image.save_render(os.path.abspath(path), scene=scene)


if __name__ == "__main__":
    main()
