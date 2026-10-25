# Vertical slice: Hotel Miramare

The reference for building the slice: layout, beats, tension, items, save spots, documents and the puzzle. Story and pillars live in [premise.md](premise.md), rules and numbers in [gameplay.md](gameplay.md), the look in [visual-style.md](visual-style.md).

Names marked *working* are placeholders, as in premise.md. Ids in `code` are the ones the implementation uses (item ids for #73, persistent ids for #89).

## Summary

- **Starts** at a new game with Luca waking in room 22, their old room. **Ends** when he unlocks the front door and steps out onto the seafront in the fog.
- **Three floors** of the hotel: the second floor, where their room is, lit and empty; the first floor, dark; and the ground floor (dining room, kitchen, lobby). The floor above is roped off.
- **The loop:** down through the dark first floor, find the service key, meet the night porter, find the key cabinet and its clue, go back up to the old room for the code, come back down through a shortcut, open the front door.
- **No enemies.** The slice is all tension that never pays off: sounds, lights and things out of place, and nothing ever attacks. That also makes a night porter calmly on duty plausible. Enemies come later with a basement section; its door is already in the slice, chained.
- **Two save spots**, about 30 minutes of play on a first run.

What's not in the slice: enemies and combat encounters, firearms, the prologue (the rave night), the crossovers with part 2, the fire axe (a midgame weapon), other locals, any other location.

## The hotel

A family hotel on the seafront, a ground floor and three floors above it plus a roof terrace, built in the 1960s and redone in the 80s: terrazzo floors, wood-panelled reception, pastel tiles, brass room numbers. It's closed for the season. The sunbeds and umbrellas from its beach concession are stacked inside for the winter, and one pile fills the main staircase between the first and ground floors.

**Lighting by floor:**
- **Second floor:** all the lamps are on, warm and steady. It looks open for business, and it's empty.
- **First floor:** every lamp is off. The flashlight is the only light.
- **Ground floor:** dark, except the porter's desk lamp in the lobby.

Outside the windows it's a dusk that doesn't match any clock. Every clock in the hotel shows a different time, except one (see [the puzzle](#the-puzzle-the-key-cabinet)).

Dimensions below are approximate, for the graybox (#70). Every floor has the same footprint, about 30 × 14 m, with 6 × 6 m rooms, a 2 m corridor and 3 m ceilings. The stair hall, lift shaft and service stairwell line up across the floors.

## Floor plans

North is the sea. Codes are explained in the [legend](#legend) below the plans.

### Second floor (lit)

```
                   north: balconies over the seafront, fog
 0m          6m          12m         18m         24m         30m
 ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 │ROOM 28    │ROOM 26    │ROOM 24    │STAIR HALL │ROOM 22    │
 │locked     │lamp off,  │"do not    │ ▓ up:   ▓ │START      │
 │           │coat by the│ disturb"  │ ▓ roped ▓ │W  h  D1   │
 │           │window     │TV, song   │ ↓ down    │clock (P1) │
 │           │tray (door)│           │       S1  │balcony    │
 ├────▒▒▒────┼────   ────┼────▒▒▒────┤           ├────   ────┤
 │ window ← corridor (lights on)                  corridor → │
 ├───────────┼────▒▒▒────┼────▒▒▒────┼──[lift]───┼────   ────┤
 │service    │ROOM 25    │ROOM 23    │lift shaft,│ROOM 21    │
 │stairwell, │locked     │locked,    │plumbing   │door ajar, │
 │no door on │           │phone      │(solid)    │shower     │
 │this floor │           │ringing    │           │running    │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **Room 22** is the corner room facing the sea, with a small balcony. Frosted dividers close it off from the neighbours' balconies.
- **Stair hall**: open to the corridor. The stairs up to the third floor are roped off with a "closed for the season" sign. The stairs down to the first floor are clear. The lift's doors are shut, with an *out of order* sign.
- **Room 24** never opens. A TV is on behind the door, playing the slowed Italo-disco song from the rave.
- **Room 26** is the one room on the floor with its lamp off. A room-service tray sits outside its door.
- **Room 21** is open, as if a guest just stepped out. Rooms 23, 25 and 28 are locked, with no key in the slice.
- **The corridor's west end** is a window, open a crack, its curtain stirring.

### First floor (dark)

```
                   north: balconies over the seafront, fog
 0m          6m          12m         18m         24m         30m
 ┌───────────┬───────────┬───────────┬───────────┬───────────┐
 │LINEN ROOM │ROOM 16    │ROOM 14    │STAIR HALL │ROOM 12    │
 │           │           │locked     │ ↑ up      │laid out   │
 │K1  W  h   │D4         │           │ ▓ down: ▓ │like 22,   │
 │D2         │           │           │ ▓blocked▓ │beds       │
 │           │           │           │           │stripped   │
 ├────   ────┼────▒▒▒────┼────▒▒▒────┤           ├────   ────┤
 │ ← corridor B (lights off)                    corridor A → │
 ├────▒▒▒────┼────   ────┼────   ────┼──[lift]───┼────▒▒▒────┤
 │SERVICE    │ROOM 15    │ROOM 13    │lift shaft,│ROOM 11    │
 │STAIRS     │sheet over │wardrobe   │plumbing   │locked,    │
 │ ↓ ground  │the bed    │creaks open│(solid)    │no key     │
 │   floor   │           │           │           │           │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: the street side
```

- **Stair hall**: the stairs up to the second floor are clear. The stairs down are filled with stacked sunbeds and folded umbrellas, impassable.
- **Room 12**, right under their room, has the same furniture in the same places, with the beds stripped and the mattresses rolled up.
- **Rooms 13 and 15** are open. Rooms 11 and 14 are locked with no key in the slice; room 16 opens with K2.
- **The service stairs** are behind a locked "staff only" door (K1), and lead down to the kitchen.

### Ground floor

```
                   north: the seafront (lungomare), fog
 0m          6m          12m         18m         24m         30m
 ┌───────────────────────────────────┬──────────────▒▒▒──────┐
 │DINING ROOM                        │LOBBY     front door K3│
 │tables set for the last dinner,    │▓▓▓▓▓▓▓▓▓   clock wall │
 │chairs pushed back                 │▓ stairs▓  key board K2│
 │                                   │▓▓▓▓▓▓▓▓▓              │
 │                                    glass doors     S2     │
 │                                   │  ┌── desk ──┐  lamp   │
 │                                   │  └─ PORTER ─┘         │
 ├───────────┬─────────   ───────────┼────   ────┬────   ────┤
 │SERVICE    │KITCHEN                │BACK OFFICE│TV ROOM    │
 │STAIRS        a pot on the stove   #P1  H      │radio, song│
 │ ↑ first   │                       │D3         │           │
 │ ↓ basement│                       │           │           │
 │   ▒▒▒     │                       │           │           │
 └───────────┴───────────────────────┴───────────┴───────────┘
                    south: the street side
```

- **Kitchen ↔ dining room**: a swing door. **Dining room ↔ lobby**: glass double doors.
- **Lobby**: the bottom of the main stairs, blocked by the same pile from below. A wall of clocks for foreign tourists' cities, all showing different times. The key board behind the desk, the reception desk with the porter behind it under his lamp, and the front door, locked.
- **The desk** is at least 2 m deep, so the porter is out of melee reach from the lobby side (longest reach 1.9 m). Nobody can hit him, and nothing explains why.
- **Back office**: reached from the lobby through the door behind the desk. Its door to the kitchen is bolted on the office side; unbolting it is the [shortcut](#locks-keys-and-shortcuts).
- **TV room**: an optional side room with a radio playing the song.
- **The service stairs** go on down to the basement door, chained shut. It's the hook for the basement section with the monsters, designed later; in the slice it never opens.

### Legend

| Code | Meaning |
|---|---|
| `   ` (gap in a wall) | Doorway with an unlocked door |
| `▒▒▒` | Locked door (key shown next to it or in the table below) |
| `#` | Door bolted from the room it's drawn in: a shortcut once unbolted |
| `▓` | Stairs, blocked or roped off |
| ↑ ↓ | Stairs up or down, clear |
| S1, S2 | Save spots |
| K1–K3 | Key items |
| D1–D4 | Documents |
| P1 | The puzzle: the key cabinet (back office) and its code (room 22's clock) |
| W | Melee weapon pickup |
| h, H | Health drink, first aid kit |

## Locks, keys and shortcuts

| Door id | Where | State | Opens with |
|---|---|---|---|
| `door_room_21` | Room 21 ↔ corridor, second floor | unlocked, ajar | |
| `door_room_22` | Room 22 ↔ corridor, second floor | unlocked | |
| `door_room_23` | Room 23 ↔ corridor, second floor | locked | nothing |
| `door_room_24` | Room 24 ↔ corridor, second floor | locked | nothing ("Do not disturb.") |
| `door_room_25` | Room 25 ↔ corridor, second floor | locked | nothing |
| `door_room_26` | Room 26 ↔ corridor, second floor | unlocked | |
| `door_room_28` | Room 28 ↔ corridor, second floor | locked | nothing |
| `door_room_11` | Room 11 ↔ corridor A, first floor | locked | nothing |
| `door_room_12` | Room 12 ↔ corridor A, first floor | unlocked | |
| `door_room_13` | Room 13 ↔ corridor B, first floor | unlocked | |
| `door_room_14` | Room 14 ↔ corridor B, first floor | locked | nothing |
| `door_room_15` | Room 15 ↔ corridor B, first floor | unlocked, ajar | |
| `door_room_16` | Room 16 ↔ corridor B, first floor | locked | `key_room_16` (K2) |
| `door_linen_room` | Linen room ↔ corridor B, first floor | unlocked | |
| `door_service_f1` | Service stairs ↔ corridor B, first floor | locked ("Staff only.") | `key_service` (K1) |
| `door_service_gf` | Service stairs ↔ kitchen | unlocked | |
| `door_basement` | Service stairs ↔ basement | locked ("Chained shut.") | nothing in the slice |
| `door_kitchen_dining` | Kitchen ↔ dining room (swing) | unlocked | |
| `door_dining_lobby` | Dining room ↔ lobby (glass, double) | unlocked | |
| `door_office_lobby` | Back office ↔ lobby, behind the desk | unlocked | |
| `door_office_kitchen` | Back office ↔ kitchen | bolted on the office side | the bolt, from inside the office (shortcut) |
| `door_tv_room` | TV room ↔ lobby | unlocked | |
| `door_front` | Lobby ↔ seafront | locked | `key_front_door` (K3), ends the slice |

Locked doors with no key answer "It's locked." unless the table gives another line.

**The shortcut.** From the kitchen, `door_office_kitchen` says *"It won't move. Bolted from the other side."* Inside the back office the bolt is an interactable that unlocks the door for good (it calls `unlock()`, and the unlock is saved like a key's). Opened, it links the lobby to the service stairs without crossing the dining room: the way back up and down for the second half of the slice.

**Progression.** K1 opens the way down. P1 needs the code from room 22, and solving it gives K3. K3 ends the slice. K2 and room 16 are optional.

## Beat sheet

Times are rough for a first run.

| # | Beat | Where | What happens | Owner | Time |
|---|---|---|---|---|---|
| 1 | **Awakening** | Room 22 | Cutscene. Luca wakes on the bed in his clothes from the rave, wristband still on. Two single beds pushed together into a double, one side slept in, the other made. Balcony door open, fog, the sea. The lamps are on; outside it's dusk. He doesn't know how he got here. Control is handed over in the room. | #96 | 1 min |
| 2 | **The old room** | Room 22 | Free exploration and the interaction tutorial: one of the bed's slats is snapped; take it (the wooden plank). A health drink in the bathroom cabinet. The registration card on the desk (D1). Examinables: his phone (no signal), the wristband, an empty, dust-free spot on the nightstand where something used to stand. | #70, #71, #79 | 2 min |
| 3 | **The lit floor** | Second floor | A warm, lit, ordinary hotel corridor with nobody in it. Room 21's shower running, the phone ringing in 23, the TV in 24, the tray outside 26 and the figure in its window, the stirring curtain ([Tension](#tension)). None of it leads anywhere. First save spot (S1) at the top of the stairs down. | #70 | 4 min |
| 4 | **Into the dark** | First floor | The lights flicker once behind him as he goes down, and stay on. The first floor is pitch dark: flashlight on. Footsteps cross the floor above, the one he just left empty. Room 12 is their room again, stripped. Room 13's wardrobe, the sheet in room 15. The main stairs down are blocked. | #70 | 4 min |
| 5 | **The linen room** | Linen room | The service key (K1) on the housekeeping trolley, the steel pipe (a broken clothes rail), a health drink, the lost-property ledger (D2). | #71 | 2 min |
| 6 | **Downstairs** | Service stairs, kitchen | K1 opens the service stairs. Below the ground floor, the stairs go on down to a chained door and a cold draught. The kitchen: a pot simmering on the stove, nobody. Through the swing door to the dining room. | #71 | 2 min |
| 7 | **The last dinner** | Dining room | Tables laid for the season's closing dinner, the food untouched and warm, the chairs pushed back as if everyone just stood up. | #71 | 2 min |
| 8 | **The night porter** | Lobby | The porter is behind the desk under his lamp, a small radio playing the song. First meeting: he greets Luca by name and gives him the room number nobody asked for (see [The night porter](#the-night-porter)). The clock wall, the key board (K2 hangs in pigeonhole 16; the hook for 22 is empty), the locked front door. Second save spot (S2). The TV room is optional. | #98 | 3 min |
| 9 | **The back office** | Back office | The key cabinet (P1), locked with a 4-digit combination. The porter's log (D3) on the desk: its last entry gives the clue. A first aid kit. The bolt on the door to the kitchen: the shortcut. | #82, #97 | 2 min |
| 10 | **Back up** | Kitchen, service stairs, first and second floors | Through the shortcut, the kitchen, the service stairs, the dark first floor and the main stairs up. Optional: room 16 with K2 (D4). The second floor is just as it was: lit, still empty. | | 3 min |
| 11 | **The clock** | Room 22 | On the nightstand, in the empty spot, there's now a flip clock, stopped at **04:47** *(working)*: the code. | #82 | 1 min |
| 12 | **The cabinet** | Back office | Back down by the same route. The code opens the cabinet: room keys on hooks, and the front door key (K3). | #82 | 3 min |
| 13 | **Checking out** | Lobby, front door | The porter, as Luca passes with K3: "Checking out already?" K3 opens the front door. | #98 | 1 min |
| 14 | **The seafront** | Outside | Short cutscene: Luca steps out into the fog. Across the road, the beach and endless rows of folded umbrellas; the song from the beach club, very far away. Fade to black, end card, back to the main menu. | new task | 1 min |

## Tension

There are no enemies in the slice. Its fear comes from tension that is built and never released: sounds, lights and things out of place. None of these events leads to a threat, and none is ever explained. No jump scare reveals anything; the payoff is that there isn't one.

Each event is a one-shot scripted trigger. They aren't saved: replaying one after loading a save is fine.

| Id | Where | Trigger | What happens |
|---|---|---|---|
| `tension_shower` | Room 21 | Entering the room | The shower runs behind the bathroom door, steam under it. Inside: nobody. Interacting turns it off. |
| `tension_phone` | Room 23 | Walking down the second floor corridor | The room phone rings behind the locked door. It stops as Luca reaches the door. |
| `tension_tray` | Outside room 26 | Seen from the corridor | A room-service tray on the floor: breakfast for two, still warm. |
| `tension_coat` | Room 26 | Looking in from the doorway | The room's lamp is off. Against the window, a tall shape stands still. With the flashlight, it's a coat on a stand. |
| `tension_curtain` | Second floor, corridor's west end | Entering the corridor | The window is open a crack and the curtain stirs. Fog drifts in. |
| `tension_flicker` | Second floor stair hall | First step down the main stairs | Every lamp on the second floor flickers once behind him, then stays on. |
| `tension_footsteps` | First floor, corridor B | First time in corridor B | Unhurried footsteps cross the floor above, then stop. Back upstairs, nobody. |
| `tension_wardrobe` | Room 13 | Entering the room | The wardrobe door creaks open. Empty hangers swing. |
| `tension_sheet` | Room 15 | Seen from the doorway | A sheet over the bed, the shape of someone lying under it. It's pillows. |
| `tension_basement` | Service stairs, below the ground floor | Looking down the stairs | The chained basement door. A cold draught from under it, and a faint sound like the sea. |
| `tension_pot` | Kitchen | Entering the kitchen | A pot simmering on a lit stove. Nobody. |

On the return trip (beat 10) the floors stay as the player left them: lit and empty upstairs, dark and empty below. No new events.

## The night porter

The first surreal local (#98). He stands behind the reception desk for the whole slice, never moves from it, and is never helpful. Draft lines, to be finished in #98:

- **First meeting**, triggered when Luca enters the lobby: *"Good evening, signor Luca. Twenty-two, as always."* After a pause: *"The signora went up already."*
- **Repeat visits**, one per interaction, in order, the last one repeating:
  - *"Breakfast is from seven until ten."*
  - *"The season's over, you know. It's always over, this time of year."*
  - *"We keep twenty-two for you. Every year."*
  - He says nothing, and turns the radio up a little.
- **Asked about the cabinet**: after D3 has been read, the next line is *"I never forget a code."*
- **Holding the front door key**: *"Checking out already?"*

Luca never answers.

## The puzzle: the key cabinet

The slice's puzzle (#82, id `puzzle_key_cabinet`): a wall-mounted key cabinet in the back office, locked with a 4-wheel combination lock. The puzzle and the route back up are to be rediscussed; this is the current version.

- **The clue.** The porter's log (D3) ends with: *"Changed the cabinet code. Same as the clock in twenty-two, so I won't forget."*
- **The answer.** The flip clock on room 22's nightstand, stopped at 04:47 *(working)*, so the code is **0447**. The clock isn't there when Luca wakes, only the spot where it stood; it appears once D3 has been read. So the trip back up is required, even for players who searched room 22 thoroughly.
- **The UI.** Four wheels, each 0–9. Up/down changes a digit, left/right moves between wheels. There's no penalty for wrong tries. The cabinet opens as soon as the wheels read the code.
- **The reward.** `key_front_door` (K3).
- **Saved state.** Solved or not.

The time on the clock is a working value. It is the only clock in the hotel that isn't simply wrong, and the slice never says what the time means (see [Two readings](#two-readings)). Keep it in data so the writers can change it.

## Encounters

None. The slice has no enemies, for now. Monsters arrive with a basement section designed later, behind `door_basement`. Its encounters, firearms and ammo budget will be designed together, following gameplay.md.

## Items

All placed by hand; nothing respawns. Pickup ids are persistent ids; item ids are #73's `ItemData` ids.

| Pickup id | Item id | Amount | Where |
|---|---|---|---|
| `pickup_plank_room22` | `wooden_plank` | 1 | Room 22, the bed's broken slat |
| `pickup_drink_room22` | `health_drink` | 1 | Room 22, bathroom cabinet |
| `pickup_pipe_linen` | `steel_pipe` | 1 | Linen room, under a collapsed shelf |
| `pickup_drink_linen` | `health_drink` | 1 | Linen room, housekeeping trolley |
| `pickup_key_service` | `key_service` | 1 | Linen room, housekeeping trolley |
| `pickup_key_room16` | `key_room_16` | 1 | Lobby, key board pigeonhole 16 |
| `pickup_aid_office` | `first_aid_kit` | 1 | Back office, wall cabinet |

`key_front_door` is the puzzle's reward, not a pickup. Documents are listed [below](#documents).

### Healing

With no enemies, nothing in the slice hurts the player, and healing can't be used at full health (#76). The budget rule (4–6 enemy hits between save spots) has nothing to cover. The slice still places a small stock, so pickups and the inventory have something real in them:

- **2 health drinks and 1 first aid kit**, 130 health, about 6.5 hits.

It all carries into the basement. When the basement is designed, its first stretch counts this stock toward its own budget.

### Weapons

The wooden plank (room 22) and the steel pipe (linen room), both from the gameplay spec. There's nothing to fight, but the player carries them into the basement. The fire axe is midgame, so it isn't placed.

## Save spots

| Id | Where | Notes |
|---|---|---|
| `save_f2_stair_hall` (S1) | Second floor, stair hall, at the top of the stairs down | The last lit place before the dark. |
| `save_gf_lobby` (S2) | Ground floor, lobby, near the glass doors | Before the puzzle and the return trip. |

Their look is placeholder (#91) until the art work. With no enemies, the "can't save while chased" refusal never fires. S1 → S2 is about 13 minutes on a first run and S2 → end about 11, inside the 15-minute guideline.

## Documents

Written in #97. Each one hints and never explains: the suicide plan is never stated, and every one keeps [two readings](#two-readings).

| Code | Id | Where | What it is |
|---|---|---|---|
| D1 | `doc_registration_card` | Room 22, desk | The hotel's registration card. Guest: Luca. Room 22. Guests: 2. Arrival: the date of the closing party. Departure: left blank. |
| D2 | `doc_lost_property` | Linen room, on the trolley | The housekeeping lost-property ledger. Things left in room 22 over many summers (a sandal, sunglasses, a hair clip, a paperback with a page folded down). The last line, in this season's hand: a men's watch, room 22, *"guest says keep it."* |
| D3 | `doc_porter_log` | Back office, desk | The night porter's log for the closing night: deadpan entries (lights out in the dining room, a complaint about the music from the beach, *"Signor Luca came in. Gave him twenty-two."*), ending with the puzzle clue. |
| D4 | `doc_postcard` | Room 16, under the mattress | A postcard of the Miramare from a summer long ago, unsent, addressed to room 22. Five words: *"Same room next year. Promise?"* The handwriting could be either of theirs. Optional, so it counts as an optional moment for the endings. |

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
| Room 22 | Phone | No signal. Battery low, and a little lower each time he looks. |
| Room 22 | Wristband | The beach club's, from the closing party. |
| Room 22 | Nightstand | Before D3 is read: a clean spot in the dust where something stood. |
| Room 22 | Beds | Two singles pushed together, one side slept in. |
| Second floor stair hall | Stairs up | Roped off. "Closed for the season." |
| First floor stair hall, lobby | Main stairs down | Sunbeds and folded umbrellas, stacked to the ceiling. |
| Stair halls | Lift | *Out of order.* The floor indicator shows a floor the hotel doesn't have. |
| Second floor | Room 24's door | "Do not disturb." The TV behind it. |
| Room 12 | Beds | The same beds as 22, stripped, the mattresses rolled up. |
| Service stairs | Basement door | Chained shut. Cold air underneath. |
| Dining room | A table | Set for the closing dinner. The food is still warm. |
| Lobby | Clock wall | Five cities, five times, none of them right. |
| Lobby | Key board | Every key on its hook except 22's. |

## Two readings

Every clue has at least two readings, and the slice confirms none (premise.md, the mystery). Nothing in it settles the open questions: the breakup reason, the canonical truth, or anything about Elena beyond the fact that she's in the town.

| Clue | One reading | Another |
|---|---|---|
| He wakes in room 22, booked under his name | He came back high and checked in, and doesn't remember | He never got here; this isn't a hotel night |
| Two beds pushed together, one side slept in | He slept alone, out of habit, on his side | Someone else was here |
| Guests: 2 on the registration card (D1) | Booked out of habit, as every summer | Elena is here (in part 2, she is) |
| Departure left blank (D1) | He didn't know how long he'd stay | There was never going to be a departure |
| *"Guest says keep it"* (D2) | Hungover generosity | Giving his things away |
| *"Signor Luca came in"* (D3) | He walked back from the rave, as the drug reading needs | The porter's log is as unreliable as the clocks |
| *"The signora went up already"* | The porter is remembering past summers | She really is upstairs |
| The lit, empty second floor; footsteps above it | A closed hotel with the lights left on, and an old building that creaks | Someone is up there, out of sight |
| Breakfast for two outside room 26 | Left over from the last guests | Meant for the two of them |
| The clock appears on the nightstand | He missed it the first time | Someone put it back |
| The clock stopped at 04:47 | A cheap clock that died at some point | A time that means something to him |
| The porter can't be reached across the desk | It's just a deep desk | He isn't there to be reached |

## What the slice needs beyond existing issues

- **The ending cutscene** (beat 14): #96 covers only the opening. It can reuse #95's cutscene support.
- **Tension events**: one-shot triggers that play a sound, move a door or flicker lights ([Tension](#tension)). No task covers them yet.
- **Lighting per floor**: second floor lit, first floor dark, ground floor dark except the porter's lamp. For the graybox (#70) and the art pass (#37).
- **Double doors** (dining ↔ lobby): two `Door`s side by side, or one wider door scene.
- **The bolt** (shortcut): a small `Interactable` that calls `unlock()` on its door.
- **Scripted world changes:** the clock appearing in room 22 and the porter's line progression. Both are saved state for #89.

### Saved world state

On top of what gameplay.md lists (pickups, doors, documents read), the slice saves `puzzle_key_cabinet` (solved), whether the clock has appeared in room 22, and the porter's line index.

## Playtest notes

Filled in by #72.
