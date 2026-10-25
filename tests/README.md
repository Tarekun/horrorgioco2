# tests/

Automated tests, written with [GUT](https://github.com/bitwes/Gut) (Godot Unit Test) 9.7.1, installed in `addons/gut/`.

- Test files are named `test_*.gd`, extend `GutTest` and define test methods named `test_*`.
- Subfolders are included, so mirror the `scripts/` layout (e.g. `tests/player/test_player.gd`).
- Settings live in `.gutconfig.json` at the project root.

Run the suite headless (also run by `tools/check.sh`):

```sh
godot --headless --path . -s res://addons/gut/gut_cmdln.gd
```

Run a single file with `-gselect=test_input_map.gd`, or a single test with `-gunit_test_name=<name>`.
The command exits non-zero if any test fails. Tests can also be run from the GUT panel in the editor.

## Why GUT

GUT was chosen over gdUnit4 because it is pure GDScript with no extra runtime, its command-line runner
works headless out of the box and exits non-zero on failure, and its 9.7.x releases explicitly track
Godot 4.7's stricter return-type checks. gdUnit4 is more feature-rich (C# support, scene runner) but
needs its own wrapper scripts to run from the command line, which this GDScript-only project doesn't need.
