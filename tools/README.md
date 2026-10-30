# tools/

Development tooling, not shipped with the game.

- `check.sh` – runs every check and test an agent must pass before committing (see `AGENTS.md`).
- `install_godot.sh` – downloads the pinned Godot editor (Linux x86_64 or arm64), verifies its checksum and prints its path; used by CI.
- `install_blender.sh` – downloads the pinned Blender (version in `.blender-version`, Linux x86_64), verifies its checksum and prints its path; for the asset pipeline below.
- `check_scripts.gd` – loads every script and scene headless and exits non-zero on any load error; called by `check.sh`.
- `bake_navmesh.gd` – bakes a level's navmesh from its collision geometry, with the doors shut: `godot --headless --path . -s res://tools/bake_navmesh.gd -- hotel_miramare`.
- `generate_hotel_graybox.py` – writes `scenes/levels/hotel_miramare.tscn` from the layout in `docs/design/slice.md`. It overwrites the whole scene, and the scene has been populated by hand since #71, so it is kept as the record of how the layout was built rather than run; its docstring has the steps, including the navmesh rebake.
- `build_assets.py` and `process_model.py` – the asset pipeline, below.

## Asset pipeline

Downloaded CC0 models are fitted to the budgets in `docs/design/visual-style.md` by a headless Blender script. It runs locally, never in CI; only its output is committed.

Blender is pinned to **4.5 LTS** in `.blender-version`. Install it and point `BLENDER` at it:

```sh
export BLENDER="$(tools/install_blender.sh)"
```

To add a model:

1. Add an entry to `assets/sources.json` with its name, category, source page, author, license (CC0 only), how to fetch it and its `process` options. The `build_assets.py` docstring describes the format.
2. Run `tools/build_assets.py <name>`. It downloads the raw files into `.asset_cache/` (gitignored), runs `process_model.py` in Blender and writes `assets/models/<category>/<name>/`. Without names it rebuilds every model.
3. Run `godot --headless --path . --import`, look at the model in the editor, and add a row to the models table in `assets/README.md`.
4. Run `tools/check.sh`: `tests/assets/test_model_budgets.gd` checks every model against its category's budgets.

`process_model.py` also runs on its own, for trying out settings on any file:

```sh
"$BLENDER" --background --factory-startup --python tools/process_model.py -- \
    INPUT.glb OUTPUT.gltf --triangles 450 --texture-size 256 [--rotate 180] [--height 1.8]
```

It imports glTF, FBX, OBJ or `.blend`; turns and scales the model and puts its origin at the bottom centre; decimates it to `--triangles` (first merging flat areas, then collapsing edges); keeps only the base colour, alpha and emission of each material, with constant roughness and metallic; downscales textures to `--texture-size`; and exports glTF with separate textures and its animations. `--help` lists every option.

- **Orientation.** The player and enemies turn their -Z towards where they move, so a model must face -Z. Most CC0 characters face +Z: pass `--rotate 180`.
- **Categories.** The folder under `assets/models/` sets the budget: `characters` (6,000 triangles, 512 px textures), `locals` and `monsters` (4,000, 512), `bosses` (8,000, 512), `props` (500, 256), `hero_props` (1,500, 256) and `environment` (1,500 per piece, 512).
- **Textures** get an `.import` file that imports them VRAM compressed with mipmaps; the test checks it.
- **Shape keys** are dropped from meshes that need decimating, since Blender can't apply a modifier to them.
- Heavy decimation (over about 90%) breaks thin parts such as chair spokes. Prefer sources already near the budget, and look at the result.
