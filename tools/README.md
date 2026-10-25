# tools/

Development tooling, not shipped with the game.

- `check.sh` – runs every check an agent must pass before committing (see `AGENTS.md`).
- `check_scripts.gd` – loads every script and scene headless and exits non-zero on any load error; called by `check.sh`.
