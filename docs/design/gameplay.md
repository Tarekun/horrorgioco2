# Gameplay spec

The reference for the core gameplay systems: movement, camera, combat, resources and saving. Story, setting and pillars live in [premise.md](premise.md).

Every number here is a **starting value**, not a final one. Implementations expose them as `@export` variables or resources so they can be tuned without code changes. If you change a rule (not just a number), update this document in the same PR.

## Summary

- Free third-person movement relative to the camera (no tank controls), with an over-the-shoulder camera.
- Melee is free but risky: a light combo and a charged heavy attack, with a few unbreakable weapons.
- Firearms (pistol, shotgun) use **lock-on aiming with a chance to miss**. Ammo is scarce and gunfire is loud.
- Downed enemies get back up unless the player stomps them.
- **No HUD.** Health and stamina come through the screen, audio and rumble; the inventory screen shows a status readout.
- Unlimited inventory. Scarcity comes only from hand-placed pickups; enemies and pickups never respawn.
- The inventory screen pauses the game.
- **Save only at save spots**, as often as you like. On death you go back to your last save.

## Movement

The player is a `CharacterBody3D` that moves relative to the camera's yaw. Stick input is analog; keyboard input is always full magnitude.

| Mode | Speed | Notes |
|---|---|---|
| Walk | 1.5 m/s | Stick tilted less than 50%. The keyboard has no walk key. |
| Run | 3.5 m/s | Default at full input. |
| Sprint | 5.5 m/s | Hold `sprint` while moving. Drains stamina. |
| Aim walk | 1.2 m/s | While aiming a firearm the player strafes, facing the target. |

- The character turns smoothly toward the movement direction at up to 720°/s. When idle, it keeps its last facing.
- Gravity applies. Step height 0.35 m, maximum walkable slope 45°.
- No jump and no crouch: levels control traversal.
- **Danger state** (see Health): every speed is multiplied by 0.8 and a limp animation layer is blended in.
- Attacking, dodging or aiming stops a sprint.
- `interact` uses the nearest interactable within 1.5 m in front of the player. A subtle prompt appears only when one is in range.

## Camera

Over the right shoulder, on a `SpringArm3D` so it never clips through walls.

| Parameter | Default | Aiming |
|---|---|---|
| Arm length | 2.2 m | 1.4 m |
| Shoulder offset (right, up) | 0.5 m, 1.6 m | 0.6 m, 1.55 m |
| FOV | 70° | 60° |
| Pitch limits | -60° to +50° | same |

- The player orbits with mouse motion or the right stick (`look_*` actions), with separate mouse and stick sensitivities and an invert-Y option in settings.
- Camera position follows the player with light smoothing (about 0.1 s). Rotation responds to input without smoothing.
- No auto-recentering while moving; there's a tunable to enable it later.
- The flashlight follows the camera aim (#16). While aiming, it points at the locked target.
- Transitions into and out of aim blend over 0.2 s.
- Entering aim with a target: the camera turns over 0.25 s to frame the player and the target. While locked, it keeps tracking the target and look input nudges it by at most ±10°.

## Stamina

One pool shared by sprinting and combat (#13). Firearms never cost stamina.

| Parameter | Value |
|---|---|
| Max | 100 |
| Regeneration | 25/s, starting 0.8 s after the last stamina use |
| Sprint drain | 15/s |
| Exhausted | At 0, the player can't sprint, dodge or start an action that costs stamina until stamina is back above 30. |

An action needs its full cost available; otherwise it doesn't start. There's no stamina bar: low stamina shows as heavier breathing (silent above 70%, louder and faster towards 0, calming slowly as it regenerates), and exhaustion as a short winded animation (0.9 s, with a gasp). The player can't move while winded. If the exhaustion comes while another action drives the body (the end of a dodge or attack, a stagger), the winded animation is skipped.

## Melee combat

### Moveset

- **Light combo**: press `attack`. Up to 3 hits. A press during the last 40% of a swing queues the next hit. The 3rd hit is slower and stronger.
- **Heavy attack**: hold `attack` for 0.35 s to start charging, and release to swing. Charge is full at 1.0 s; releasing earlier scales damage from 60% to 100%. A fully charged heavy hit knocks down a standard enemy.
- **Soft targeting**: when a swing starts, the player turns toward the nearest enemy within 2.5 m and 60° of the input direction (or of the facing direction, with no input). There's no melee lock-on.
- **Hits**: each swing has an active hitbox window and damages each target at most once per swing (#22). Every hit staggers a standard enemy, interrupting its attack. Add 0.05 s of hitstop on contact.
- **Cancels**: after a swing's active window ends, its recovery can be cancelled into a dodge.

### Weapons

The player holds one melee weapon at a time, equipped from the inventory. Melee weapons **never break**. The names are placeholders until the narrative is set.

| Weapon | Light damage (1 / 2 / 3) | Heavy (full charge) | Stamina (light / heavy) | Reach | Speed | Where |
|---|---|---|---|---|---|---|
| Wooden plank | 8 / 8 / 12 | 25 | 10 / 20 | 1.6 m | fast | start |
| Steel pipe | 12 / 12 / 18 | 35 | 12 / 25 | 1.8 m | medium | early |
| Fire axe | 18 / 26 (2-hit combo) | 50 | 18 / 35 | 1.9 m | slow | midgame |

### Dodge

- Press `dodge` to dodge in the input direction, or to backstep with no input.
- Distance 2.5 m (backstep 1.5 m). Total duration 0.5 s, of which the first 0.25 s is invulnerable.
- Costs 20 stamina. After a dodge ends, there's a 0.2 s cooldown before the next one.
- Dodging cancels aiming. Holding `aim` re-acquires the target afterwards.

### Downed enemies and finishers

- A standard enemy at 0 health falls down (#28). It gets up after 8 s (±2 s random) with 40% health, unless finished.
- A fully charged heavy hit also knocks a standard enemy down, without touching its health: it gets up after the same delay with the health it had. A downed enemy can't be staggered, and doesn't hear or attack.
- Pressing `attack` within 1.2 m of a downed enemy performs a **stomp** instead of a swing. The stomp takes 0.8 s, costs no stamina, kills the enemy for good and leaves the player exposed.
- Bullets damage downed enemies normally, so shooting one is allowed but wastes ammo.
- Dead enemies stay as corpses and are recorded in saves.

## Firearms

Two firearms: the **pistol** (found early) and the **shotgun** (found mid-game). Each uses its own ammo type. One weapon is equipped at a time, melee or firearm. `switch_weapon` toggles between the last equipped melee weapon and the last equipped firearm; anything else is equipped from the inventory.

### Aiming: lock-on

- Hold `aim` to raise the firearm. The player locks onto the best target: the nearest enemy that is visible (line of sight), within weapon range and inside a 70° cone in front of the camera. Standing enemies are preferred over downed ones.
- `next_target` cycles to the next valid target, ordered by angle.
- With no valid target, the player aims straight along the camera's forward direction. Shots still hit whatever the ray meets.
- Fire with `attack` while aiming.
- With a firearm equipped but not aiming, `attack` performs a **shove**: 5 damage, a stagger and a short knockback, costing 15 stamina. It's for making space, not killing.

### Hit chance

Lock-on picks the target, and every shot rolls against a hit chance. A miss is visible: the shot strikes the environment near the target (a spark or decal) and never the target itself. The rule, with no aim skill involved:

```
p = base(distance) × steadiness × modifiers, clamped to [0.05, 0.95]
```

- **`base(distance)`** interpolates linearly from the near chance (at or inside the near distance) to the far chance (at the far distance). Beyond the maximum range, `p = 0`.
- **Steadiness** starts at `steady_min` when a target is acquired and rises linearly to 1.0 over `steady_time`. Each shot subtracts `recoil` (floored at `steady_min`), and switching targets resets it. So waiting before shooting improves accuracy, and firing rapidly lowers it.
- **Modifiers**, multiplied together:

  | Condition | Multiplier |
  |---|---|
  | Player is moving | ×0.75 |
  | Target is moving | ×0.85 |
  | Target is staggered or downed | ×1.15 |
  | Player is in Danger health | ×0.85 |
  | Player is exhausted (stamina) | ×0.85 |

- The clamp means **no shot is ever guaranteed**, and none is hopeless inside the maximum range.
- **Feedback**: a thin ring around the locked target tightens and brightens as `p` rises. No percentages are shown.
- The hit-chance calculation is a pure function, and the random number generator is injected so that GUT tests are deterministic.

### Weapon stats

| | Pistol | Shotgun |
|---|---|---|
| Damage | 20 per shot | 8 pellets × 8 |
| Hit roll | once per shot | once per pellet |
| Near / far chance | 0.90 at 4 m / 0.35 at 20 m | 0.90 at 3 m / 0.15 at 12 m |
| Maximum range | 25 m | 15 m |
| `steady_min` / `steady_time` / `recoil` | 0.75 / 0.8 s / 0.15 | 0.80 / 0.6 s / 0.30 |
| Time between shots | 0.35 s | 1.0 s (pump) |
| Magazine | 10 | 6 |
| Reload | 1.4 s for a full magazine | 0.6 s per shell, can be interrupted |
| Noise radius | 25 m | 30 m |
| Special | none | 5 or more pellets hitting a standard enemy knock it down |

For reference, a standard enemy has 100 health. That's about 5 pistol hits, or 2 close shotgun blasts.

- **Reloading** happens only in real time: press `reload`, or try to fire with an empty magazine while ammo is in reserve. The inventory screen can't reload, because it pauses the game and would make reloads free.
- Ammo in the magazine and in reserve is tracked separately and saved.
- While aiming, a small magazine count appears next to the reticle. Nothing is shown when not aiming.

### Noise

Noise events feed enemy hearing (#27). Gunshots are the loudest thing the player can do: shooting trades ammo and safety for kill speed.

| Source | Radius |
|---|---|
| Pistol / shotgun shot | 25 m / 30 m |
| Melee hit | 8 m |
| Sprint footsteps | 6 m |
| Walk / run footsteps | 0 m / 3 m |

### Enemy perception

A standard enemy notices the player by sight or by sound (#27). Values are `@export` starting values on `EnemyPerception`.

- **Sight**: a 110° cone (55° each side) out to 10 m, with an unobstructed line from the enemy's eyes to the player. With the flashlight on, the range is ×1.8 (18 m). Within 1.5 m the player is noticed from any direction.
- **Hearing**: a noise alerts every enemy within its radius to where it came from.
- **Alert**: the enemy chases the player while it sees them, or goes to the last place it saw or heard them. After 6 s without a sighting or a noise it loses track and goes back to wandering. Being hit alerts it to the attacker.

## Health and healing

- The player has 100 max health and **no natural regeneration**. A standard enemy hit deals 15–25.
- Health has three states. Each state has cues; there are never numbers or bars on screen:

  | State | Health | Cues |
  |---|---|---|
  | Fine | 60–100 | none |
  | Caution | 30–59 | faint edge vignette, occasional heavy breath |
  | Danger | 1–29 | strong vignette and desaturation, heartbeat audio and gamepad rumble pulse, limp (×0.8 speed), aim penalty |

- **Getting hit** (#24): a stagger animation, a red flash at the screen edge, a short camera shake and a rumble.
- The inventory screen shows the state as a descriptive status readout (for example an ECG line and the words Fine / Caution / Danger), never as a number.
- **Healing items** are used from the inventory. Since the inventory pauses the game, using one is instant and safe. A healing item can't be used at full health: the screen says so and the item is kept.

  | Item | Effect |
  |---|---|
  | Health drink | +30 |
  | First aid kit | +70 |
  | Ampoule | full heal |

- At 0 health the player dies and the game is over (see Saving).

## Resources and inventory

- **No inventory limit.** Every item stacks without limit, so scarcity comes entirely from what is placed in the world.
- The inventory screen **pauses the game**. It has these categories: weapons, ammo, healing, key items, documents. Actions: equip, use, examine. There's no crafting or combining of resources; any combining of puzzle items belongs to #33.
- **Hand-placed only**: all ammo and healing are placed by hand in levels. Enemies drop nothing. Enemies and pickups never respawn, so the total supply of a level is fixed and known.
- Pickups have a faint glint and are picked up with `interact`. A typical pickup: 8 pistol rounds, 4 shotgun shells, or 1 healing item.
- **Budget guideline** for level designers, per area:
  - The damage from all placed ammo should be about **60%** of the total health of the area's enemies. The player can't shoot everything, so melee, stomps and avoidance are expected.
  - Healing should cover about the damage of **4–6 enemy hits** between save spots.
- The flashlight has unlimited battery. It isn't a resource; its cost is that it gets you noticed (#27).
- There's one difficulty for now. All scarcity values (pickup amounts, enemy health and damage, the hit-chance clamp) live in one resource, `assets/data/scarcity.tres` (`Scarcity`), so difficulty presets can scale them later. A pickup holds its item's standard amount from that resource, times a bundle count for bigger stashes.

## Saving

- You can save **only at save spots**: fixed, visually distinct objects in the world. Their look is decided in the art and narrative work. Use one with `interact` to open the save screen, which pauses the game.
- Saves are **unlimited** and cost nothing. Save spots don't heal.
- You can't save while any enemy is chasing the player. The save spot shows a short refusal message instead.
- There are 8 manual save slots and no autosave. Each slot shows the area name, the play time and a timestamp.
- **A save stores:**
  - the player's health, inventory, ammo (magazine and reserve), equipped weapons and flashlight state
  - which save spot was used (loading puts the player there)
  - the world state: collected pickups, unlocked doors, puzzle states, documents read, and which enemies are dead (with their corpse positions)
- Enemies still alive in a save come back at their placed positions with full health when it's loaded.
- **On death**, the game over screen offers:
  - **Load last save**: the most recent save written or loaded this session.
  - **Load game…**: pick any slot.
  - **Quit to title.**

  If the player hasn't saved yet, "Load last save" restarts the game from its starting state. Scripted story deaths, such as the end of part 1's prologue (see [premise.md](premise.md)), are cutscenes, not game overs. There are no hidden checkpoints, so death costs everything since the last save. Note that #24's "retry reloads the level" is replaced by this.
- **Spacing guideline**: no more than about 15 minutes of normal play between save spots. Always place one before a major encounter, and never place one where the player can be trapped by enemies.

## Input actions

The current input map (#2) covers movement, look, `sprint`, `attack`, `dodge`, `interact`, `flashlight` and `pause`. This spec needs five more. The bindings below are proposals; the tasks that implement these features finalize them.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| `aim` | Right mouse button | Left trigger |
| `reload` | R | X / Square |
| `next_target` | Mouse wheel / Tab | Right bumper |
| `switch_weapon` | Q | D-pad up |
| `inventory` | I | Back / Select |

## Out of scope

The following are left to their own epics and tasks: the map, puzzles and key-item combining (#33), the inventory and menu screens (#32, #35), bosses, difficulty presets, and enemy types beyond the standard enemy (#25). A radio that crackles with static when enemies are near would fit the genre and is worth considering alongside enemy perception (#27).
