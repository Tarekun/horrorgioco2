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

`scenes/main.tscn` is the entry point and stays loaded for the whole run. It holds the post-process layer and a `ScreenHost` node, which it registers with the `GameFlow` autoload (`scripts/autoload/game_flow.gd`). GameFlow instances the title screen (`scenes/ui/main_menu.tscn`) or a level inside the host and tracks the state (title, playing, game over). `main.tscn` also holds the `PauseMenu` (`scenes/ui/pause_menu.tscn`), which opens on `pause` while playing, never over a screen that already paused the tree. Screens never switch scenes themselves: they call `GameFlow.start_new_game()`, `load_game(save)`, `go_to_title()` or `restart_level()`. The starting level is `GameFlow.START_LEVEL_PATH`.

## Settings

`GameSettings` (`scripts/settings/`) is the data: mouse and stick sensitivity, invert Y, a linear volume per audio bus and the retro filter toggle, stored in `user://settings.cfg`. The `UserSettings` autoload loads it, applies the volumes (scaling each bus's level from `default_bus_layout.tres`) and emits `changed` on `commit()`. The camera follows it; the retro filter (#100) should read `UserSettings.settings.is_retro_filter_enabled` and connect to `changed`. `scenes/ui/settings_screen.tscn` edits it, and both the main menu and the pause menu hold an instance. Nothing is read or saved on a headless display, so tests and CI never touch a player's file.

## UI

`scenes/ui/` holds screen-space feedback scenes, instanced by the player scene: `damage_overlay.tscn` (the red edge flash when hit), `health_overlay.tscn` (the vignette and desaturation of the Caution and Danger health states, driven by `PlayerHealthCues`; `PlayerStaminaCues` does the breathing and the winded animation for stamina, which has no on-screen cue) and `game_over_screen.tscn` (shown on death, pauses the game, retry has GameFlow restart the level).

`inventory_screen.tscn` (`InventoryScreen`, also on the player) opens with `inventory` (I / Back) and pauses the game. Its tabs follow `ItemData.Category`; Equip and Use only emit `equip_requested` / `use_requested`, which the player's other nodes act on. Its status readout (an `EcgLine` and the word Fine, Caution or Danger) is the only place the health state appears outside the cues, and never as a number.

`save_screen.tscn` (`SaveScreen`) lists the 8 save slots. In save mode (from a save spot) it writes the save, asking before saving over a used slot. In load mode (the main menu's Load game, game over) it emits `load_requested` with the chosen save, which its owner hands to `GameFlow.load_game()`. Opened at a save spot, a switch button turns it to load mode and back. During play it pauses the game; over a screen that already paused it, or on the title screen, it leaves the pause alone. The player and the main menu each hold an instance.

`scenes/levels/combat_test_arena.tscn` is a small flat arena with the player and two training dummies, for trying out combat by hand (run it with the editor's "Run Current Scene"). The dummies don't attack on their own.

`scenes/levels/graybox_level.tscn` is the game's main level: a lobby, a corridor, side rooms and an office in one building, and a foggy street and yard around it, all built from boxes. Its navmesh is baked into `assets/data/graybox_navmesh.res`; after changing the walls, rebake it with `godot --headless --path . -s res://tools/bake_graybox_navmesh.gd`. The player starts at `PlayerSpawn` on the street and enemies live under `Enemies`.

Doors (`scenes/levels/door.tscn`) are `Interactable`s opened with `interact` (`PlayerInteraction` on the player, with the `InteractionHint` text at the bottom of the screen). A door's `NavigationLink3D` is on only while it's open, so enemies don't path through closed doors. The graybox navmesh is baked with the doors shut, so rebake after moving one.

## Items

Item definitions are `ItemData` resources in `assets/data/items/`, one per item and named after its `id` (`pistol_ammo.tres` has the id `pistol_ammo`). Saves store ids; `ItemCatalog` turns them back into items. The player's `Inventory` (`Player.inventory`) stacks every item without limit. `PlayerItems` on the player carries out the inventory screen's Use (healing) and Equip (weapons). A weapon item points at its `MeleeWeapon` in `assets/data/weapons/`, and weapons stay in the inventory whether held or not. The player starts holding the wooden plank.

Pickups (`scenes/items/pickup.tscn`) are `Interactable`s placed by hand in a level: set the `item` on each instance. How many it holds comes from the item's standard amount in the `Scarcity` resource (`assets/data/scarcity.tres`), times the pickup's `bundles` for a bigger stash. Enemies take their health and hit damage from the same resource. A faint pulsing glint marks them in the dark. Each has a `pickup_id` for saves (by default its path in the level, which changes if the pickup is renamed or moved to another parent) and emits `collected`; see Saving below. The graybox level keeps its pickups under `Pickups`.

## Saving

A save is a `SaveData` (`scripts/saving/save_data.gd`): the level, the save spot used, area name, play time and timestamp, the player's health, inventory, held weapon and flashlight (`Player.write_save()`), and a copy of the world state. `to_dict()` / `from_dict()` turn it into JSON-safe data.

The world state (`WorldState`, `scripts/saving/world_state.gd`) maps persistent ids to small dictionaries. The live one is `SaveSystem.world` (`scripts/autoload/save_system.gd`); a new game starts it empty. Persistent objects register themselves, so levels need no saving code: each joins `WorldState.GROUP`, has an id (an exported `*_id`, by default its path in the level from `WorldState.default_id()`), records its changes with `SaveSystem.world.record()` as they happen, and takes them back in `load_state()` when `WorldState.apply()` runs on a freshly loaded level. Pickups record being collected, doors their lock, enemies their death with the corpse's position and rotation. Objects still as placed record nothing, which is why living enemies come back at their placed positions. Puzzles and documents should follow the same pattern.

Saves live in 8 slots (`SaveSlots`, `scripts/saving/save_slots.gd`), one JSON file each in `user://saves/`: `{"version": 1, "save": {...}}`. Bump `SaveSlots.FORMAT_VERSION` when `SaveData` changes in a way old files can't follow. Reading a slot gives a `SaveSlotInfo`: empty, loadable (with area name, play time and timestamp for the slot screen), unreadable, or from another version. The last two are reported, never loaded. Writes go through a temporary file, so a crash can't damage the old save. `SaveSystem.slots` is the game's set; on a headless display it uses `user://headless_saves/` instead, so tests and CI never touch a player's saves. `SaveSystem.play_time` counts seconds while a level runs unpaused.

Save spots (`scenes/levels/save_spot.tscn`, `SaveSpot`) are `Interactable`s with a placeholder desk look. Set `area_name` on each one; it names the slot. Using one opens the player's save screen with `SaveSystem.capture()`, a save made at that spot, unless an enemy `is_chasing()` (alive, on its feet and alert), in which case it shows a refusal on the hint. Each has a `spot_id` (by default its path in the level) and a `SpawnPoint` child, where loading puts the player. The level a save loads is the scene file of the spot's level. The graybox level keeps its save spots under `SaveSpots`. After placing one, rebake the navmesh, because its desk is solid.

Loading (`GameFlow.load_game(save)`) gives `SaveSystem` the save's world state and play time, instances the save's level fresh, and calls `SaveSystem.restore()` on it. That runs `WorldState.apply()` on the level (collected pickups vanish, doors lock or unlock, dead enemies lie where they fell), gives the player the saved health, inventory, weapon and flashlight (`Player.read_save()`), and puts the player at the save spot's `SpawnPoint` with the camera behind (`Player.place_at()`). Enemies alive in the save are simply the level's own, at their placed positions with full health.
