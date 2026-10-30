# tools/

Development tooling, not shipped with the game.

- `check.sh` – runs every check and test an agent must pass before committing (see `AGENTS.md`).
- `install_godot.sh` – downloads the pinned Godot editor (Linux x86_64 or arm64), verifies its checksum and prints its path; used by CI.
- `check_scripts.gd` – loads every script and scene headless and exits non-zero on any load error; called by `check.sh`.
- `bake_navmesh.gd` – bakes a level's navmesh from its collision geometry, with the doors shut: `godot --headless --path . -s res://tools/bake_navmesh.gd -- hotel_miramare`.
