# tools/

Development tooling, not shipped with the game.

- `check.sh` – runs every check and test an agent must pass before committing (see `AGENTS.md`).
- `install_godot.sh` – downloads the pinned Godot editor (Linux x86_64), verifies its checksum and prints its path; used by CI.
- `check_scripts.gd` – loads every script and scene headless and exits non-zero on any load error; called by `check.sh`.
