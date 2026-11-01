# Horror Game

A 3D survival horror game built with Godot 4 and GDScript.

## Godot version

The project is pinned to **Godot 4.7.2-stable** (standard build, not .NET).
The exact version lives in [`.godot-version`](.godot-version), which tooling reads;
`project.godot` declares the `4.7` feature set. Download it from
<https://github.com/godotengine/godot/releases/tag/4.7.2-stable>, or on Linux (x86_64 or arm64) run
`tools/install_godot.sh`, which downloads and verifies it and prints the binary's path.

Open the project by importing `project.godot` in the editor, or run it from the command line:

```sh
godot --headless --path . --import   # build the .godot/ import cache
godot --path .                       # run the main scene
```

## Layout

| Folder     | Contents |
|------------|----------|
| `scenes/`  | Scenes (`.tscn`); `scenes/main.tscn` is the entry point |
| `scripts/` | GDScript sources (`.gd`) |
| `assets/`  | Imported art, audio, fonts and other resources |
| `tests/`   | Automated tests (GUT) |
| `addons/`  | Third-party editor plugins (GUT) – don't edit |
| `tools/`   | Development tooling such as the check script |

Each folder has its own README with more detail.

## Checks

Run `tools/check.sh` to import the project, load every script and scene, run the main scene,
lint/format-check all GDScript and run the test suite. It needs Godot (set `GODOT` if it isn't on `PATH` as `godot`)
and gdtoolkit (`pip install -r requirements-dev.txt`). See `AGENTS.md` for details and for the
coding conventions (Godot 4 APIs only, static typing, naming, layout).

CI (`.github/workflows/ci.yml`) runs the same script on every pull request and on pushes to `main`. (A copy lives at `.gitea/workflows/ci.yml` for the Gitea remote.)

## Input map

Actions are defined in `project.godot` for keyboard/mouse and gamepad:

| Action | Keyboard / mouse | Gamepad |
|--------|------------------|---------|
| `move_forward` / `move_back` / `move_left` / `move_right` | W / S / A / D | Left stick |
| `look_up` / `look_down` / `look_left` / `look_right` | Arrow keys (mouse motion is read in code) | Right stick |
| `sprint` | Shift | Left stick click |
| `attack` | Left mouse button | Right trigger |
| `dodge` | Space | B / Circle |
| `interact` | E | A / Cross |
| `flashlight` | F | Y / Triangle |
| `pause` | Escape | Start |

Keys are bound by physical location, so WASD stays in place on non-QWERTY layouts.
Godot's input map cannot bind mouse motion, so camera look reads `InputEventMouseMotion` directly
and uses the `look_*` actions for the gamepad and keyboard fallback.
