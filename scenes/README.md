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

`scenes/main.tscn` is the entry point and stays loaded for the whole run. It holds the post-process layer and a `ScreenHost` node, which it registers with the `GameFlow` autoload (`scripts/autoload/game_flow.gd`). GameFlow instances the title screen (`scenes/ui/main_menu.tscn`) or a level inside the host and tracks the state (title, playing, game over). `main.tscn` also holds the `PauseMenu` (`scenes/ui/pause_menu.tscn`), which opens on `pause` while playing, never over a screen that already paused the tree. Screens never switch scenes themselves: they call `GameFlow.start_new_game()`, `load_game(save)`, `go_to_title()` or `restart_game()`. The starting level is `GameFlow.START_LEVEL_PATH`.

## Settings

`GameSettings` (`scripts/settings/`) is the data: mouse and stick sensitivity, invert Y, a linear volume per audio bus and the retro filter toggle, stored in `user://settings.cfg`. The `UserSettings` autoload loads it, applies the volumes (scaling each bus's level from `default_bus_layout.tres`) and emits `changed` on `commit()`. The camera follows it; the retro filter (#100) should read `UserSettings.settings.is_retro_filter_enabled` and connect to `changed`. `scenes/ui/settings_screen.tscn` edits it, and both the main menu and the pause menu hold an instance. Nothing is read or saved on a headless display, so tests and CI never touch a player's file.

## UI

`scenes/ui/` holds screen-space feedback scenes, instanced by the player scene: `damage_overlay.tscn` (the red edge flash when hit), `health_overlay.tscn` (the vignette and desaturation of the Caution and Danger health states, driven by `PlayerHealthCues`; `PlayerStaminaCues` does the breathing and the winded animation for stamina, which has no on-screen cue) and `game_over_screen.tscn` (shown on death, pauses the game, and offers Load last save, Load game… and Quit to title).

`inventory_screen.tscn` (`InventoryScreen`, also on the player) opens with `inventory` (I / Back) and pauses the game. Its tabs follow `ItemData.Category`; Equip and Use only emit `equip_requested` / `use_requested`, which the player's other nodes act on. Its status readout (an `EcgLine` and the word Fine, Caution or Danger) is the only place the health state appears outside the cues, and never as a number.

`save_screen.tscn` (`SaveScreen`) lists the 8 save slots. In save mode (from a save spot) it writes the save, asking before saving over a used slot. In load mode (the main menu's Load game, game over) it emits `load_requested` with the chosen save, which its owner hands to `GameFlow.load_game()`. Opened at a save spot, a switch button turns it to load mode and back. During play it pauses the game; over a screen that already paused it, or on the title screen, it leaves the pause alone. The player and the main menu each hold an instance.

`screen_fade.tscn` (`ScreenFade`) fades the screen to black and back, and keeps fading while the game is paused. The rubble chute uses it for its slide: until in-engine cutscenes (#95) exist, a short sequence pauses the game, as the menus do, so all input is locked, and fades out and in around what happens.

`scenes/levels/combat_test_arena.tscn` is a small flat arena with the player and two training dummies, for trying out combat by hand (run it with the editor's "Run Current Scene"). The dummies don't attack on their own.

`scenes/levels/hotel_miramare.tscn` is the vertical slice's level, where a new game starts: the Hotel Miramare in graybox, laid out from the floor plans in `docs/design/slice.md`. It has four levels on the same 30 × 14 m footprint, with x running west to east and north (the sea) towards −z: the basement at y −3.2, GF at 0, 1F at 3.2 and 2F at 6.4. One switchback staircase in the west stairwell joins them all, and a solid lift core stands in the lift halls. The nodes are grouped by floor:
- `Structure/<Floor>` holds the slabs and walls; `Structure/Stairs`, `Structure/Lift` and `Structure/Outside` (the foggy seafront) are shared.
- `Props/<Floor>` holds furniture blocks. The placeholders that later tasks turn into interactables are named after their ids: `ObstacleSunbeds`, `ChuteTop`/`ChuteBottom`, `KeyCabinet`, `SwitchboardBasement`, `ShutterStaff`, `PorterLocker`.
- `Lights/<Floor>` follows the doc's lighting: 2F lit, 1F dark, GF only the porter's desk lamp. The basement's `BoilerRoom` lights are hidden until the power comes back.
- `Doors/<Floor>` holds every door in the doc's locks table, each with its `door_id`. Locked doors that open with a key have the key item's id as their `key_id`. `door_stairs_gf` is locked with `blocked_by` metadata until the sunbeds are moved.
- `Enemies` holds E1–E3 from the doc's encounters, all in the basement. E1 (`enemy_boiler_room`) is dormant behind the boilers until something calls `wake()`, which the power will do; E3 keeps to the staff room with a small `wander_radius`. The staff room door starts open, so E3 can come out.
- `Pickups` holds the doc's items, each with its `pickup_id`: the healing (2 health drinks and a first aid kit), the steel pipe and the key items K1, K2 and K4. `BlockadeRoom28` is the plank across room 28's doorway: a pickup giving the wooden plank, with the plank's collider as a child, so taking it clears the way in.
- `SaveSpots` holds S1–S3 with their `spot_id`s and area names.
- `TensionEvents` is an instance of `scenes/levels/tension/hotel_tension_events.tscn`, the eleven one-shot scares of the doc's Tension table (see Tension events below).
- `RubbleChute` (`scenes/levels/rubble_chute.tscn`) is the chute from room 15 down to the GF building site: its root, at the chute's top, is the *"Slide down."* interactable; its `Mouth` over the skip answers *"No way back up that."*; `Landing` is where the player is put on GF. Its look is the `ChuteTop`/`ChuteBottom`/`Skip` props. It has no saved state.
- `Documents` (D1–D4) and `Puzzles` (the key cabinet, and the spot on room 22's nightstand where the clock appears) are `Marker3D` placeholders carrying their ids as metadata, for #80 and #82 to replace.

The player starts at `PlayerSpawn` in room 22. The navmesh is baked into `assets/data/hotel_miramare_navmesh.res`. The layout came from `tools/generate_hotel_graybox.py`, but everything above from `Enemies` down was placed by hand, so edit the scene directly: rerunning the generator would wipe it.

`scenes/levels/graybox_level.tscn` is the earlier test level: a lobby, a corridor, side rooms and an office in one building, and a foggy street and yard around it, all built from boxes. The save and game over integration tests run on it. Its navmesh is baked into `assets/data/graybox_navmesh.res`. The player starts at `PlayerSpawn` on the street and enemies live under `Enemies`.

After changing a level's walls, doors or solid props, rebake its navmesh with `godot --headless --path . -s res://tools/bake_navmesh.gd -- <level>`, where `<level>` is `hotel_miramare` or `graybox_level`.

Doors (`scenes/levels/door.tscn`) are `Interactable`s opened with `interact` (`PlayerInteraction` on the player, with the `InteractionHint` text at the bottom of the screen). A locked door with a `key_id` unlocks and opens for a player carrying that key item, with a "Used <key>." message; the key is kept. A door's `NavigationLink3D` is on only while it's open, so enemies don't path through closed doors. Navmeshes are baked with the doors shut, so rebake after moving one.

## Tension events

The scares above ground (`docs/design/slice.md`, Tension) are `TensionEvent`s (`scripts/levels/tension/`), one per id, under the hotel's `TensionEvents`. Each event fires once per level load and saves nothing, so loading a save plays it again. It is set off by a trigger child: a `TensionTrigger` (an `Area3D` that goes off when the player enters it) or a `TensionSight` (the player, standing in its area, looks at its `target` with nothing in between). When it fires it runs its `TensionAction` children, each after its own `delay`:

- `TensionSound` plays a stream at its position, on the SFX bus (or Ambience for a lasting background), optionally for a `duration` or moving by `travel` while it plays;
- `TensionParticles` starts a `CPUParticles3D` set up in the scene (left with `emitting` off); steam, fog and draughts share the events scene's soft `vapour` billboard material;
- `TensionSway` swings a node around one of its axes, dying away over a `duration` or for good; `TensionTurn` turns one and leaves it (a door creaking open); `TensionReveal` shows hidden nodes (a lit stove's flame);
- `TensionFlicker` flickers the lights and glowing lamp shades under two groups named by path, with a dip of the camera's exposure, since the hotel's lamps are baked into the lightmap and their energy only lights dynamic objects.

All values are exported, so writers tune an event in the inspector. Wiring that is particular to one event is done with signal connections in the scene: room 21's `ShowerTap` (an `Interactable`, usable only while the shower runs) stops the water and the steam, and a second trigger by room 23's door stops the phone. Events are sound and light only: they never hurt the player and never call `NoiseEvent`, so enemies don't hear them.

The props an event moves belong to the event, not to `Props`: the curtain at the 2F corridor's west end and room 13's wardrobe (`scenes/levels/tension/creaking_wardrobe.tscn`, with doors that open and hangers that swing). They are left out of `tools/dress_hotel.gd`'s layout, their meshes are `gi_mode` dynamic so a lightmap bake leaves them out, and their old entries were removed from the baked lightmap's users. The laundry's extra sheet in front of a linen cart is new and has no collider.

## Items

Item definitions are `ItemData` resources in `assets/data/items/`, one per item and named after its `id` (`pistol_ammo.tres` has the id `pistol_ammo`). Saves store ids; `ItemCatalog` turns them back into items. The player's `Inventory` (`Player.inventory`) stacks every item without limit. `PlayerItems` on the player carries out the inventory screen's Use (healing) and Equip (weapons). A weapon item points at its `MeleeWeapon` in `assets/data/weapons/`, and weapons stay in the inventory whether held or not. The player starts holding the wooden plank.

Pickups (`scenes/items/pickup.tscn`) are `Interactable`s placed by hand in a level: set the `item` on each instance. How many it holds comes from the item's standard amount in the `Scarcity` resource (`assets/data/scarcity.tres`), times the pickup's `bundles` for a bigger stash. Enemies take their health and hit damage from the same resource. A faint pulsing glint marks them in the dark. Each has a `pickup_id` for saves (by default its path in the level, which changes if the pickup is renamed or moved to another parent) and emits `collected`; see Saving below. The graybox level keeps its pickups under `Pickups`.

## Examining

Examinables (`Examinable`, `scripts/interaction/examinable.gd`) are `Interactable`s for things the player can look at, with the prompt "Examine". They have no look of their own: add one as a `Node3D` with the script at the object, where the player stands to look at it, and fill in `lines`. Each interaction shows the next line and the last one leads back to the first; a description left unfinished for `restart_after` seconds starts over. Until the dialogue display (#94) exists, the lines appear on the `InteractionHint`, which keeps long messages up long enough to read (`seconds_per_character`).

## Saving

A save is a `SaveData` (`scripts/saving/save_data.gd`): the level, the save spot used, area name, play time and timestamp, the player's health, inventory, held weapon and flashlight (`Player.write_save()`), and a copy of the world state. `to_dict()` / `from_dict()` turn it into JSON-safe data.

The world state (`WorldState`, `scripts/saving/world_state.gd`) maps persistent ids to small dictionaries. The live one is `SaveSystem.world` (`scripts/autoload/save_system.gd`); a new game starts it empty. Persistent objects register themselves, so levels need no saving code: each joins `WorldState.GROUP`, has an id (an exported `*_id`, by default its path in the level from `WorldState.default_id()`), records its changes with `SaveSystem.world.record()` as they happen, and takes them back in `load_state()` when `WorldState.apply()` runs on a freshly loaded level. Pickups record being collected, doors their lock, enemies their death with the corpse's position and rotation. Objects still as placed record nothing, which is why living enemies come back at their placed positions. Puzzles and documents should follow the same pattern.

Saves live in 8 slots (`SaveSlots`, `scripts/saving/save_slots.gd`), one JSON file each in `user://saves/`: `{"version": 1, "save": {...}}`. Bump `SaveSlots.FORMAT_VERSION` when `SaveData` changes in a way old files can't follow. Reading a slot gives a `SaveSlotInfo`: empty, loadable (with area name, play time and timestamp for the slot screen), unreadable, or from another version. The last two are reported, never loaded. Writes go through a temporary file, so a crash can't damage the old save. `SaveSystem.slots` is the game's set; on a headless display it uses `user://headless_saves/` instead, so tests and CI never touch a player's saves. `SaveSystem.play_time` counts seconds while a level runs unpaused.

Save spots (`scenes/levels/save_spot.tscn`, `SaveSpot`) are `Interactable`s with a placeholder desk look. Set `area_name` on each one; it names the slot. Using one opens the player's save screen with `SaveSystem.capture()`, a save made at that spot, unless an enemy `is_chasing()` (alive, on its feet and alert), in which case it shows a refusal on the hint. Each has a `spot_id` (by default its path in the level) and a `SpawnPoint` child, where loading puts the player. The level a save loads is the scene file of the spot's level. The graybox level keeps its save spots under `SaveSpots`. After placing one, rebake the navmesh, because its desk is solid.

Loading (`GameFlow.load_game(save)`) gives `SaveSystem` the save's world state and play time, instances the save's level fresh, and calls `SaveSystem.restore()` on it. That runs `WorldState.apply()` on the level (collected pickups vanish, doors lock or unlock, dead enemies lie where they fell), gives the player the saved health, inventory, weapon and flashlight (`Player.read_save()`), and puts the player at the save spot's `SpawnPoint` with the camera behind (`Player.place_at()`). Enemies alive in the save are simply the level's own, at their placed positions with full health.

On death, game over's **Load last save** loads `SaveSystem.last_save`: the most recent save written or loaded this session. A new game clears it, so with no save yet it starts the game over (`GameFlow.restart_game()`). **Load game…** opens its own save screen in load mode, and **Quit to title** goes back to the main menu.
