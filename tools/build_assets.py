#!/usr/bin/env python3
"""Downloads the CC0 sources listed in assets/sources.json and fits them to budget.

Only the processed results are committed. The raw downloads go in
.asset_cache/ (gitignored, and hidden from Godot), so anyone can rebuild an
asset from its manifest entry. From the project root:

    tools/build_assets.py                     # every model and texture
    tools/build_assets.py painted_chair terrazzo  # just these

BLENDER sets the Blender binary (default: blender); install the pinned one
with tools/install_blender.sh. Each entry's "process" settings become the
options of its Blender script:

- a model is written to assets/models/<category>/<name>/<name>.gltf by
  tools/process_model.py;
- a texture is written to assets/textures/<name>.jpg by
  tools/process_texture.py, with the source's ambient occlusion map baked
  in when it has one.

Each new texture gets an .import file that makes Godot compress it for the
GPU (VRAM) with mipmaps. Then run Godot's import (godot --headless --import)
and commit the new files with their .import files.

A model entry in assets/sources.json looks like:

    {
      "name": "painted_chair",
      "category": "props",
      "source": "https://polyhaven.com/a/painted_wooden_chair_01",
      "author": "Kuutti Siitonen",
      "license": "CC0",
      "fetch": {"polyhaven": "painted_wooden_chair_01"},
      "process": {"triangles": 450, "texture_size": 256}
    }

and a texture entry, under "textures", the same without "category":

    {
      "name": "terrazzo",
      "source": "https://ambientcg.com/a/Terrazzo011",
      "author": "ambientCG",
      "license": "CC0",
      "fetch": {"ambientcg": "Terrazzo011"},
      "process": {"size": 512, "saturation": 0.8}
    }

"fetch" says how to get the raw files:

- {"polyhaven": ID} downloads the 1k glTF of a Poly Haven model, or the 1k
  colour and occlusion maps of a Poly Haven texture;
- {"ambientcg": ID} downloads the 1K JPG set of an ambientCG material
  (textures only);
- {"url": URL, "file": PATH} downloads URL (unpacking it if it is a .zip)
  and processes PATH inside it (models only);
- {"file": PATH} is for sources that can't be downloaded by script (such
  as Google Drive folders): download them by hand from "source" into
  .asset_cache/<name>/ and the build processes PATH there (models only).
"""

import json
import os
import shutil
import subprocess
import sys
import urllib.request
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "assets", "sources.json")
CACHE = os.path.join(ROOT, ".asset_cache")
MODELS = os.path.join(ROOT, "assets", "models")
TEXTURES = os.path.join(ROOT, "assets", "textures")
AMBIENTCG_ZIP = "https://ambientcg.com/get?file={id}_1K-JPG.zip"
POLYHAVEN_API = "https://api.polyhaven.com/files/"
USER_AGENT = "horror-game-asset-pipeline"
TEXTURE_EXTENSIONS = (".png", ".jpg", ".jpeg")
# Godot keeps the params of an existing .import file and fills in the rest.
TEXTURE_IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=2
mipmaps/generate=true
"""


def main():
    with open(MANIFEST, encoding="utf-8") as file:
        manifest = json.load(file)
    models = manifest.get("models", [])
    textures = manifest.get("textures", [])
    names = sys.argv[1:]
    unknown = set(names) - {entry["name"] for entry in models + textures}
    if unknown:
        sys.exit(f"build_assets: not in {MANIFEST}: {', '.join(sorted(unknown))}")
    for model in models:
        if not names or model["name"] in names:
            build_model(model)
    for texture in textures:
        if not names or texture["name"] in names:
            build_texture(texture)


def build_model(model):
    name = model["name"]
    source = fetch_model(name, model["fetch"])
    out_dir = os.path.join(MODELS, model["category"], name)
    clean(out_dir)
    blender(name, "process_model.py", [source, os.path.join(out_dir, name + ".gltf")], model)
    drop_stale_imports(out_dir)
    seed_texture_imports(out_dir)


def build_texture(texture):
    name = texture["name"]
    color, ao = fetch_texture(name, texture["fetch"])
    arguments = [color, os.path.join(TEXTURES, name + ".jpg")]
    if ao:
        arguments += ["--ao", ao]
    blender(name, "process_texture.py", arguments, texture)
    seed_texture_imports(TEXTURES)


def blender(name, script, arguments, entry):
    command = [os.environ.get("BLENDER", "blender"), "--background", "--factory-startup"]
    command += ["--python", os.path.join(ROOT, "tools", script), "--"] + arguments
    for key, value in entry["process"].items():
        command += ["--" + key.replace("_", "-"), str(value)]
    print(f"build_assets: {name}", flush=True)
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    prefix = script.removesuffix(".py") + ":"
    for line in result.stdout.splitlines():
        if line.startswith(prefix):
            print(line)
    if result.returncode != 0:
        sys.exit(f"build_assets: Blender failed on {name}:\n{result.stdout}{result.stderr}")


def fetch_model(name, fetch_spec):
    cache = os.path.join(CACHE, name)
    if "polyhaven" in fetch_spec:
        return fetch_polyhaven_model(cache, fetch_spec["polyhaven"])
    path = os.path.join(cache, fetch_spec["file"])
    if os.path.exists(path):
        return path
    if "url" not in fetch_spec:
        sys.exit(f"build_assets: download {name} by hand into {cache}/ (missing {path})")
    os.makedirs(cache, exist_ok=True)
    archive = os.path.join(cache, os.path.basename(fetch_spec["url"].split("?")[0]))
    download(fetch_spec["url"], archive)
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as zip_file:
            zip_file.extractall(cache)
    if not os.path.exists(path):
        sys.exit(f"build_assets: {fetch_spec['file']} not found in {fetch_spec['url']}")
    return path


def fetch_polyhaven_model(cache, asset_id):
    gltf = polyhaven_files(asset_id)["gltf"]["1k"]["gltf"]
    path = os.path.join(cache, os.path.basename(gltf["url"]))
    files = [(path, gltf["url"])]
    files += [(os.path.join(cache, p), f["url"]) for p, f in gltf["include"].items()]
    for target, url in files:
        if not os.path.exists(target):
            download(url, target)
    return path


def fetch_texture(name, fetch_spec):
    """Returns the paths of the colour map and of the occlusion map, or None."""
    cache = os.path.join(CACHE, name)
    if "ambientcg" in fetch_spec:
        asset_id = fetch_spec["ambientcg"]
        color = os.path.join(cache, f"{asset_id}_1K-JPG_Color.jpg")
        if not os.path.exists(color):
            archive = os.path.join(cache, f"{asset_id}_1K-JPG.zip")
            download(AMBIENTCG_ZIP.format(id=asset_id), archive)
            with zipfile.ZipFile(archive) as zip_file:
                zip_file.extractall(cache)
        ao = os.path.join(cache, f"{asset_id}_1K-JPG_AmbientOcclusion.jpg")
        return color, ao if os.path.exists(ao) else None
    if "polyhaven" in fetch_spec:
        files = polyhaven_files(fetch_spec["polyhaven"])
        maps = []
        for key in ("Diffuse", "AO"):
            if key not in files:
                maps.append(None)
                continue
            url = files[key]["1k"]["jpg"]["url"]
            path = os.path.join(cache, os.path.basename(url))
            if not os.path.exists(path):
                download(url, path)
            maps.append(path)
        return maps[0], maps[1]
    sys.exit(f"build_assets: texture {name} needs an ambientcg or polyhaven fetch")


def polyhaven_files(asset_id):
    with urllib.request.urlopen(request(POLYHAVEN_API + asset_id)) as response:
        return json.load(response)


def download(url, target):
    print(f"build_assets: downloading {url}", flush=True)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with urllib.request.urlopen(request(url)) as response, open(target, "wb") as file:
        shutil.copyfileobj(response, file)


def request(url):
    return urllib.request.Request(url, headers={"User-Agent": USER_AGENT})


def clean(out_dir):
    # Keep the .import files: they hold the uids that scenes reference.
    if not os.path.isdir(out_dir):
        return
    for entry in os.listdir(out_dir):
        if not entry.endswith(".import"):
            os.remove(os.path.join(out_dir, entry))


def drop_stale_imports(out_dir):
    for entry in os.listdir(out_dir):
        if entry.endswith(".import") and not os.path.exists(os.path.join(out_dir, entry[:-7])):
            os.remove(os.path.join(out_dir, entry))


def seed_texture_imports(out_dir):
    for entry in os.listdir(out_dir):
        path = os.path.join(out_dir, entry + ".import")
        if entry.lower().endswith(TEXTURE_EXTENSIONS) and not os.path.exists(path):
            with open(path, "w", encoding="utf-8") as file:
                file.write(TEXTURE_IMPORT)


if __name__ == "__main__":
    main()
