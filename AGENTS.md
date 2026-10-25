# Agent notes

This project is a 3D survival horror videogame built with Godot 4 and GDScript.

Project skills live in `.agent/skills/`: `pm` for project management on the Gitea repo, `dev` for developing an issue through to a pull request.

Design references live in `docs/design/`. Before starting a task, read the relevant doc:

- `gameplay.md`: the rules and starting values for movement, camera, combat, resources and saving;
- `visual-style.md`: model and texture budgets, materials, lighting and post-processing, for art and rendering work;
- `premise.md`: story, setting, tone and pillars.

## Godot version

Pinned to **Godot 4.7.2-stable** (standard build) in `.godot-version`; keep `config/features` in `project.godot` in sync. Use **only Godot 4 APIs**. Most examples online are Godot 3, so check anything unfamiliar against the [4.7 docs](https://docs.godotengine.org/en/4.7/). Usual traps: annotations (`@export`, `@onready`, `@tool`), `await` instead of `yield`, `signal.connect(callable)`, `*3D` node types (`Node3D`, `CharacterBody3D`), `instantiate()`, `FileAccess`/`DirAccess`. `tools/check.sh` catches Godot 3 syntax, but renamed APIs only fail when that code runs.

## Conventions

These follow the official [GDScript style guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html). gdlint and gdformat enforce most of them.

### Static typing

All GDScript is statically typed. `project.godot` sets `debug/gdscript/warnings/untyped_declaration` to *error*, so untyped code fails to load and fails the check (`addons/` is exempt).

- Declare types on every variable, parameter and return value, including `-> void`.
- Use `:=` only when the type is obvious from the right-hand side (`var dir := Vector3.ZERO`, `var timer := Timer.new()`). Otherwise write it out (`var health: int = max_health`).
- Use typed collections: `Array[Enemy]`, `Dictionary[StringName, int]`.
- Cast explicitly with `as` when narrowing (`var body := collider as CharacterBody3D`) and handle `null`.
- Give every reusable script a `class_name` so it can be used as a type.

### Naming

| Thing | Style | Example |
|---|---|---|
| Files and folders | `snake_case` | `scripts/player/player_controller.gd`, `scenes/player/player.tscn` |
| `class_name`, nodes in scenes | `PascalCase` | `class_name PlayerController`, `$CameraPivot` |
| Functions, variables, parameters | `snake_case` | `func take_damage(amount: int) -> void` |
| Private members | leading `_` | `var _stamina: float`, `func _update_camera() -> void` |
| Constants, enum values | `CONSTANT_CASE` | `const MAX_SPEED := 6.0`, `enum State { IDLE, CHASING }` |
| Enum names | `PascalCase` | `enum State` |
| Signals | past-tense `snake_case` | `signal health_changed(new_value: int)`, `signal died` |
| Input actions | `snake_case` verbs | `interact`, `move_forward` |
| Booleans | `is_` / `has_` / `can_` prefix | `is_sprinting`, `has_key` |

### Folder layout

| Folder | Contents |
|---|---|
| `scenes/` | Scenes (`.tscn`), grouped in subfolders by feature (`scenes/player/`, `scenes/enemies/`, `scenes/levels/`). `scenes/main.tscn` is the entry point. |
| `scripts/` | GDScript, mirroring `scenes/` (`scenes/player/player.tscn` → `scripts/player/player.gd`). Autoloads go in `scripts/autoload/`. |
| `assets/` | Imported art, audio and fonts by type (`assets/models/`, `assets/textures/`, `assets/audio/`). Data resources (`.tres`) go in `assets/data/`. |
| `tests/` | GUT tests mirroring `scripts/` (`scripts/player/player.gd` → `tests/player/test_player.gd`). |
| `tools/` | Development tooling (check script). Not shipped. |
| `addons/` | Third-party plugins (GUT). Don't edit; update by replacing the whole folder. |

Commit the `.uid` and `.import` sidecar files Godot generates next to scripts and assets. Never commit `.godot/`.

### Scene and script organization

- One script per scene root, with the same base name as the scene. Child nodes get their own script only when they have their own behavior.
- Compose behavior from small nodes and scenes, such as `HealthComponent` or `Interactable`, rather than deep inheritance chains.
- "Call down, signal up": parents call methods on their children, and children report to parents and siblings through signals. Never reach up with `get_parent()` chains or absolute `/root/...` paths.
- Reference child nodes with `@onready var _camera: Camera3D = %Camera` (scene-unique names) or `@export` node references, not long `$A/B/C` paths.
- Use autoloads only for global systems (game state, save/load, audio bus). Keep gameplay logic in scenes.
- Read input through the input actions in `project.godot` (`Input.is_action_pressed(&"sprint")`), never raw keycodes. Add new actions there with both keyboard/mouse and gamepad bindings, then extend `tests/test_input_map.gd`.
- Keep tunable values in `@export` variables or resources so they can be adjusted without code changes.
- Within a script, keep the style-guide order: `@tool`, `class_name`, `extends`, doc comment, signals, enums, constants, `@export` vars, public vars, private vars, `@onready` vars, `_init`/`_ready` and other built-in virtuals, public methods, private methods.
- Keep logic testable: put rules and calculations in plain methods or `RefCounted` classes that tests can call without a running scene.

## Checks and tests

Run `tools/check.sh` before every commit and fix anything it reports. It needs:

- the pinned Godot editor binary (version in `.godot-version`) on `PATH` as `godot`, or set `GODOT=/path/to/godot`. `tools/install_godot.sh` downloads and verifies it, then prints its path (Linux x86_64 or arm64), e.g. `export GODOT="$(tools/install_godot.sh)"`;
- gdtoolkit (`pip install -r requirements-dev.txt`), providing `gdlint` and `gdformat`.

The script runs these steps and exits non-zero if any fails, listing the failed steps at the end:

1. **Import project**: `godot --headless --import` builds the `.godot/` cache.
2. **Load scripts and scenes**: `tools/check_scripts.gd` loads every `.gd` and `.tscn` file and fails on any parse or load error, including untyped declarations.
3. **Run main scene**: runs the main scene for one frame with `--quit`.
4. **gdlint** and **gdformat --check**: lint and formatting on all GDScript files outside `addons/`.
5. **Tests**: runs the GUT suite in `tests/` headless and fails if any test fails.

In steps 1–3, any `ERROR:` or `SCRIPT ERROR:` printed by Godot fails the step, even if Godot exits 0. To fix formatting, run `gdformat` on the reported files.

To run only the tests: `godot --headless --path . -s res://addons/gut/gut_cmdln.gd`. Add `-gselect=<file>` for one file or `-gunit_test_name=<name>` for one test (see `tests/README.md`). New gameplay logic comes with tests.

### CI

`.gitea/workflows/ci.yml` runs `tools/check.sh` on Gitea Actions for every pull request and every push to `main`. It installs the pinned Godot with `tools/install_godot.sh` and gdtoolkit from `requirements-dev.txt`. A PR with a failing check must not be merged. If you change the Godot version, update `.godot-version` and CI picks it up.
