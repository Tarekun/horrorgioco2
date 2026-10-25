# assets/

Source assets imported by Godot: models, textures, materials, audio and fonts.
Organize by type (e.g. `assets/models/`, `assets/textures/`, `assets/audio/`); data resources (`.tres`) go in `assets/data/`.

Commit the `.import` files Godot generates next to each asset; the imported data itself lives in `.godot/` and is not committed.

## Placeholder character

The player's stand-in humanoid is **not an imported asset**: `tools/generate_placeholder_character.gd` builds it from primitive shapes (boxes, capsules, a sphere) on a 15-bone skeleton, with procedural idle, walk and run animations, and writes `scenes/player/player_model.tscn`. Run it with `godot --headless --path . --script res://tools/generate_placeholder_character.gd` to regenerate.

- **Source:** original work for this project, no third-party content.
- **License:** the same as the project; nothing to attribute.
- **Replacing it:** swap in the final rigged model keeping the bone names, or retarget the `idle`, `walk` and `run` animations. The `AnimationTree` blend space (idle 0, walk 1.5, run 3.5, sprint 5.5 m/s) is driven by `PlayerModel.set_speed()`.

The generator also builds the action clips (`attack_light_1` to `3`, `attack_heavy_charge`, `attack_heavy_swing`, `dodge`, `backstep`, `hit`, `death`) as states of the `AnimationTree` state machine beside the `locomotion` blend space, and a wooden plank held in the right hand. `PlayerModel.play_action()` jumps to a clip and `return_to_locomotion()` goes back. Clip lengths match the default `MeleeWeapon` timings (`assets/data/weapons/wooden_plank.tres`); keep them in step when tuning.

Record the source and license of every imported asset here, as the visual style doc requires.
