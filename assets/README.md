# assets/

Source assets imported by Godot: models, textures, materials, audio and fonts.
Organize by type (e.g. `assets/models/`, `assets/textures/`, `assets/audio/`); data resources (`.tres`) go in `assets/data/`.

Commit the `.import` files Godot generates next to each asset; the imported data itself lives in `.godot/` and is not committed.

## Player character

Luca's placeholder is the mannequin of Quaternius' **Universal Animation Library** (Standard), a faceless humanoid on a 53-bone rig, decimated from 13,743 to 5,879 triangles. `tools/build_assets.py luca` builds `assets/models/characters/luca/` from the source and keeps only the clips the game plays (the entry in `sources.json` lists them). `tools/generate_player_model.gd` then writes `scenes/player/player_model.tscn` and `assets/data/player_animations.res`; run it with `godot --headless --path . --script res://tools/generate_player_model.gd` after rebuilding the model or changing the clip mapping.

- **Source:** [Universal Animation Library on OpenGameArt](https://opengameart.org/node/174563), also at [quaternius.com](https://quaternius.com/packs/universalanimationlibrary.html).
- **Author and license:** Quaternius, CC0.
- **Replacing it:** build the final rigged model into the same scene (it keeps the `PlayerModel` script, the `AnimationPlayer` library and the `AnimationTree`), or point the clip mapping in the generator at its animations. The `AnimationTree` blend space (idle 0, walk 1.5, run 3.5, sprint 5.5 m/s) is driven by `PlayerModel.set_speed()`.

The generator maps the source's clips to the states the game plays: `idle`, `walk`, `run` (the jog) and `sprint` in the blend space, and one state each for `attack_light_1` to `3` (two punches and a sword swing), `attack_heavy_charge`, `attack_heavy_swing`, `dodge` (a roll), `backstep` (the roll played backwards), `hit`, `death` and `winded` (a crouch). `PlayerModel.play_action()` jumps to a state and `return_to_locomotion()` goes back; attacks are stretched to the `MeleeWeapon` timings (`assets/data/weapons/wooden_plank.tres`). The wooden plank is a box attached to the right hand bone. The source has no clips for a backstep, a charge or being winded, so those are stand-ins.

Record the source and license of every imported asset here, as the visual style doc requires.

## Models

Each model is in `assets/models/<category>/<name>/`, where the category folder sets its budget in `docs/design/visual-style.md`, and has an entry `<name>` in `sources.json`, so `tools/build_assets.py <name>` rebuilds it (see `tools/README.md`). Downloaded models are CC0, fitted to budget by the asset pipeline, and their raw downloads are not committed. The hotel kit and the simplest props are made by `tools/make_kit.py`: original work for this project, under the project's license, with nothing to attribute.

`scenes/levels/hotel_miramare.tscn` is built from them by `tools/dress_hotel.gd` (see `tools/README.md`). `scenes/levels/kit_showcase.tscn` lays out a corridor, a guest room, the lobby, a dining room and a basement store, under the game's fog and flashlight: run it (F6 in the editor) to look at the pieces in game.

### Hotel kit

The kit sits on a **2 m grid**, 3 m from floor to ceiling and 3.2 m from floor to floor, like the graybox. Every piece has collision except ceilings, window frames and the pipes overhead.

- **Floors and ceilings** are 2 × 2 m with the origin at their centre: put a floor on each cell and a ceiling 3 m above it.
- **Walls are half walls**, 0.1 m thick, a storey (3.2 m) tall and finished on one face, with the origin at the bottom centre of the back. Turn each to face the room it belongs to, on the grid line: a wall between two rooms is two pieces back to back, so each side gets its own material. A wall reaches the floor above, so a stairwell has no gap between storeys; in a room the ceiling hides its top.
- **`wall_door`** leaves a 1.6 × 2.5 m opening; a `door_frame` centred on the grid line lines it down to the 1.4 × 2.4 m of `scenes/levels/door.tscn`. **`wall_window`** has a 1.2 × 1.4 m opening 0.9 m up, which a `window_frame` on the grid line fills with dark glass.
- **`stairs`** is one 2.8 m wide flight rising half a storey (1.6 m over 2.6 m) towards -Z from the foot of its first riser, walked on as a smooth ramp; **`stair_landing`** is the 2.9 × 1.7 m slab between flights, with the origin at the centre of its top, and **`stair_wall`** the 2.6 m wall between the two flights, finished on both sides. Two flights and two landings side by side fill the graybox's 6 m stairwell.
- **Variants.** Each piece comes in one glTF per material, `<piece>_<material>.gltf`, using the shared materials in `assets/materials/`. UVs are in metres, so textures line up across pieces; each material's `uv1_scale` sets how many metres one repeat covers (a divisor of 2 m).

| Piece | Materials |
|---|---|
| `floor` | `terrazzo`, `carpet`, `floor_tiles`, `concrete_floor` |
| `ceiling` | `ceiling_plaster`, `ceiling_tiles`, `concrete_wall` |
| `wall`, `wall_door`, `wall_window` | `wallpaper`, `painted_wall`, `wall_tiles`, `brick`, `stripped_plaster`, `concrete_wall`, `wood_panelling` |
| `door_frame` | `door` |
| `stairs`, `stair_landing` | `terrazzo`, `concrete_floor` |
| `stair_wall` | `painted_wall`, `concrete_wall` |

The fittings come in one variant each, in flat colours:

| Fitting | What |
|---|---|
| `railing` | 1 m of steel balustrade along X, centred; railings join end to end |
| `window_frame` | Wooden frame and dark glass for `wall_window`'s opening; origin at the bottom centre of the opening |
| `balcony_divider` | Frosted glass screen between balconies, 1.9 m wide and 2 m high |
| `lift_doors` | Steel lift doors in their frame, with the call button; on the face of the shaft's wall |
| `roller_shutter` | Steel roller shutter across a corridor, 2 m wide and 3 m high, down |
| `ceiling_pipes` | Two pipes and a conduit along 2 m of ceiling (X), hanging from the origin |

### Props

Props face +Z (their front towards the viewer in Godot's default view), with the origin at the bottom centre; those hung on a wall have it at the bottom centre of their back. Furniture has a box collider.

| Model | What | Source | Author | License |
|---|---|---|---|---|
| `characters/luca` | Luca's placeholder: a faceless mannequin on a 53-bone rig with 12 clips, 5,879 triangles, flat colours | [Universal Animation Library (Standard)](https://opengameart.org/node/174563) | Quaternius | CC0 |
| `props/bed` | Single bed, 0.9 × 2 m, with linen and a blanket; headboard at -Z | Made by `tools/make_kit.py` | This project | Project's own |
| `props/wardrobe` | Two-door wardrobe, 1 m wide, 2 m tall | Made by `tools/make_kit.py` | This project | Project's own |
| `props/reception_desk` | The porter's desk: a U 3 m wide and 2.2 m deep, open at the back (-Z), so the porter is out of reach | Made by `tools/make_kit.py` | This project | Project's own |
| `props/desk_lamp` | The porter's green banker's lamp | Made by `tools/make_kit.py` | This project | Project's own |
| `props/bedside_lamp` | Bedside lamp with a fabric shade | Made by `tools/make_kit.py` | This project | Project's own |
| `props/ceiling_lamp` | Opal glass ceiling lamp, hanging from its origin at the ceiling | Made by `tools/make_kit.py` | This project | Project's own |
| `props/room_number` | Brass door numbers for rooms 11–16 and 21–28 (`room_number_22`), origin at their back | Made by `tools/make_kit.py` | This project | Project's own |
| `props/sign` | Signs, origin at their centre: `out_of_order` (FUORI SERVIZIO) and `do_not_disturb` (NON DISTURBARE) hang from a cord; `stairs`, `lift`, `reception` and `private` are wall plates | Made by `tools/make_kit.py` | This project | Project's own |
| `props/desk` | Writing desk, 1.4 m wide, drawers on the right: room 22, the back office | Made by `tools/make_kit.py` | This project | Project's own |
| `props/wall_cabinet` | Small white wall cabinet, hung on a wall: bathrooms, the back office | Made by `tools/make_kit.py` | This project | Project's own |
| `props/alarm_clock` | Wind-up alarm clock: room 22's clock (P1) | Made by `tools/make_kit.py` | This project | Project's own |
| `props/coat_stand` | Bentwood coat stand with a coat on it: room 26 | Made by `tools/make_kit.py` | This project | Project's own |
| `props/room_service_tray` | Tray with a covered plate, a glass and a napkin: outside room 26 | Made by `tools/make_kit.py` | This project | Project's own |
| `props/key_cabinet` | Housekeeping key cabinet with a combination lock, hung on a wall (P1) | Made by `tools/make_kit.py` | This project | Project's own |
| `props/key_board` | Board of room keys behind the reception desk, some missing; hung on a wall | Made by `tools/make_kit.py` | This project | Project's own |
| `props/linen_cart` | Housekeeping trolley with linen on top, 1 m high | Made by `tools/make_kit.py` | This project | Project's own |
| `props/scaffolding` | One bay of builders' scaffolding, 2.5 m long, decked at 2.4 m | Made by `tools/make_kit.py` | This project | Project's own |
| `props/rubble_chute` | One 1 m segment of a yellow rubble chute; segments hook into each other | Made by `tools/make_kit.py` | This project | Project's own |
| `props/skip` | Builders' skip full of rubble, 3 × 2 m | Made by `tools/make_kit.py` | This project | Project's own |
| `props/sunbed_stack` | The beach concession's sunbeds stacked on end, with two umbrellas: the obstacle on GF | Made by `tools/make_kit.py` | This project | Project's own |
| `props/kitchen_counter` | 2 m of kitchen cupboards under a steel top; back at the origin | Made by `tools/make_kit.py` | This project | Project's own |
| `props/stove` | Restaurant range with a pot left on it | Made by `tools/make_kit.py` | This project | Project's own |
| `props/hotplate` | Two-ring electric hotplate, for a counter: the staff room | Made by `tools/make_kit.py` | This project | Project's own |
| `props/radio` | Radiogram on short legs: the TV room | Made by `tools/make_kit.py` | This project | Project's own |
| `props/washing_machine` | Industrial front-loading washing machine: the laundry | Made by `tools/make_kit.py` | This project | Project's own |
| `props/hanging_sheet` | Bed sheet pegged on 2 m of washing line, no collider: the laundry | Made by `tools/make_kit.py` | This project | Project's own |
| `props/boiler` | Old boiler drum with a flue to the ceiling: the boiler room | Made by `tools/make_kit.py` | This project | Project's own |
| `props/water_tank` | Tall galvanised expansion tank: the boiler room | Made by `tools/make_kit.py` | This project | Project's own |
| `props/switchboard` | The hotel's main switchboard with its lever, hung on a wall | Made by `tools/make_kit.py` | This project | Project's own |
| `props/wall_button` | Up and down push-button box for the roller shutter, hung on a wall | Made by `tools/make_kit.py` | This project | Project's own |
| `props/locker` | Steel staff locker: `locker_closed`, and `locker_ajar` with the porter's coat inside | Made by `tools/make_kit.py` | This project | Project's own |
| `props/curtain` | Drawn curtain, 1.4 m wide, hanging from its origin at the rail | Made by `tools/make_kit.py` | This project | Project's own |
| `props/painted_chair` | White painted wooden room chair | [Poly Haven: Painted Wooden Chair 01](https://polyhaven.com/a/painted_wooden_chair_01) | Kuutti Siitonen | CC0 |
| `props/nightstand` | Painted wooden nightstand | [Poly Haven: Painted Wooden Nightstand](https://polyhaven.com/a/painted_wooden_nightstand) | Kirill Sannikov | CC0 |
| `props/dining_table` | Long painted wooden table, 2.4 m | [Poly Haven: Painted Wooden Table](https://polyhaven.com/a/painted_wooden_table) | Kirill Sannikov | CC0 |
| `props/cupboard` | Tall painted wooden cupboard: linen room, kitchen | [Poly Haven: Painted Wooden Cabinet 02](https://polyhaven.com/a/painted_wooden_cabinet_02) | Kirill Sannikov | CC0 |
| `props/shelves` | Small painted wooden shelves | [Poly Haven: Painted Wooden Shelves](https://polyhaven.com/a/painted_wooden_shelves) | Kirill Sannikov | CC0 |
| `props/sofa` | Fabric sofa: TV room, lobby | [Poly Haven: Sofa 02](https://polyhaven.com/a/sofa_02) | Kirill Sannikov | CC0 |
| `props/armchair` | Mid-century lounge chair: lobby | [Poly Haven: Mid Century Lounge Chair](https://polyhaven.com/a/mid_century_lounge_chair) | Kuutti Siitonen | CC0 |
| `props/television` | Old CRT television: room 24, TV room | [Poly Haven: Television 02](https://polyhaven.com/a/television_02) | Benny Weimer | CC0 |
| `props/wall_clock` | Round wall clock, no collider: the clock wall, room 22's clock | [Poly Haven: Wall Clock](https://polyhaven.com/a/wall_clock) | PierreB3D | CC0 |
| `props/steel_shelves` | Steel frame shelves: basement stores | [Poly Haven: Steel Frame Shelves 01](https://polyhaven.com/a/steel_frame_shelves_01) | James Ray Cock | CC0 |

## Textures and materials

The hotel's environment textures are CC0 photo textures, chosen from a contact sheet of candidates and fitted by the asset pipeline (`tools/README.md`): downscaled to 256 or 512 px with power-of-two sides, the source's ambient occlusion baked into the colour where it has one, and desaturated to 80% so a material tint can bring them to the palette. Each is `assets/textures/<name>.jpg`, imported VRAM compressed with mipmaps, with its entry in `sources.json` (`tools/build_assets.py <name>` rebuilds it).

Each texture has a shared material in `assets/materials/<name>.tres`: a `StandardMaterial3D` with only the albedo texture, a constant roughness per surface, and trilinear anisotropic filtering, which the retro filter (#100) turns off through the viewport. The tint (`albedo_color`) is white for now. The per-floor colours of the palette in `docs/design/visual-style.md` come with dressing the hotel (#112), as tinted copies of these materials. A tint only darkens, which is why the wallpaper was lifted to a light grey with `--levels`.

| Texture | What | px | Source | Author | License |
|---|---|---|---|---|---|
| `terrazzo` | Terrazzo floor: corridors and lobby | 512 | [ambientCG: Terrazzo011](https://ambientcg.com/a/Terrazzo011) | ambientCG | CC0 |
| `carpet` | Guest room carpet | 512 | [ambientCG: Carpet013](https://ambientcg.com/a/Carpet013) | ambientCG | CC0 |
| `floor_tiles` | Terracotta floor tiles: kitchen, bathrooms, staff room | 256 | [ambientCG: Tiles027](https://ambientcg.com/a/Tiles027) | ambientCG | CC0 |
| `concrete_floor` | Basement floor | 512 | [ambientCG: Concrete047A](https://ambientcg.com/a/Concrete047A) | ambientCG | CC0 |
| `painted_wall` | Painted plaster wall: rooms and corridors | 512 | [ambientCG: Concrete046](https://ambientcg.com/a/Concrete046) | ambientCG | CC0 |
| `wallpaper` | Damask wallpaper: guest rooms (lifted to light grey for tinting) | 512 | [Poly Haven: floral_jacquard](https://polyhaven.com/a/floral_jacquard) | Rico Cilliers, photographed by colormass | CC0 |
| `wall_tiles` | Small square wall tiles: kitchen and bathrooms | 256 | [ambientCG: Tiles133A](https://ambientcg.com/a/Tiles133A) | ambientCG | CC0 |
| `brick` | Bare brick: building sites | 512 | [ambientCG: Bricks085](https://ambientcg.com/a/Bricks085) | ambientCG | CC0 |
| `stripped_plaster` | Plaster stripped to the brick: building sites | 512 | [ambientCG: PaintedPlaster014](https://ambientcg.com/a/PaintedPlaster014) | ambientCG | CC0 |
| `concrete_wall` | Basement walls | 512 | [ambientCG: Concrete036](https://ambientcg.com/a/Concrete036) | ambientCG | CC0 |
| `wood_panelling` | Wood panelling: reception desk and lobby | 256 | [ambientCG: Wood030](https://ambientcg.com/a/Wood030) | ambientCG | CC0 |
| `door` | Door veneer | 256 | [ambientCG: Wood023](https://ambientcg.com/a/Wood023) | ambientCG | CC0 |
| `ceiling_plaster` | Stucco ceiling: rooms and corridors | 256 | [ambientCG: Plaster003](https://ambientcg.com/a/Plaster003) | ambientCG | CC0 |
| `ceiling_tiles` | Suspended ceiling tiles: lobby and dining room | 256 | [ambientCG: OfficeCeiling001](https://ambientcg.com/a/OfficeCeiling001) | ambientCG | CC0 |

The wallpaper's source is 2:3; it is stored at 256×512, so map it 2:3 to keep the damask's proportions.

## Audio

Audio buses are defined in `default_bus_layout.tres` (`Music`, `Ambience`, `SFX`, `UI`, each sending to `Master`); their names are constants in `scripts/audio/audio_buses.gd`.

All current sounds are **generated placeholders, not recorded or downloaded audio**. `tools/generate_placeholder_audio.gd` synthesizes them from seeded noise and sine waves and writes the WAV files in `assets/audio/`. Run it with `godot --headless --path . --script res://tools/generate_placeholder_audio.gd` to regenerate (then re-import; `ambience_drone.wav.import` keeps `edit/loop_mode=2` so it loops).

| File | What | Source | License |
|---|---|---|---|
| `footstep_1.wav`, `footstep_2.wav`, `footstep_3.wav` | Dull footstep thumps (lowpassed noise plus a low sine) | Generated by `tools/generate_placeholder_audio.gd` | Original work for this project, no third-party content; nothing to attribute |
| `ambience_drone.wav` | 16 s seamless looping dark drone | Generated by `tools/generate_placeholder_audio.gd` | Same |
| `heartbeat.wav` | A "lub-dub" heartbeat (two low sine thumps), played in the Danger health state | Generated by `tools/generate_placeholder_audio.gd` | Same |
| `breath_heavy.wav` | One heavy breath (filtered noise), played now and then in the Caution health state | Generated by `tools/generate_placeholder_audio.gd` | Same |

Footsteps are triggered by `emit_footstep()` method tracks in the `walk` and `run` animations (added by `tools/generate_player_model.gd`, at the frames a foot lands). If the character's animations are replaced, add equivalent method tracks at the foot-contact frames.

Replace these with real recordings or CC0 audio (for example CC0 uploads on freesound.org, checking each file's license) before release, and record the source and license of each new file in this table.
