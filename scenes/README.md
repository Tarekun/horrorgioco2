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
