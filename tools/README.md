# tools/

Development tooling, not shipped with the game.

- `check.sh` – runs every check and test an agent must pass before committing (see `AGENTS.md`).
- `install_godot.sh` – downloads the pinned Godot editor (Linux x86_64 or arm64), verifies its checksum and prints its path; used by CI.
- `install_blender.sh` – downloads the pinned Blender (version in `.blender-version`, Linux x86_64), verifies its checksum and prints its path; for the asset pipeline below.
- `check_scripts.gd` – loads every script and scene headless and exits non-zero on any load error; called by `check.sh`.
- `bake_navmesh.gd` – bakes a level's navmesh from its collision geometry, with the doors shut: `godot --headless --path . -s res://tools/bake_navmesh.gd -- hotel_miramare`.
- `generate_hotel_graybox.py` – writes `scenes/levels/hotel_miramare.tscn` from the layout in `docs/design/slice.md`. It overwrites the whole scene, and the scene has been populated by hand since #71, so it is kept as the record of how the layout was built rather than run; its docstring has the steps, including the navmesh rebake.
- `generate_character_models.gd` – writes the player's and the standard enemy's animated scenes (`scenes/player/player_model.tscn`, `scenes/enemies/enemy_model.tscn`) and their clip libraries in `assets/data/` from the rigged models in `assets/models/characters/` and `assets/models/monsters/`. It maps the source's clips to the states the game plays, adds the player's footstep calls and builds each `AnimationTree`: `godot --headless --path . --script res://tools/generate_character_models.gd`.
- `build_assets.py`, `process_model.py` and `process_texture.py` – the asset pipeline, below.

## Asset pipeline

Downloaded CC0 models and textures are fitted to the budgets in `docs/design/visual-style.md` by headless Blender scripts, and the hotel kit and simple props are made by one. It runs locally, never in CI; only its output is committed.

Blender is pinned to **4.5 LTS** in `.blender-version`. Install it and point `BLENDER` at it:

```sh
export BLENDER="$(tools/install_blender.sh)"
```

To add a model or texture:

1. Add an entry to `assets/sources.json` (under `models` or `textures`) with its name, category (models only), source page, author, license (CC0 only), how to fetch it and its `process` options. A model made by `make_kit.py` has `make` instead, with its variants. The `build_assets.py` docstring describes the format.
2. Run `tools/build_assets.py <name>`. It downloads the raw files into `.asset_cache/` (gitignored), runs `process_model.py`, `make_kit.py` or `process_texture.py` in Blender and writes `assets/models/<category>/<name>/` or `assets/textures/<name>.jpg`. Without names it rebuilds everything.
3. Run `godot --headless --path . --import`, look at the model in the editor (or in `scenes/levels/kit_showcase.tscn`), and add a row to the models or textures table in `assets/README.md`. A new texture also gets a material in `assets/materials/`.
4. Run `tools/check.sh`: `tests/assets/test_model_budgets.gd` checks every model against its category's budgets, its source and its shared materials, and `tests/assets/test_textures.gd` the textures and materials.

Commit each model with its `.import` file and, for static models, the `.unwrap_cache` Godot writes beside it: it holds the lightmap UVs, so every machine bakes lightmaps onto the same ones.

`process_model.py` also runs on its own, for trying out settings on any file:

```sh
"$BLENDER" --background --factory-startup --python tools/process_model.py -- \
    INPUT.glb OUTPUT.gltf --triangles 450 --texture-size 256 [--rotate 180] [--height 1.8] [--drop OBJECT,...] [--actions CLIP,...]
```

It imports glTF, FBX, OBJ or `.blend`; turns and scales the model and puts its origin at the bottom centre; decimates it to `--triangles` (first merging flat areas, then collapsing edges); keeps only the base colour, alpha and emission of each material, with constant roughness and metallic; downscales textures to `--texture-size`; and exports glTF with separate textures and its animations. `--help` lists every option.

- **Orientation.** The player and enemies turn their -Z towards where they move, so a model must face -Z. Most CC0 characters face +Z: pass `--rotate 180`.
- **Categories.** The folder under `assets/models/` sets the budget: `characters` (6,000 triangles, 512 px textures), `locals` and `monsters` (4,000, 512), `bosses` (8,000, 512), `props` (500, 256), `hero_props` (1,500, 256) and `environment` (1,500 per piece, 512).
- **Textures** get an `.import` file that imports them VRAM compressed with mipmaps; the test checks it.
- **Models** get an `.import` file that swaps each material named after a shared one (`assets/materials/<name>.tres`) in for it, and unwraps `environment`, `props` and `hero_props` models for baked lightmaps.
- **`--collision box`** adds the model's bounding box as a convex collider, for furniture the player should bump into.
- **Units.** A source in the wrong units comes out the wrong size; check it in the editor and fix it with `--height`.
- **`--drop`** deletes the named objects (a source's helper shapes) and **`--actions`** keeps only the named animations, so a character carries just the clips the game plays.
- **Shape keys** are dropped from meshes that need decimating, since Blender can't apply a modifier to them.
- Heavy decimation (over about 90%) breaks thin parts such as chair spokes. Prefer sources already near the budget, and look at the result.

`make_kit.py` builds the hotel's modular kit (floors, ceilings, half walls with door and window openings, door frames, stairs and landings) and the props simple enough to model from boxes and prisms (bed, wardrobe, reception desk, lamps, brass room numbers, signs):

```sh
"$BLENDER" --background --factory-startup --python tools/make_kit.py -- \
    PIECE OUT_DIR [--variants wallpaper,brick]
```

It writes one glTF per variant: a shared material for kit pieces, a number or sign for the others. Its docstring and `assets/README.md` give the grid and each piece's origin. Faces are named after the material they take, and UVs are in metres; colliders are separate boxes named `*-convcolonly`. To add a piece, write a builder for it in `make_kit.py`, add it to `PIECES` and give it a manifest entry.

`process_texture.py` takes a source's colour map and writes one albedo image:

```sh
"$BLENDER" --background --factory-startup --python tools/process_texture.py -- \
    COLOR.jpg OUTPUT.jpg --size 512 [--ao AO.jpg] [--saturation 0.8] [--levels 0.55,0.92]
```

It downscales to `--size` with power-of-two sides, multiplies in the ambient occlusion map, desaturates, and with `--levels` remaps the brightness range (to lift a dark source so a tint can colour it). Normal, roughness and height maps are never used.
