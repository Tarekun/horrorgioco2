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

## UI

`scenes/ui/` holds screen-space feedback scenes, instanced by the player scene: `damage_overlay.tscn` (the red edge flash when hit), `health_overlay.tscn` (the vignette and desaturation of the Caution and Danger health states, driven by `PlayerHealthCues`; `PlayerStaminaCues` does the breathing and the winded animation for stamina, which has no on-screen cue) and `game_over_screen.tscn` (shown on death, pauses the game, retry reloads the current scene).

`scenes/levels/combat_test_arena.tscn` is a small flat arena with the player and two training dummies, for trying out combat by hand (run it with the editor's "Run Current Scene"). The dummies don't attack on their own.

`scenes/levels/graybox_level.tscn` is the game's main level: a lobby, a corridor, side rooms and an office in one building, and a foggy street and yard around it, all built from boxes. Its navmesh is baked into `assets/data/graybox_navmesh.res`; after changing the walls, rebake it with `godot --headless --path . -s res://tools/bake_graybox_navmesh.gd`. The player starts at `PlayerSpawn` on the street and enemies live under `Enemies`.

Doors (`scenes/levels/door.tscn`) are `Interactable`s opened with `interact` (`PlayerInteraction` on the player, with the `InteractionHint` text at the bottom of the screen). A door's `NavigationLink3D` is on only while it's open, so enemies don't path through closed doors. The graybox navmesh is baked with the doors shut, so rebake after moving one.
