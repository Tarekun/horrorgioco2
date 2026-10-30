# Vertical slice: Hotel Miramare

The reference for building the slice: layout, beats, tension, items, save spots, documents and the puzzle. Story and pillars live in [premise.md](premise.md), rules and numbers in [gameplay.md](gameplay.md), the look in [visual-style.md](visual-style.md).

Names marked *working* are placeholders, as in premise.md. Ids in `code` are the ones the implementation uses (item ids for #73, persistent ids for #89).

## Summary

- **Starts** at a new game with Luca waking in room 22, their old room. **Ends** when he unlocks the front door himself and steps out onto the seafront in the fog.
- **The whole hotel, three floors:** **2F**, where their room is, lit and empty; **1F**, dark; and **GF**, with the dining room, kitchen and the lobby. There's nothing above 2F.
- **The loop:**
  - pull the plank off a doorless room on 2F to get a weapon and the stairs key;
  - go down to the dark 1F; the stairs don't go further, because the GF door is blocked;
  - slide down a builders' rubble chute from a building site on 1F to GF, and move the obstacle blocking the stairs;
  - the porter won't open the front door; the clue to the key cabinet sends Luca back up;
  - he solves the cabinet on 1F, comes back down, finds the porter gone and lets himself out.
- **No enemies.** The slice is all tension that never pays off: sounds, lights and things out of place, and nothing ever attacks. That also makes a night porter calmly on duty plausible. Enemies come later with a basement section; its door is already in the slice, chained.
- **Two save spots**, about 30 minutes of play on a first run.

What's not in the slice: enemies and combat encounters, firearms, the prologue (the rave night), the crossovers with part 2, the fire axe (a midgame weapon), other locals, any other location.

## The hotel

A family hotel on the seafront, built in the 1960s and redone in the 80s: terrazzo floors, wood-panelled reception, pastel tiles, brass room numbers. It has three floors: GF (ground floor), 1F (first floor) and 2F (second floor). **The hotel is closed**: the season is over, there are no guests, and the porter says so. The sunbeds and umbrellas from its beach concession are stacked inside for the winter.

- **One staircase**, at the west end of the corridor on every floor, behind a door. The middle of each floor is a lift hall with a lift that doesn't work.
- **Two rooms are building sites**: room 15 on 1F and the room right below it on GF, joined by a yellow rubble chute. Nothing else in the hotel is being worked on, and nothing says why these two are.

**Lighting by floor:**
- **2F:** all the lamps are on, warm and steady. It looks open for business, and it's empty.
- **1F:** every lamp is off. The flashlight is the only light.
- **GF:** dark, except the porter's desk lamp in the lobby.

Outside the windows it's a dusk that doesn't match any clock. Every clock in the hotel shows a different time, except one (see [the puzzle](#the-puzzle-the-key-cabinet)).

Dimensions below are approximate, for the graybox (#70). Every floor has the same footprint, about 30 × 14 m, with 6 × 6 m rooms, a 2 m corridor and 3 m ceilings. The staircase, the lift and the two building sites line up across the floors.

## Floor plans

North is the sea. Codes are explained in the [legend](#legend) below the plans.

### 2F (lit)

```
                   north: balconies over the seafront, fog
 0m          6m          12m         18m         24m         30m
 ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 │ROOM 28    │ROOM 26    │ROOM 24    │LIFT HALL  │ROOM 22    │
 │no door,   │lamp off,  │"do not    │           │START      │
 │plank      │coat by the│ disturb"  │lift doors,│h  D1      │
 │across: K1 │window     │TV, song   │out of     │clock (P1) │
 │           │tray (door)│           │order      │balcony    │
 ├────=W=────┼────   ────┼────▒▒▒────┤           ├────   ────┤
 │ window   S1   corridor (lights on)                      → │
 ├────▒▒▒────┼────▒▒▒────┼────▒▒▒────┼───────────┼────   ────┤
 │STAIRS     │ROOM 25    │ROOM 23    │plumbing   │ROOM 21    │
 │ ↓ 1F, GF  │locked     │locked,    │(solid)    │door ajar, │
 │           │           │phone      │           │shower     │
 │           │           │ringing    │           │running    │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **Room 22** is the corner room facing the sea, with a small balcony. Frosted dividers close it off from the neighbours' balconies.
- **Room 28** has no door, only an empty frame with a plank nailed across it at chest height ([the blockade](#the-blockade)). Inside: the stairs key (K1) on a chair in the middle of the empty room, facing the window.
- **The stairs door** at the west end is locked; K1 opens it.
- **Lift hall**: the lift's doors are shut, with an *out of order* sign.
- **Room 24** never opens. A TV is on behind the door, playing the slowed Italo-disco song from the rave.
- **Room 26** is the one room on the floor with its lamp off. A room-service tray sits outside its door.
- **Room 21** is open, as if a guest just stepped out. Rooms 23 and 25 are locked, with no key in the slice.
- **The corridor's west end** is a window, open a crack, its curtain stirring.

### 1F (dark)

```
                   north: balconies over the seafront, fog
 0m          6m          12m         18m         24m         30m
 ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 │LINEN ROOM │ROOM 16    │ROOM 14    │LIFT HALL  │ROOM 12    │
 │key cabinet│           │locked     │           │laid out   │
 │(P1)  h    │D4         │           │lift doors,│like 22,   │
 │D2         │           │           │out of     │beds       │
 │           │           │           │order      │stripped   │
 ├────   ────┼────▒▒▒────┼────▒▒▒────┤           ├────   ────┤
 │ corridor (lights off)                                   → │
 ├────▒▒▒────┼────   ────┼────   ────┼───────────┼────▒▒▒────┤
 │STAIRS     │ROOM 15    │ROOM 13    │plumbing   │ROOM 11    │
 │ ↑ 2F      │BUILDING   │wardrobe   │(solid)    │locked,    │
 │ ↓ GF      │SITE: W,   │creaks open│           │no key     │
 │           │chute ↓ GF │           │           │           │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **The stairs door** is locked too, and opens with the same K1.
- **Linen room**: the housekeeping key cabinet (P1), locked with a combination. It's found early and opened late.
- **Room 15** is a building site, the only one upstairs: plaster stripped to the brick, scaffolding, dust sheets, a work lamp that's off. A yellow rubble chute runs from a hole in the floor down to GF ([the chute](#the-chute)). The steel pipe lies among the scaffolding.
- **Room 12**, right under their room, has the same furniture in the same places, with the beds stripped and the mattresses rolled up.
- **Room 13** is open. Rooms 11 and 14 are locked with no key in the slice; room 16 opens with K2.

### GF

```
                   north: the seafront (lungomare), fog
 0m          6m          12m         18m         24m         30m
 ┌───────────────────────────────────┬──────────────▒▒▒──────┐
 │DINING ROOM                        │LOBBY     front door K3│
 │tables set for the last dinner,    │lift doors  clock wall │
 │chairs pushed back                 │           key board K2│
 │                                    glass doors     S2     │
 │                                   │  ┌── desk ──┐  lamp   │
 ├─────────────────   ───────────────┤  └─ PORTER ─┘         │
 │ sunbeds   corridor  →                                     │
 ├────≡≡≡────┬────   ────┬────   ────┼────   ────┬────   ────┤
 │STAIRS     │BUILDING   │KITCHEN    │BACK OFFICE│TV ROOM    │
 │ ↑ 1F, 2F  │SITE: skip,│a pot on   │D3  H      │radio, song│
 │ ↓ basement│chute from │the stove  │           │           │
 │   ▒▒▒     │above      │           │           │           │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **The stairs door** won't open from the stairs: a tall stack of sunbeds stands against it in the corridor. From the corridor side the stack can be pushed aside ([the obstacle](#the-obstacle)), which opens the stairs for good: the shortcut between GF and the floors above.
- **Building site**: the room below room 15. Bare walls, a builders' skip full of rubble and dust sheets, the chute's mouth hanging over it from a hole in the ceiling. Its door opens onto the corridor, a few steps from the sunbeds.
- **Corridor**: runs from the stairs door to the lobby, with doors to the building site, the kitchen and the dining room.
- **Dining room**: a door from the corridor, glass double doors to the lobby.
- **Lobby**: the lift doors, a wall of clocks for foreign tourists' cities (all showing different times), the key board behind the desk, the reception desk with the porter behind it under his lamp, and the front door, locked.
- **The desk** is at least 2 m deep, so the porter is out of melee reach from the lobby side (longest reach 1.9 m). Nobody can hit him, and nothing explains why.
- **Back office**: reached from the lobby through the door behind the desk.
- **TV room**: an optional side room with a radio playing the song.
- **Below GF** the stairs go on down to the basement door, chained shut. It's the hook for the basement section with the monsters, designed later; in the slice it never opens. It can be reached from 1F before GF is, since only the GF door is blocked.

### Legend

| Code | Meaning |
|---|---|
| `   ` (gap in a wall) | Doorway with an unlocked door |
| `▒▒▒` | Locked door (key shown next to it or in the table below) |
| `=W=` | Doorless doorway with a plank across it: [the blockade](#the-blockade) |
| `≡≡≡` | Door blocked by an obstacle on the corridor side: [the obstacle](#the-obstacle) |
| ↑ ↓ | Stairs up or down |
| S1, S2 | Save spots |
| K1–K3 | Key items |
| D1–D4 | Documents |
| P1 | The puzzle: the key cabinet (1F linen room) and its code (the clock in room 22) |
| W | Melee weapon: the plank at room 28, the steel pipe in room 15 |
| h, H | Health drink, first aid kit |

## Locks, keys and shortcuts

| Id | Where | State | Opens with |
|---|---|---|---|
| `door_room_21` | Room 21, 2F | unlocked, ajar | |
| `door_room_22` | Room 22, 2F | unlocked | |
| `door_room_23` | Room 23, 2F | locked | nothing |
| `door_room_24` | Room 24, 2F | locked | nothing ("Do not disturb.") |
| `door_room_25` | Room 25, 2F | locked | nothing |
| `door_room_26` | Room 26, 2F | unlocked | |
| `blockade_room_28` | Room 28, 2F (no door) | plank across the doorway | `interact`: takes the plank ([the blockade](#the-blockade)) |
| `door_stairs_2f` | Stairs, 2F | locked | `key_stairs` (K1) |
| `door_linen_room` | Linen room, 1F | unlocked | |
| `door_room_11` | Room 11, 1F | locked | nothing |
| `door_room_12` | Room 12, 1F | unlocked | |
| `door_room_13` | Room 13, 1F | unlocked | |
| `door_room_14` | Room 14, 1F | locked | nothing |
| `door_room_15` | Room 15 (building site), 1F | unlocked, propped open | |
| `door_room_16` | Room 16, 1F | locked | `key_room_16` (K2) |
| `door_stairs_1f` | Stairs, 1F | locked | `key_stairs` (K1) |
| `door_stairs_gf` | Stairs, GF | blocked from the corridor side | moving `obstacle_sunbeds` ([the obstacle](#the-obstacle)) |
| `door_basement` | Stairs, below GF | locked ("Chained shut.") | nothing in the slice |
| `door_building_site_gf` | Building site ↔ corridor, GF | unlocked | |
| `door_kitchen` | Kitchen ↔ corridor, GF | unlocked | |
| `door_dining_corridor` | Dining room ↔ corridor, GF | unlocked | |
| `door_dining_lobby` | Dining room ↔ lobby (glass, double), GF | unlocked | |
| `door_office_lobby` | Back office ↔ lobby, behind the desk | unlocked | |
| `door_tv_room` | TV room ↔ lobby | unlocked | |
| `door_front` | Lobby ↔ seafront | locked | `key_front_door` (K3), ends the slice |

Locked doors with no key answer "It's locked." unless the table gives another line.

**Progression.**
1. The blockade gives the plank and K1.
2. K1 opens the stairs on 2F and 1F.
3. The chute takes Luca from 1F to GF, and the obstacle then opens the stairs on GF.
4. P1 needs the code from room 22, and solving it gives K3.
5. K3 ends the slice.

K2 and room 16 are optional.

### The blockade

Room 28's doorway has no door, only a plank nailed across it. Its prompt reads *"Pull the plank off."* Interacting does two things at once:

- Luca gets the plank, the `wooden_plank` weapon. It's his first weapon, equipped straight away.
- The doorway opens and room 28 can be entered. K1 is inside.

Saved like a pickup: once taken, the plank is gone from the doorway for good.

### The chute

A yellow plastic rubble chute, the kind builders hang from scaffolding to drop debris into a skip. In room 15 it hangs into a hole in the floor; on GF its mouth hangs over a skip in the building site.

- **Prompt:** *"Slide down."* Interacting plays a short in-engine sequence (#95): Luca climbs in, the screen goes dark with the noise of the slide, and he lands in the rubble in the skip on GF.
- **One way only.** From GF the chute is too steep to climb (*"No way back up that."*).
- **No softlock.** The way back up is the stairs, once the obstacle is moved. The building site's door opens onto the corridor right next to the sunbeds, so the player sees the obstacle straight away.
- It stays usable, so sliding again later is allowed.

### The obstacle

On GF a tall stack of sunbeds on a wheeled storage rack stands against the stairs door, in the corridor.

- **From the stairs side**, the door gives a centimetre and stops: *"Something heavy on the other side."*
- **From the corridor**, the stack is an interactable: *"Push the sunbeds aside."* It rolls clear (a short animation), and `door_stairs_gf` works as a normal unlocked door from then on.
- Saved like an unlocked door.

## Beat sheet

Times are rough for a first run.

| # | Beat | Where | What happens | Owner | Time |
|---|---|---|---|---|---|
| 1 | **Awakening** | Room 22 | Cutscene. Luca wakes on the bed in his clothes from the rave, wristband still on. Two single beds pushed together into a double, one side slept in, the other made. Balcony door open, fog, the sea. The lamps are on; outside it's dusk. He doesn't know how he got here. Control is handed over in the room. | #96 | 1 min |
| 2 | **The old room** | Room 22 | Free exploration and the interaction tutorial. A health drink in the bathroom cabinet, the registration card on the desk (D1). Examinables: his phone (no signal), the wristband, an empty, dust-free spot on the nightstand where something used to stand. | #70, #71, #79 | 2 min |
| 3 | **The lit floor** | 2F | A warm, lit, ordinary hotel corridor with nobody in it: room 21's shower running, the phone ringing in 23, the TV in 24, the tray outside 26 and the figure in its window, the stirring curtain ([Tension](#tension)). None of it leads anywhere. The stairs door is locked. First save spot (S1) by the stairs. | #70 | 3 min |
| 4 | **The blockade** | Room 28 | A doorless room with a plank across the doorway. Pulling the plank off arms Luca and opens the room. K1 sits on a chair facing the window. | #71 | 1 min |
| 5 | **Into the dark** | Stairs, 1F | K1 opens the stairs. The 2F lamps flicker once behind him, and stay on. One floor down, K1 opens the 1F door too; below that, the GF door won't open. Further down, the chained basement door. 1F is pitch dark: flashlight on. Footsteps cross the floor above, the one he just left empty. Room 12 is their room again, stripped. Room 13's wardrobe. The linen room: a drink, the lost-property ledger (D2), and a key cabinet with a combination lock he can't open yet. | #70 | 5 min |
| 6 | **The building site** | Room 15 | The only room in the hotel under construction. The steel pipe among the scaffolding. The yellow chute through the floor. He slides down. | new task | 2 min |
| 7 | **GF** | Building site, corridor | He lands in a skip in another building site. In the corridor, a stack of sunbeds is jammed against the stairs door: he pushes it aside, opening the way back up. Off the corridor, the kitchen (a pot simmering, nobody) and the dining room, tables laid for the closing dinner, food warm, chairs pushed back. | #71 | 3 min |
| 8 | **The night porter** | Lobby | The porter is behind the desk under his lamp, a small radio playing the song. He greets Luca by name and gives him the room number nobody asked for. Asked to open the front door, he refuses: the hotel is closed, and he isn't authorized (see [The night porter](#the-night-porter)). The clock wall, the key board (K2 in pigeonhole 16; the hook for 22 is empty). Second save spot (S2). The TV room is optional. | #98 | 3 min |
| 9 | **The back office** | Back office | The porter's log (D3) on the desk: its last entry points to the cabinet upstairs and to the clock in twenty-two. A first aid kit. | #97 | 2 min |
| 10 | **Back up** | Stairs, 2F | Through the unblocked stairs, past the dark 1F, to 2F. Optional: room 16 with K2 (D4). 2F is just as it was: lit, still empty. | | 2 min |
| 11 | **The clock** | Room 22 | On the nightstand, in the empty spot, there's now a flip clock, stopped at **04:47** *(working)*: the code. | #82 | 1 min |
| 12 | **The cabinet** | 1F linen room | The code opens the cabinet: the hotel's spare keys on hooks, and the front door key (K3). | #82 | 2 min |
| 13 | **The empty desk** | Stairs, lobby | Back down to the lobby. The porter is gone: the lamp still on, the radio still playing, his chair empty. Nothing says where he went. K3 opens the front door. | #98 | 2 min |
| 14 | **The seafront** | Outside | Short cutscene: Luca steps out into the fog. Across the road, the beach and endless rows of folded umbrellas; the song from the beach club, very far away. Fade to black, end card, back to the main menu. | new task | 1 min |

## Tension

There are no enemies in the slice. Its fear comes from tension that is built and never released: sounds, lights and things out of place. None of these events leads to a threat, and none is ever explained. No jump scare reveals anything; the payoff is that there isn't one.

Each event is a one-shot scripted trigger. They aren't saved: replaying one after loading a save is fine.

| Id | Where | Trigger | What happens |
|---|---|---|---|
| `tension_shower` | Room 21 | Entering the room | The shower runs behind the bathroom door, steam under it. Inside: nobody. Interacting turns it off. |
| `tension_phone` | Room 23 | Walking down the 2F corridor | The room phone rings behind the locked door. It stops as Luca reaches the door. |
| `tension_tray` | Outside room 26 | Seen from the corridor | A room-service tray on the floor: breakfast for two, still warm. |
| `tension_coat` | Room 26 | Looking in from the doorway | The room's lamp is off. Against the window, a tall shape stands still. With the flashlight, it's a coat on a stand. |
| `tension_curtain` | 2F, corridor's west end | Entering the corridor | The window is open a crack and the curtain stirs. Fog drifts in. |
| `tension_flicker` | 2F stairs door | Stepping onto the stairs the first time | Every lamp on 2F flickers once behind him, then stays on. |
| `tension_footsteps` | 1F corridor | First time in the 1F corridor | Unhurried footsteps cross the floor above, then stop. Back upstairs, nobody. |
| `tension_wardrobe` | Room 13 | Entering the room | The wardrobe door creaks open. Empty hangers swing. |
| `tension_basement` | Stairs, below GF | Looking down the last flight | The chained basement door. A cold draught from under it, and a faint sound like the sea. |
| `tension_pot` | Kitchen | Entering the kitchen | A pot simmering on a lit stove. Nobody. |

On the return trip (beat 10) the floors stay as the player left them: lit and empty upstairs, dark and empty below. No new events.

## The night porter

The first surreal local (#98). He stands behind the reception desk, never moves from it, and is never helpful. Draft lines, to be finished in #98:

- **First meeting**, triggered when Luca enters the lobby: *"Good evening, signor Luca. Twenty-two, as always."* After a pause: *"The signora went up already."*
- **The front door**, whenever Luca tries it while the porter is there: *"I'm sorry, signor Luca. The hotel is closed. I'm not authorized to open the main door."*
- **Repeat visits**, one per interaction, in order, the last one repeating:
  - *"Breakfast is from seven until ten."*
  - *"The season's over, you know. It's always over, this time of year."*
  - *"We keep twenty-two for you. Every year."*
  - He says nothing, and turns the radio up a little.
- **Asked about the cabinet**: after D3 has been read, the next line is *"I never forget a code."*
- **Gone**: as soon as the cabinet is open, the porter is no longer in the lobby. His lamp stays on and his radio keeps playing.

Luca never answers.

## The puzzle: the key cabinet

The slice's puzzle (#82, id `puzzle_key_cabinet`): the housekeeping key cabinet in the 1F linen room, locked with a 4-wheel combination lock. Solving it means leaving the lobby area: the clue is downstairs, the code is on 2F and the cabinet is on 1F. The details may still be rediscussed; this is the current version.

- **The clue.** The porter's log (D3) ends with: *"Changed the code on the key cabinet upstairs. Same as the clock in twenty-two, so I won't forget."*
- **The answer.** The flip clock on room 22's nightstand, stopped at 04:47 *(working)*, so the code is **0447**. The clock isn't there when Luca wakes, only the spot where it stood; it appears once D3 has been read. So the trip back up is required, even for players who searched room 22 thoroughly.
- **The UI.** Four wheels, each 0–9. Up/down changes a digit, left/right moves between wheels. There's no penalty for wrong tries. The cabinet opens as soon as the wheels read the code.
- **The reward.** `key_front_door` (K3). Opening the cabinet also removes the porter from the lobby.
- **Saved state.** Solved or not.

The time on the clock is a working value. It is the only clock in the hotel that isn't simply wrong, and the slice never says what the time means (see [Two readings](#two-readings)). Keep it in data so the writers can change it.

## Encounters

None. The slice has no enemies, for now. Monsters arrive with a basement section designed later, behind `door_basement`. Its encounters, firearms and ammo budget will be designed together, following gameplay.md.

## Items

All placed by hand; nothing respawns. Pickup ids are persistent ids; item ids are #73's `ItemData` ids.

| Pickup id | Item id | Amount | Where |
|---|---|---|---|
| `pickup_drink_room22` | `health_drink` | 1 | Room 22, bathroom cabinet |
| `blockade_room_28` | `wooden_plank` | 1 | Across room 28's doorway ([the blockade](#the-blockade)) |
| `pickup_key_stairs` | `key_stairs` | 1 | Room 28, on the chair |
| `pickup_drink_linen` | `health_drink` | 1 | 1F linen room, housekeeping trolley |
| `pickup_pipe_site` | `steel_pipe` | 1 | Room 15, among the scaffolding |
| `pickup_key_room16` | `key_room_16` | 1 | Lobby, key board pigeonhole 16 |
| `pickup_aid_office` | `first_aid_kit` | 1 | Back office, wall cabinet |

`key_front_door` is the puzzle's reward, not a pickup. Documents are listed [below](#documents).

### Healing

With no enemies, nothing in the slice hurts the player, and healing can't be used at full health (#76). The budget rule (4–6 enemy hits between save spots) has nothing to cover. The slice still places a small stock, so pickups and the inventory have something real in them:

- **2 health drinks and 1 first aid kit**, 130 health, about 6.5 hits.

It all carries into the basement. When the basement is designed, its first stretch counts this stock toward its own budget.

### Weapons

The wooden plank (room 28's blockade) and the steel pipe (room 15), both from the gameplay spec. There's nothing to fight, but the player carries them into the basement. The fire axe is midgame, so it isn't placed.

## Save spots

| Id | Where | Notes |
|---|---|---|
| `save_2f_corridor` (S1) | 2F, west end of the corridor, by the stairs door | The last lit place before the dark. |
| `save_gf_lobby` (S2) | GF, lobby, near the glass doors | Before the puzzle and the return trip. |

Their look is placeholder (#91) until the art work. With no enemies, the "can't save while chased" refusal never fires. S1 → S2 is about 12 minutes on a first run and S2 → end about 11, inside the 15-minute guideline.

## Documents

Written in #97. Each one hints and never explains: the suicide plan is never stated, and every one keeps [two readings](#two-readings).

| Code | Id | Where | What it is |
|---|---|---|---|
| D1 | `doc_registration_card` | Room 22, desk | The hotel's registration card. Guest: Luca. Room 22. Guests: 2. Arrival: the date of the closing party. Departure: left blank. |
| D2 | `doc_lost_property` | 1F linen room, on the trolley | The housekeeping lost-property ledger. Things left in room 22 over many summers (a sandal, sunglasses, a hair clip, a paperback with a page folded down). The last line, in this season's hand: a men's watch, room 22, *"guest says keep it."* |
| D3 | `doc_porter_log` | Back office, desk | The night porter's log for the closing night: deadpan entries (lights out in the dining room, a complaint about the music from the beach, *"Last guests checked out. Hotel closed."*, then *"Signor Luca came in. Gave him twenty-two."*), ending with the puzzle clue. |
| D4 | `doc_postcard` | Room 16, under the mattress | A postcard of the Miramare from a summer long ago, unsent, addressed to room 22. Five words: *"Same room next year. Promise?"* The handwriting could be either of theirs. Optional, so it counts as an optional moment for the endings. |

## Key items

| Code | Id | Name | Where | Opens |
|---|---|---|---|---|
| K1 | `key_stairs` | Stairs key | Room 28, on the chair | `door_stairs_2f`, `door_stairs_1f` |
| K2 | `key_room_16` | Room 16 key | Lobby, key board | `door_room_16` |
| K3 | `key_front_door` | Front door key | Key cabinet (P1) | `door_front` |

## Examinables

Things to look at (#79). Each has one or two lines, and none is explained.

| Where | Object | Gist |
|---|---|---|
| Room 22 | Phone | No signal. Battery low, and a little lower each time he looks. |
| Room 22 | Wristband | The beach club's, from the closing party. |
| Room 22 | Nightstand | Before D3 is read: a clean spot in the dust where something stood. |
| Room 22 | Beds | Two singles pushed together, one side slept in. |
| Lift halls, lobby | Lift | *Out of order.* The floor indicator shows 3, a floor the hotel doesn't have. |
| 2F | Room 24's door | "Do not disturb." The TV behind it. |
| Room 28 | Chair | Set in the middle of the empty room, facing the window. |
| Room 12 | Beds | The same beds as 22, stripped, the mattresses rolled up. |
| Room 15, GF building site | Building work | Only these two rooms. No sign of who's doing it, or why. |
| Stairs, below GF | Basement door | Chained shut. Cold air underneath. |
| Dining room | A table | Set for the closing dinner. The food is still warm. |
| Lobby | Clock wall | Five cities, five times, none of them right. |
| Lobby | Key board | Every key on its hook except 22's. |
| Lobby, after the cabinet | The desk | The lamp on, the radio playing, the chair empty. |

## Two readings

Every clue has at least two readings, and the slice confirms none (premise.md, the mystery). Nothing in it settles the open questions: the breakup reason, the canonical truth, or anything about Elena beyond the fact that she's in the town.

| Clue | One reading | Another |
|---|---|---|
| He wakes in room 22, booked under his name | He came back high and checked in, and doesn't remember | He never got here; this isn't a hotel night |
| The hotel is closed, yet his room is kept for him | The porter made an exception for an old regular | He isn't a guest in any ordinary sense |
| Two beds pushed together, one side slept in | He slept alone, out of habit, on his side | Someone else was here |
| Guests: 2 on the registration card (D1) | Booked out of habit, as every summer | Elena is here (in part 2, she is) |
| Departure left blank (D1) | He didn't know how long he'd stay | There was never going to be a departure |
| *"Guest says keep it"* (D2) | Hungover generosity | Giving his things away |
| *"Signor Luca came in"* (D3) | He walked back from the rave, as the drug reading needs | The porter's log is as unreliable as the clocks |
| *"The signora went up already"* | The porter is remembering past summers | She really is upstairs |
| The lit, empty 2F; footsteps above 1F | A closed hotel with the lights left on, and an old building that creaks | Someone is up there, out of sight |
| A room boarded with a single plank, a chair facing the window | Housekeeping closed off a room with nothing in it | Someone shut something in, or out |
| Building work in only two rooms | A renovation started before the season ended | A way down made for him |
| Breakfast for two outside room 26 | Left over from the last guests | Meant for the two of them |
| The clock appears on the nightstand | He missed it the first time | Someone put it back |
| The clock stopped at 04:47 | A cheap clock that died at some point | A time that means something to him |
| The porter can't be reached across the desk | It's just a deep desk | He isn't there to be reached |
| The porter is gone when Luca has the key | His shift ended | He was only there to keep him in |

## What the slice needs beyond existing issues

- **The blockade** (room 28): an interactable that gives the plank and clears the doorway. Close to a pickup (#74), plus the collision removal.
- **The chute** (room 15): an interactable that plays a short sequence (#95) and moves the player to the skip on GF.
- **The obstacle** (GF): an interactable that rolls the sunbeds clear and frees `door_stairs_gf`.
- **The porter leaving** when the cabinet opens, and his front door refusal (#98).
- **The ending cutscene** (beat 14): #96 covers only the opening. It can reuse #95's cutscene support.
- **Tension events**: one-shot triggers that play a sound, move a door or flicker lights ([Tension](#tension)). No task covers them yet.
- **Lighting per floor**: 2F lit, 1F dark, GF dark except the porter's lamp. For the graybox (#70) and the art pass (#37).
- **Double doors** (dining room ↔ lobby): two `Door`s side by side, or one wider door scene.
- **Scripted world changes:** the clock appearing in room 22 and the porter's line progression. Both are saved state for #89.

### Saved world state

On top of what gameplay.md lists (pickups, doors, documents read), the slice saves:

- the blockade taken and the obstacle moved;
- `puzzle_key_cabinet` (solved), which also means the porter is gone;
- whether the clock has appeared in room 22;
- the porter's line index.

## Playtest notes

Filled in by #72.
