# Vertical slice: Hotel Miramare

The reference for building the slice: layout, beats, encounters, items, save spots, documents and the puzzle. Story and pillars live in [premise.md](premise.md), rules and numbers in [gameplay.md](gameplay.md), the look in [visual-style.md](visual-style.md).

Names marked *working* are placeholders, as in premise.md. Ids in `code` are the ones the implementation uses (item ids for #73, persistent ids for #89).

## Summary

- **Starts** at a new game with Luca waking in room 12, their old room. **Ends** when he unlocks the front door and steps out onto the seafront in the fog.
- **Two floors** of the hotel: the first floor (the guest rooms) and the ground floor (dining room, kitchen, lobby). The floors above are implied, never reached.
- **The loop:** find the service key to get downstairs, meet the night porter, find the key cabinet and its clue, go back up to the old room for the code, come back down through a shortcut, open the front door.
- **Five standard enemies**, all avoidable except one, which is very likely a fight.
- **Melee only.** Firearms are milestone M3; see [Firearms in M3](#firearms-in-m3) for where they go later.
- **Two save spots**, about 25 minutes of play on a first run.

What's not in the slice: the prologue (the rave night), the crossovers with part 2, firearms, the fire axe (a midgame weapon), other locals, any other location.

## The hotel

A family hotel on the seafront, three storeys plus a roof terrace, built in the 1960s and redone in the 80s: terrazzo floors, wood-panelled reception, pastel tiles, brass room numbers. It's closed for the season. The sunbeds and umbrellas from its beach concession are stacked inside for the winter, and one pile fills the main staircase.

The lamps are on but dim and sparse, so rooms need the flashlight. The light through the shutters is a dusk that doesn't match any clock. Every clock in the hotel shows a different time, except one (see [the puzzle](#the-puzzle-the-key-cabinet)).

Dimensions below are approximate, for the graybox (#70). The footprint is about 30 × 14 m, with 6 × 6 m rooms, a 2 m corridor and 3 m ceilings.

## Floor plans

North is the sea. Codes are explained in the [legend](#legend) below the plans.

### First floor (guest rooms)

```
                   north: balconies over the seafront, fog
 0m          6m          12m         18m         24m         30m
 ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 │LINEN ROOM │ROOM 16    │ROOM 14    │STAIR HALL │ROOM 12    │
 │           │           │"do not    │ ▓▓▓▓▓▓▓▓▓ │START      │
 │K1  W  h   │D4         │ disturb"  │ ▓ main  ▓ │W  h  D1   │
 │D2         │           │TV, song   │ ▓ stairs▓ │clock (P1) │
 │           │           │           │       S1  │balcony    │
 ├────   ────┼────▒▒▒────┼────▒▒▒────┤           ├────   ────┤
 │  ← corridor B          E2 wanders here      corridor A →  │
 ├────▒▒▒────┼────   ────┼────   ────┼──[lift]───┼────▒▒▒────┤
 │SERVICE    │ROOM 15    │ROOM 13    │lift shaft,│ROOM 11    │
 │STAIRS     │           │           │plumbing   │           │
 │ ↓ ground  │E1  h      │empty      │(solid)    │locked,    │
 │   floor   │           │hiding spot│           │no key     │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **Room 12** is the corner room facing the sea, with a small balcony. Frosted dividers close it off from the neighbours' balconies.
- **Stair hall**: open to both corridors. The main stairs down are filled with stacked sunbeds and folded umbrellas, impassable. The lift's doors are shut, with an *out of order* sign.
- **Room 14** never opens. A TV is on behind the door, playing the slowed Italo-disco song from the rave.
- **Room 13** is open and empty: a place to shut yourself in while E2 loses track (enemies can't open doors).
- **Room 11** is simply locked. No key exists in the slice.

### Ground floor

```
                   north: the seafront (lungomare), fog
 0m          6m          12m         18m         24m         30m
 ┌───────────────────────────────────┬──────────────▒▒▒──────┐
 │DINING ROOM                        │LOBBY     front door K3│
 │tables set for the last dinner     │▓▓▓▓▓▓▓▓▓   clock wall │
 │                                   │▓ stairs▓  key board K2│
 │      E4                E5         │▓▓▓▓▓▓▓▓▓              │
 │                                    glass doors     S2     │
 │                                   │  ┌── desk ──┐         │
 │                                   │  └─ PORTER ─┘         │
 ├───────────┬─────────   ───────────┼────   ────┬────   ────┤
 │SERVICE    │KITCHEN                │BACK OFFICE│TV ROOM    │
 │STAIRS        E3        h          #P1  H      │h          │
 │ ↑ first   │                       │D3         │radio, song│
 │   floor   │                       │           │           │
 │           │                       │           │           │
 └───────────┴───────────────────────┴───────────┴───────────┘
                    south: the street side
```

- **Kitchen ↔ dining room**: a swing door. **Dining room ↔ lobby**: glass double doors.
- **Lobby**: the bottom of the main stairs, blocked by the same pile from below. A wall of clocks for foreign tourists' cities, all showing different times. The key board behind the desk, the reception desk with the porter behind it, and the front door, locked.
- **The desk** is at least 2 m deep, so the porter is out of melee reach from the lobby side (longest reach 1.9 m). Nobody can hit him, and nothing explains why.
- **Back office**: reached from the lobby through the door behind the desk. Its door to the kitchen is bolted on the office side; unbolting it is the [shortcut](#locks-keys-and-shortcuts).
- **TV room**: an optional side room with a radio playing the song.

### Legend

| Code | Meaning |
|---|---|
| `   ` (gap in a wall) | Doorway with an unlocked door |
| `▒▒▒` | Locked door (key shown next to it or in the table below) |
| `#` | Door bolted from the room it's drawn in: a shortcut once unbolted |
| `▓` | Main stairs, blocked |
| E1–E5 | Standard enemies ([Encounters](#encounters)) |
| S1, S2 | Save spots |
| K1–K3 | Key items |
| D1–D4 | Documents |
| P1 | The puzzle: the key cabinet (back office) and its code (room 12's clock) |
| W | Melee weapon pickup |
| h, H | Health drink, first aid kit |

## Locks, keys and shortcuts

| Door id | Where | State | Opens with |
|---|---|---|---|
| `door_room_12` | Room 12 ↔ corridor A | unlocked | |
| `door_room_11` | Room 11 ↔ corridor A | locked | nothing ("It's locked.") |
| `door_room_13` | Room 13 ↔ corridor B | unlocked | |
| `door_room_14` | Room 14 ↔ corridor B | locked | nothing ("Do not disturb.") |
| `door_room_15` | Room 15 ↔ corridor B | unlocked, ajar | |
| `door_room_16` | Room 16 ↔ corridor B | locked | `key_room_16` (K2) |
| `door_linen_room` | Linen room ↔ corridor B | unlocked | |
| `door_service_f1` | Service stairs ↔ corridor B | locked ("Staff only.") | `key_service` (K1) |
| `door_service_gf` | Service stairs ↔ kitchen | unlocked | |
| `door_kitchen_dining` | Kitchen ↔ dining room (swing) | unlocked | |
| `door_dining_lobby` | Dining room ↔ lobby (glass, double) | unlocked | |
| `door_office_lobby` | Back office ↔ lobby, behind the desk | unlocked | |
| `door_office_kitchen` | Back office ↔ kitchen | bolted on the office side | the bolt, from inside the office (shortcut) |
| `door_tv_room` | TV room ↔ lobby | unlocked | |
| `door_front` | Lobby ↔ seafront | locked | `key_front_door` (K3), ends the slice |

**The shortcut.** From the kitchen, `door_office_kitchen` says *"It won't move. Bolted from the other side."* Inside the back office the bolt is an interactable that unlocks the door for good (it calls `unlock()`, and the unlock is saved like a key's). Opened, it links the lobby to the service stairs without crossing the dining room: the way back up and down for the second half of the slice.

**Progression.** K1 opens the way down. P1 needs the code from room 12, and solving it gives K3. K3 ends the slice. K2 and room 16 are optional.

## Beat sheet

Times are rough for a first run.

| # | Beat | Where | What happens | Owner | Time |
|---|---|---|---|---|---|
| 1 | **Awakening** | Room 12 | Cutscene. Luca wakes on the bed in his clothes from the rave, wristband still on. Two single beds pushed together into a double, one side slept in, the other made. Balcony door open, fog, the sea. The light through the shutters is dusk. He doesn't know how he got here. Control is handed over in the room. | #96 | 1 min |
| 2 | **The old room** | Room 12 | Free exploration and the interaction tutorial: one of the bed's slats is snapped; take it (the wooden plank). A health drink in the bathroom cabinet. The registration card on the desk (D1). Examinables: his phone (no signal), the wristband, an empty, dust-free spot on the nightstand where something used to stand. | #70, #71, #79 | 2 min |
| 3 | **The floor** | Corridor A, stair hall | The main stairs are buried under sunbeds and umbrellas. Lift out of order. Room 11 locked. First save spot (S1). | #70 | 1 min |
| 4 | **Corridor B** | Corridor B, rooms 13–16 | The first enemy, E2, wanders the corridor between the player and everything else. Fight it (most players will), wait it out, or hide in room 13. Room 14 has the TV and the song behind a "do not disturb" sign. Room 15 is open, with E1 and a health drink inside. Room 16 is locked. | #71 | 4 min |
| 5 | **The linen room** | Linen room | The service key (K1) on the housekeeping trolley, the steel pipe (a broken clothes rail), a health drink, the lost-property ledger (D2). | #71 | 2 min |
| 6 | **Downstairs** | Service stairs, kitchen | K1 opens the service stairs. The kitchen: E3 at the stoves, back turned. A health drink on the pantry shelves. Through the swing door to the dining room. | #71 | 2 min |
| 7 | **The last dinner** | Dining room | Tables laid for the season's closing dinner, the food untouched and fresh. E4 and E5 stand motionless among the tables, facing the sea windows. Cross along the south wall to the glass doors. | #71 | 2 min |
| 8 | **The night porter** | Lobby | The porter is behind the desk, small radio playing the song. First meeting: he greets Luca by name and gives him the room number nobody asked for (see [The night porter](#the-night-porter)). The clock wall, the key board (K2 hangs in pigeonhole 16; the hook for 12 is empty), the locked front door. Second save spot (S2). The TV room is optional (health drink, radio). | #98 | 3 min |
| 9 | **The back office** | Back office | The key cabinet (P1), locked with a 4-digit combination. The porter's log (D3) on the desk: its last entry gives the clue. A first aid kit. The bolt on the door to the kitchen: the shortcut. | #82, #97 | 2 min |
| 10 | **Back up** | Kitchen, service stairs, first floor | Through the shortcut, the kitchen (E3 again if it's still standing) and the service stairs. Optional: room 16 with K2 (D4). Any enemy avoided earlier is still where it was. | | 2 min |
| 11 | **The clock** | Room 12 | On the nightstand, in the empty spot, there's now a flip clock, stopped at **04:47** *(working)*: the code. | #82 | 1 min |
| 12 | **The cabinet** | Back office | Back down by the same route. The code opens the cabinet: room keys on hooks, and the front door key (K3). | #82 | 2 min |
| 13 | **Checking out** | Lobby, front door | The porter, as Luca passes with K3: "Checking out already?" K3 opens the front door. | #98 | 1 min |
| 14 | **The seafront** | Outside | Short cutscene: Luca steps out into the fog. Across the road, the beach and endless rows of folded umbrellas; the song from the beach club, very far away. Fade to black, end card, back to the main menu. | new task | 1 min |

## The night porter

The first surreal local (#98). He stands behind the reception desk for the whole slice, never moves from it, and is never helpful. Draft lines, to be finished in #98:

- **First meeting**, triggered when Luca enters the lobby: *"Good evening, signor Luca. Twelve, as always."* After a pause: *"The signora went up already."*
- **Repeat visits**, one per interaction, in order, the last one repeating:
  - *"Breakfast is from seven until ten."*
  - *"The season's over, you know. It's always over, this time of year."*
  - *"We keep twelve for you. Every year."*
  - He says nothing, and turns the radio up a little.
- **Asked about the cabinet**: after D3 has been read, the next line is *"I never forget a code."*
- **Holding the front door key**: *"Checking out already?"*

Luca never answers.

## The puzzle: the key cabinet

The slice's puzzle (#82, id `puzzle_key_cabinet`): a wall-mounted key cabinet in the back office, locked with a 4-wheel combination lock.

- **The clue.** The porter's log (D3) ends with: *"Changed the cabinet code. Same as the clock in twelve, so I won't forget."*
- **The answer.** The flip clock on room 12's nightstand, stopped at 04:47 *(working)*, so the code is **0447**. The clock isn't there when Luca wakes, only the spot where it stood; it appears once D3 has been read. So the trip back up is required, even for players who searched room 12 thoroughly.
- **The UI.** Four wheels, each 0–9. Up/down changes a digit, left/right moves between wheels. There's no penalty for wrong tries. The cabinet opens as soon as the wheels read the code.
- **The reward.** `key_front_door` (K3).
- **Saved state.** Solved or not.

The time on the clock is a working value. It is the only clock in the hotel that isn't simply wrong, and the slice never says what the time means (see [Two readings](#two-readings)). Keep it in data so the writers can change it.

## Encounters

All five are the standard enemy (100 health, hits for 15–25) with the existing IDLE/WANDER brain. Their look and any voice lines wait on the breakup reason (premise.md, open questions), so the slice uses the placeholder model. A *stationary* enemy is one with a very long `idle_duration` and a facing set in the level; it stays put until it notices the player.

| Id | Where | Placement | How to avoid it | Notes |
|---|---|---|---|---|
| `enemy_e1` | Room 15 | Stationary, facing the window, its back to the door | Don't go in (the room is optional), or walk in with the flashlight off and take the drink near the door, staying more than 3 m from it | Guards an optional health drink |
| `enemy_e2` | Corridor B | Wanders around the middle of corridor B, `wander_radius` 4 m | Wait in the stair hall with the flashlight off until it wanders west, or let it see you and shut yourself in room 13 until it loses track (6 s) | The first fight for most players, with the plank. The steel pipe comes right after |
| `enemy_e3` | Kitchen | Stationary at the stoves, back turned to the route between the service stairs, the swing door and the office door | Keep at least 3.5 m away (running footsteps carry 3 m) | Met twice if avoided: on the way down and on the shortcut route |
| `enemy_e4` | Dining room | Stationary among the tables, facing the sea windows | The route along the south wall keeps at least 4 m from both | E4 and E5 stand about 6 m apart, so fighting one wakes the other (melee hits carry 8 m). Avoiding is the smart move here |
| `enemy_e5` | Dining room | As E4 | As E4 | |

Total health of the killable enemies: **500**.

## Items

All placed by hand; nothing respawns. Pickup ids are persistent ids; item ids are #73's `ItemData` ids.

| Pickup id | Item id | Amount | Where | Path |
|---|---|---|---|---|
| `pickup_plank_room12` | `wooden_plank` | 1 | Room 12, the bed's broken slat | critical |
| `pickup_drink_room12` | `health_drink` | 1 | Room 12, bathroom cabinet | critical |
| `pickup_drink_room15` | `health_drink` | 1 | Room 15, luggage rack by the door | optional (E1) |
| `pickup_pipe_linen` | `steel_pipe` | 1 | Linen room, under a collapsed shelf | critical |
| `pickup_drink_linen` | `health_drink` | 1 | Linen room, housekeeping trolley | critical |
| `pickup_key_service` | `key_service` | 1 | Linen room, housekeeping trolley | critical |
| `pickup_drink_kitchen` | `health_drink` | 1 | Kitchen, pantry shelves | critical |
| `pickup_key_room16` | `key_room_16` | 1 | Lobby, key board pigeonhole 16 | optional |
| `pickup_drink_tv_room` | `health_drink` | 1 | TV room, next to the radio | optional |
| `pickup_aid_office` | `first_aid_kit` | 1 | Back office, wall cabinet | critical |

`key_front_door` is the puzzle's reward, not a pickup. Documents are listed [below](#documents).

### Healing budget

The rule (gameplay.md): healing between save spots covers about **4–6 enemy hits**. At 20 damage per hit on average, that's 80–120 health.

| Stretch | Enemies met | Healing placed | Total | Hits |
|---|---|---|---|---|
| Start → S1 | none | | | |
| S1 → S2 | E2, E3, E4, E5, E1 (optional) | drinks in room 12\*, the linen room and the kitchen; drink in room 15 (optional) | 90 + 30 = 120 | 4.5–6 |
| S2 → end | E2, E3 again if avoided | first aid kit in the back office; drink in the TV room (optional) | 70 + 30 = 100 | 3.5–5 |

\* The drink in room 12 lies before S1 but there's nothing to spend it on until after S1, so it counts for S1 → S2.

Placed overall: 5 health drinks and 1 first aid kit, **220 health**, of which 160 is on the critical path. No ampoule in the slice.

### Weapons

The wooden plank (room 12) and the steel pipe (linen room), both from the gameplay spec. The fire axe is midgame, so it isn't placed.

### Firearms in M3

When firearms land (M3), add them without moving anything else:

- the **pistol**, in the back office desk drawer, with 7 rounds in the magazine;
- one **8-round** pickup in room 16.

15 rounds × 20 damage = 300, which is **60%** of the 500 enemy health, as gameplay.md asks.

## Save spots

| Id | Where | Notes |
|---|---|---|
| `save_f1_stair_hall` (S1) | First floor, stair hall | A hub between both corridors with escape routes either way. It's within E2's flashlight sight range (18 m), which teaches that the light gets you noticed. |
| `save_gf_lobby` (S2) | Ground floor, lobby, near the glass doors | Before the puzzle and the return trip. Exits to the dining room, the back office and the TV room. |

Their look is placeholder (#91) until the art work. S1 → S2 is about 12 minutes on a first run and S2 → end about 10, inside the 15-minute guideline.

## Documents

Written in #97. Each one hints and never explains: the suicide plan is never stated, and every one keeps [two readings](#two-readings).

| Code | Id | Where | What it is |
|---|---|---|---|
| D1 | `doc_registration_card` | Room 12, desk | The hotel's registration card. Guest: Luca. Room 12. Guests: 2. Arrival: the date of the closing party. Departure: left blank. |
| D2 | `doc_lost_property` | Linen room, on the trolley | The housekeeping lost-property ledger. Things left in room 12 over many summers (a sandal, sunglasses, a hair clip, a paperback with a page folded down). The last line, in this season's hand: a men's watch, room 12, *"guest says keep it."* |
| D3 | `doc_porter_log` | Back office, desk | The night porter's log for the closing night: deadpan entries (lights out in the dining room, a complaint about the music from the beach, *"Signor Luca came in. Gave him twelve."*), ending with the puzzle clue. |
| D4 | `doc_postcard` | Room 16, under the mattress | A postcard of the Miramare from a summer long ago, unsent, addressed to room 12. Five words: *"Same room next year. Promise?"* The handwriting could be either of theirs. Optional, so it counts as an optional moment for the endings. |

## Key items

| Code | Id | Name | Where | Opens |
|---|---|---|---|---|
| K1 | `key_service` | Service key | Linen room, on the trolley | `door_service_f1` |
| K2 | `key_room_16` | Room 16 key | Lobby, key board | `door_room_16` |
| K3 | `key_front_door` | Front door key | Key cabinet (P1) | `door_front` |

## Examinables

Things to look at (#79). Each has one or two lines, and none is explained.

| Where | Object | Gist |
|---|---|---|
| Room 12 | Phone | No signal. Battery low, and a little lower each time he looks. |
| Room 12 | Wristband | The beach club's, from the closing party. |
| Room 12 | Nightstand | Before D3 is read: a clean spot in the dust where something stood. |
| Room 12 | Beds | Two singles pushed together, one side slept in. |
| Stair hall, lobby | Main stairs | Sunbeds and folded umbrellas, stacked to the ceiling. |
| Stair hall | Lift | *Out of order.* The floor indicator shows a floor the hotel doesn't have. |
| Corridor B | Room 14's door | "Do not disturb." The TV behind it. |
| Dining room | A table | Set for the closing dinner. The food is still warm. |
| Lobby | Clock wall | Five cities, five times, none of them right. |
| Lobby | Key board | Every key on its hook except 12's. |

## Two readings

Every clue has at least two readings, and the slice confirms none (premise.md, the mystery). Nothing in it settles the open questions: the breakup reason, the canonical truth, or anything about Elena beyond the fact that she's in the town.

| Clue | One reading | Another |
|---|---|---|
| He wakes in room 12, booked under his name | He came back high and checked in, and doesn't remember | He never got here; this isn't a hotel night |
| Two beds pushed together, one side slept in | He slept alone, out of habit, on his side | Someone else was here |
| Guests: 2 on the registration card (D1) | Booked out of habit, as every summer | Elena is here (in part 2, she is) |
| Departure left blank (D1) | He didn't know how long he'd stay | There was never going to be a departure |
| *"Guest says keep it"* (D2) | Hungover generosity | Giving his things away |
| *"Signor Luca came in"* (D3) | He walked back from the rave, as the drug reading needs | The porter's log is as unreliable as the clocks |
| *"The signora went up already"* | The porter is remembering past summers | She really is upstairs |
| The clock appears on the nightstand | He missed it the first time | Someone put it back |
| The clock stopped at 04:47 | A cheap clock that died at some point | A time that means something to him |
| The porter can't be reached across the desk | It's just a deep desk | He isn't there to be reached |

## What the slice needs beyond existing issues

- **The ending cutscene** (beat 14): #96 covers only the opening. It can reuse #95's cutscene support.
- **Double doors** (dining ↔ lobby): two `Door`s side by side, or one wider door scene.
- **The bolt** (shortcut): a small `Interactable` that calls `unlock()` on its door.
- **Scripted world changes:** the clock appearing in room 12 and the porter's line progression. All are saved state for #89.

### Saved world state

On top of what gameplay.md lists (pickups, doors, documents read, dead enemies), the slice saves `puzzle_key_cabinet` (solved), whether the clock has appeared in room 12, and the porter's line index.

## Playtest notes

Filled in by #72.
