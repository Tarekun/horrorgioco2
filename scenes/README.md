# scenes/

Godot scenes (`.tscn`). `main.tscn` is the project's main scene and the entry point when the game runs.

Group scenes in subfolders by feature (e.g. `scenes/player/`, `scenes/levels/`) as the game grows.

## Collision layers

Named in `project.godot` (`layer_names/3d_physics/*`); bit masks in `scripts/combat/combat_layers.gd`.

| Layer | Name | Used by |
|---|---|---|
| 1 | `world` | level geometry; the camera spring arm collides with it |
| 2 | `player` | the player body |
| 3 | `enemy` | enemy bodies |
| 4 | `player_hitbox` | the player's attack hitboxes |
| 5 | `enemy_hitbox` | enemy attack hitboxes |
| 6 | `player_hurtbox` | the player's `Hurtbox` |
| 7 | `enemy_hurtbox` | enemy `Hurtbox` nodes |

Hitboxes sit on their own layer and only mask the opposing hurtbox layer; hurtboxes are passive (mask 0). Bodies mask `world` plus the opposing body layer.

## Game flow

`scenes/main.tscn` is the entry point and stays loaded for the whole run. It holds the post-process layer and a `ScreenHost` node, which it registers with the `GameFlow` autoload (`scripts/autoload/game_flow.gd`). GameFlow instances the title screen (`scenes/ui/main_menu.tscn`) or a level inside the host and tracks the state (title, playing, game over). `main.tscn` also holds the `PauseMenu` (`scenes/ui/pause_menu.tscn`), which opens on `pause` while playing, never over a screen that already paused the tree. Screens never switch scenes themselves: they call `GameFlow.start_new_game()`, `go_to_title()` or `restart_level()`. The starting level is `GameFlow.START_LEVEL_PATH`.

## Settings

`GameSettings` (`scripts/settings/`) is the data: mouse and stick sensitivity, invert Y, a linear volume per audio bus and the retro filter toggle, stored in `user://settings.cfg`. The `UserSettings` autoload loads it, applies the volumes (scaling each bus's level from `default_bus_layout.tres`) and emits `changed` on `commit()`. The camera follows it; the retro filter (#100) should read `UserSettings.settings.is_retro_filter_enabled` and connect to `changed`. `scenes/ui/settings_screen.tscn` edits it, and both the main menu and the pause menu hold an instance. Nothing is read or saved on a headless display, so tests and CI never touch a player's file.

## UI

`scenes/ui/` holds screen-space feedback scenes, instanced by the player scene: `damage_overlay.tscn` (the red edge flash when hit) and `game_over_screen.tscn` (shown on death, pauses the game, retry has GameFlow restart the level).

`scenes/levels/combat_test_arena.tscn` is a small flat arena with the player and two training dummies, for trying out combat by hand (run it with the editor's "Run Current Scene"). The dummies don't attack on their own.

`scenes/levels/graybox_level.tscn` is the game's main level: a lobby, a corridor, side rooms and an office in one building, and a foggy street and yard around it, all built from boxes. Its navmesh is baked into `assets/data/graybox_navmesh.res`; after changing the walls, rebake it with `godot --headless --path . -s res://tools/bake_graybox_navmesh.gd`. The player starts at `PlayerSpawn` on the street and enemies live under `Enemies`.

Doors (`scenes/levels/door.tscn`) are `Interactable`s opened with `interact` (`PlayerInteraction` on the player, with the `InteractionHint` text at the bottom of the screen). A door's `NavigationLink3D` is on only while it's open, so enemies don't path through closed doors. The graybox navmesh is baked with the doors shut, so rebake after moving one.
