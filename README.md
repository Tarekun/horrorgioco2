# Horror Game

A 3D survival horror game built with Godot 4 and GDScript.

## Godot version

The project is pinned to **Godot 4.7.2-stable** (standard build, not .NET).
The exact version lives in [`.godot-version`](.godot-version), which tooling reads;
`project.godot` declares the `4.7` feature set. Download it from
<https://github.com/godotengine/godot/releases/tag/4.7.2-stable>.

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
| `tests/`   | Automated tests |

Each folder has its own README with more detail.

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
