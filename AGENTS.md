# Agent notes

This project is a 3D survival horror videogame.

Project skills live in `.agent/skills/`: `pm` for project management on the Gitea repo, `dev` for developing an issue through to a pull request.

## Checks

Run `tools/check.sh` before every commit and fix anything it reports. It needs:

- the pinned Godot editor binary (version in `.godot-version`) on `PATH` as `godot`, or set `GODOT=/path/to/godot`;
- gdtoolkit (`pip install -r requirements-dev.txt`), providing `gdlint` and `gdformat`.

The script runs these steps and exits non-zero if any fails, listing the failed steps at the end:

1. **Import project** – `godot --headless --import` builds the `.godot/` cache.
2. **Load scripts and scenes** – `tools/check_scripts.gd` loads every `.gd` and `.tscn` file and fails on any parse or load error.
3. **Run main scene** – runs the main scene for one frame with `--quit`.
4. **gdlint** and **gdformat --check** – lint and formatting on all GDScript files outside `addons/`.
5. **Tests** – runs the GUT suite in `tests/` headless; fails if any test fails.

In steps 1–3, any `ERROR:` or `SCRIPT ERROR:` printed by Godot fails the step, even if Godot exits 0. To fix formatting, run `gdformat` on the reported files.

To run only the tests: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd` (see `tests/README.md`).
