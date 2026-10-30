# Vertical slice: Hotel Miramare

The reference for building the slice: layout, beats, tension, encounters, items, save spots, documents and the puzzle. Story and pillars live in [premise.md](premise.md), rules and numbers in [gameplay.md](gameplay.md), the look in [visual-style.md](visual-style.md).

Names marked *working* are placeholders, as in premise.md. Ids in `code` are the ones the implementation uses (item ids for #73, persistent ids for #89).

## Summary

- **Starts** at a new game with Luca waking in room 22, their old room. **Ends** when he unlocks the front door himself and steps out onto the seafront in the fog.
- **The whole hotel:** three floors and a basement. **2F**, where their room is, lit and empty; **1F**, dark; **GF**, with the dining room, kitchen and the lobby; and the **basement**, the hotel's service level, dark and chained shut. There's nothing above 2F.
- **The loop:**
  - pull the plank off a doorless room on 2F to get a weapon and the stairs key;
  - go down to the dark 1F; the stairs don't go further, because the GF door is blocked;
  - slide down a builders' rubble chute from a building site on 1F to GF, and move the obstacle blocking the stairs;
  - the porter won't open the front door; the clue to the key cabinet sends Luca back up;
  - the cabinet on 1F gives the basement key;
  - in the basement he brings the power back: the lights reveal the first enemy, the lift starts working, and upstairs the porter is gone;
  - past two more enemies, the porter's locker holds the front door key; he goes back up to an empty lobby and lets himself out.
- **Enemies only in the basement.** Above ground the slice is all tension that never pays off: sounds, lights and things out of place, and nothing ever attacks. That also makes a night porter calmly on duty plausible. The basement is where it pays off: three enemies in two encounters, melee only.
- **Three save spots**, about 40 minutes of play on a first run.

What's not in the slice: firearms, the prologue (the rave night), the crossovers with part 2, the fire axe (a midgame weapon), other locals, any other location, and the lift's later role (see [the lift](#the-lift)).

## The hotel

A family hotel on the seafront, built in the 1960s and redone in the 80s: terrazzo floors, wood-panelled reception, pastel tiles, brass room numbers. It has three floors, GF (ground floor), 1F (first floor) and 2F (second floor), and a basement below GF. **The hotel is closed**: the season is over, there are no guests, and the porter says so. The sunbeds and umbrellas from its beach concession are stacked inside for the winter.

- **One staircase**, at the west end of the corridor on every floor, behind a door. It goes down to the basement. The middle of each floor is a lift hall with a lift that doesn't work until the power comes back ([the power](#the-power)).
- **Two rooms are building sites**: room 15 on 1F and the room right below it on GF, joined by a yellow rubble chute. Nothing else in the hotel is being worked on, and nothing says why these two are.
- **The basement** is the service level: laundry, boiler room, stores and the staff quarters. Guests never went down there.

**Lighting by floor:**
- **2F:** all the lamps are on, warm and steady. It looks open for business, and it's empty.
- **1F:** every lamp is off. The flashlight is the only light.
- **GF:** dark, except the porter's desk lamp in the lobby.
- **Basement:** no power at all. Once it's back, only the boiler room is lit; the rest stays dark.

Outside the windows it's a dusk that doesn't match any clock. Every clock in the hotel shows a different time, except one (see [the puzzle](#the-puzzle-the-key-cabinet)).

Dimensions below are approximate, for the graybox (#70). Every level has the same footprint, about 30 × 14 m, with 6 × 6 m rooms, a 2 m corridor and 3 m ceilings. The staircase, the lift and the two building sites line up across the floors.

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
- **Lift hall**: the lift's doors are shut, with an *out of order* sign, until the power comes back.
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
 │DINING ROOM                        │LOBBY     front door K4│
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
- **Below GF** the stairs go on down to the basement door, chained shut until K3. It can be seen from 1F before GF is reached, since only the GF door is blocked.

### Basement (dark)

```
                   north: under the seafront
 0m          6m          12m         18m         24m         30m
 ┌───────────────────────┬───────────┬───────────┬───────────┐
 │LAUNDRY                │BOILER ROOM│LIFT       │CHANGING   │
 │washing machines,      │switchboard│MACHINERY  │ROOM       │
 │linen carts,           │           │(solid,    │porter's   │
 │sheets on lines        │E1 behind  │heard, not │locker: K4 │
 │                       │the boilers│seen)      │           │
 ├─────────   ───────────┼────   ────┼───────────┼────   ────┤
 │ corridor (dark)           button  ┃ staff corridor  E2    │
 ├────▒▒▒────┼────▒▒▒────┼────▒▒▒────┼───────────┼────   ────┤
 │STAIRS     │STORAGE    │PANTRY     │plumbing   │STAFF ROOM │
 │ ↑ GF      │locked     │locked     │(solid)    │E3,        │
 │ S3        │           │           │           │door open  │
 │           │           │           │           │           │
 │           │           │           │           │           │
 └───────────┴───────────┴───────────┴───────────┴───────────┘
                    south: under the street
```

- **The stairs** end at a landing with the third save spot (S3) and the basement door, chained shut. K3 opens the padlock. It's a heavy fire door that swings shut by itself, and enemies can't open doors, so the landing is always safe.
- **Corridor**: dark, low, pipes along the ceiling. Halfway along, a **roller shutter** (`┃`) closes it off from the staff quarters, with a wall button beside it ([the roller shutter](#the-roller-shutter)).
- **Laundry**: washing machines, linen carts, sheets hung on lines across the room. Open, with nothing to take. It's the room to back off into during the first fight.
- **Boiler room**: two old boilers and, on the wall facing the door, the hotel's main switchboard ([the power](#the-power)). E1 stands in the gap behind the boilers, out of sight from the door and the switchboard.
- **Lift machinery**: under the lift hall, walled off. It's only heard: silent before the power, groaning and ticking after.
- **Staff corridor**: the far side of the shutter. E2 wanders here.
- **Staff room**: a table, chairs, a hotplate. Its door stands open; E3 waits inside.
- **Changing room**: two rows of staff lockers. The porter's is ajar, with his coat on the hanger and the front door key (K4) on the hook.
- **Storage and pantry** are locked, with no key in the slice.

### Legend

| Code | Meaning |
|---|---|
| `   ` (gap in a wall) | Doorway with an unlocked door |
| `▒▒▒` | Locked door (key shown next to it or in the table below) |
| `=W=` | Doorless doorway with a plank across it: [the blockade](#the-blockade) |
| `≡≡≡` | Door blocked by an obstacle on the corridor side: [the obstacle](#the-obstacle) |
| `┃` | Roller shutter across the corridor: [the roller shutter](#the-roller-shutter) |
| ↑ ↓ | Stairs up or down |
| S1–S3 | Save spots |
| K1–K4 | Key items |
| D1–D4 | Documents |
| E1–E3 | Enemies ([Encounters](#encounters)) |
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
| `door_building_site_gf` | Building site ↔ corridor, GF | unlocked | |
| `door_kitchen` | Kitchen ↔ corridor, GF | unlocked | |
| `door_dining_corridor` | Dining room ↔ corridor, GF | unlocked | |
| `door_dining_lobby` | Dining room ↔ lobby (glass, double), GF | unlocked | |
| `door_office_lobby` | Back office ↔ lobby, behind the desk | unlocked | |
| `door_tv_room` | TV room ↔ lobby | unlocked | |
| `door_front` | Lobby ↔ seafront | locked | `key_front_door` (K4), ends the slice |
| `door_basement` | Stairs ↔ basement corridor | locked ("Chained shut."), self-closing | `key_basement` (K3) |
| `door_laundry` | Laundry, basement | unlocked | |
| `door_boiler_room` | Boiler room, basement | unlocked | |
| `door_storage` | Storage, basement | locked | nothing |
| `door_pantry` | Pantry, basement | locked | nothing |
| `shutter_staff` | Basement corridor | down | its button, once the power is back ([the roller shutter](#the-roller-shutter)) |
| `door_staff_room` | Staff room, basement | unlocked, wedged open | |
| `door_changing_room` | Changing room, basement | unlocked | |

Locked doors with no key answer "It's locked." unless the table gives another line.

**Progression.**
1. The blockade gives the plank and K1.
2. K1 opens the stairs on 2F and 1F.
3. The chute takes Luca from 1F to GF, and the obstacle then opens the stairs on GF.
4. P1 needs the code from room 22, and solving it gives K3.
5. K3 opens the basement.
6. The switchboard brings the power back, which opens the shutter's way.
7. K4 is in the porter's locker, and it ends the slice.

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

### The power

The basement has no power when Luca arrives. The main switchboard in the boiler room (`switchboard_basement`) brings it back: a big lever, prompt *"Throw the main switch."* It's a one-time action, and it does four things at once:

1. **The boiler room's lights** stutter on, and E1 is standing behind the boilers. It turns to Luca: the first fight starts ([Encounters](#encounters)).
2. **The shutter's button** works from now on.
3. **The lift** works from now on: in the basement the machinery groans awake behind the wall ([the lift](#the-lift)).
4. **The porter is gone.** Luca is in the basement and doesn't see it. Next time he's in the lobby, the desk is empty: the lamp on, the radio playing, the chair empty. He doesn't have the front door key yet.

Nothing else changes: 1F and GF stay dark, and 2F stays lit. Saved as one flag, `power_restored`, which the four effects read.

### The roller shutter

A metal roller shutter (`shutter_staff`) closes the basement corridor off from the staff quarters, with a button on the wall beside it.

- **Before the power:** *"Nothing happens."* The prompt stays, so the player knows it matters.
- **After the power:** it rolls up in about 3 s, loud enough to wake the far side. It makes a noise event of **12 m** *(working)*, which covers the whole staff area, so E2 and E3 both come (the second fight).
- It stays up. Saved as up or down.

### The lift

Out of order on every floor until the power comes back. From then on it works between **GF, 1F and 2F**: call button, doors, a short ride (the doors close, a hum, they open on the other floor). It doesn't go down to the basement.

In the slice it adds little: by then the stairs are open everywhere, and the way out is on GF. It's there because the lift has a bigger role later, as a way to somewhere that opens a different ending. That role isn't designed here. The floor indicator showing 3 (see [Examinables](#examinables)) is the only hint, and it stays unexplained.

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
| 12 | **The cabinet** | 1F linen room | The code opens the cabinet: the hotel's spare keys on hooks, and one on its own with a handwritten tag, *Basement* (K3). | #82 | 2 min |
| 13 | **Down** | Stairs, basement landing | All the way down the stairs, past GF, to the chained door. Third save spot (S3). K3 opens the padlock, the chain drops, and the door swings shut behind him. | #71 | 1 min |
| 14 | **The basement** | Corridor, laundry | Low, dark, pipes overhead. Sheets hanging in the laundry. The roller shutter's button does nothing. The boiler room door is open. | #70 | 2 min |
| 15 | **The power** | Boiler room | He throws the main switch. The lights stutter on, and something is standing behind the boilers. It turns. **First fight**, one on one, in the light. Behind the wall, the lift machinery groans awake. Upstairs, unseen, the porter leaves the desk ([the power](#the-power)). | new task, #71 | 3 min |
| 16 | **The shutter** | Basement corridor, staff corridor | Now the button works. The shutter rolls up loudly, into the dark of the staff quarters, and two of them come at the noise. **Second fight**, two at once, in the dark. | new task, #71 | 3 min |
| 17 | **The locker** | Changing room | The porter's locker stands ajar: his coat on the hanger, the front door key (K4) on the hook. | #71 | 1 min |
| 18 | **The empty desk** | Stairs, lobby | Back up to the lobby. The porter is gone: the lamp still on, the radio still playing, his chair empty. The lift's call button is lit; riding it is optional. K4 opens the front door. | #98 | 2 min |
| 19 | **The seafront** | Outside | Short cutscene: Luca steps out into the fog. Across the road, the beach and endless rows of folded umbrellas; the song from the beach club, very far away. Fade to black, end card, back to the main menu. | new task | 1 min |

## Tension

Above ground there are no enemies. The fear there comes from tension that is built and never released: sounds, lights and things out of place. None of these events leads to a threat, and none is ever explained. No jump scare reveals anything; the payoff is that there isn't one, until the basement.

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
| `tension_basement` | Stairs, below GF | Looking down the last flight, before K3 | The chained basement door. A cold draught from under it, and a faint sound like the sea. |
| `tension_pot` | Kitchen | Entering the kitchen | A pot simmering on a lit stove. Nobody. |
| `tension_sheets` | Basement laundry | Entering the laundry | In the flashlight, a shape stands behind one of the hanging sheets. It's a linen cart. The last false alarm before a real one. |

On the return trips (beats 10 and 18) the floors stay as the player left them: lit and empty upstairs, dark and empty below. No new events. After the power, the only changes upstairs are the empty desk and the working lift.

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
- **The basement** *(optional)*: if Luca talks to him while carrying K3, the next line is *"The basement is staff only, signor Luca."* He doesn't stop him. The route from the cabinet to the basement doesn't pass the lobby, so many players won't hear it.
- **Gone**: as soon as the power is back ([the power](#the-power)), the porter is no longer in the lobby. His lamp stays on and his radio keeps playing.

Luca never answers.

## The puzzle: the key cabinet

The slice's puzzle (#82, id `puzzle_key_cabinet`): the housekeeping key cabinet in the 1F linen room, locked with a 4-wheel combination lock. Solving it means leaving the lobby area: the clue is downstairs, the code is on 2F and the cabinet is on 1F.

- **The clue.** The porter's log (D3) ends with: *"Changed the code on the key cabinet upstairs. Same as the clock in twenty-two, so I won't forget."*
- **The answer.** The flip clock on room 22's nightstand, stopped at 04:47 *(working)*, so the code is **0447**. The clock isn't there when Luca wakes, only the spot where it stood; it appears once D3 has been read. So the trip back up is required, even for players who searched room 22 thoroughly.
- **The UI.** Four wheels, each 0–9. Up/down changes a digit, left/right moves between wheels. There's no penalty for wrong tries. The cabinet opens as soon as the wheels read the code.
- **The reward.** `key_basement` (K3).
- **Saved state.** Solved or not.

The time on the clock is a working value. It is the only clock in the hotel that isn't simply wrong, and the slice never says what the time means (see [Two readings](#two-readings)). Keep it in data so the writers can change it.

## Encounters

All in the basement: three standard enemies (#111's placeholder monster, 100 health, values from gameplay.md) in two encounters. Melee only: the player has the plank and the steel pipe, and there's no ammo in the slice.

| Code | Id | Where | Starts | Encounter |
|---|---|---|---|---|
| E1 | `enemy_boiler_room` | Boiler room, behind the boilers | dormant until the power | The lights |
| E2 | `enemy_staff_corridor` | Staff corridor | WANDER, inside the staff quarters | The shutter |
| E3 | `enemy_staff_room` | Staff room, door wedged open | IDLE | The shutter |

### The lights (E1)

The first fight, and the one that teaches fighting: one on one, in a lit room.

- **Before the power** E1 is **dormant**: it stands still in the gap behind the boilers and doesn't see or hear. The gap can't be seen from the door or the switchboard, so the flashlight doesn't give it away.
- **Throwing the switch** lights the room and wakes E1, already alerted to Luca, about 4 m away.
- **Room to move:** the boiler room opens onto the corridor, and the laundry is across it.
- **Expected fight:** about 8 hits with the pipe or 11 with the plank. A fully charged heavy knocks it down and a stomp finishes it, which is easy to read in the light.
- **On load:** once `power_restored` is saved, E1 starts awake at its placed position, like any other enemy.

### The shutter (E2, E3)

The second fight: two at once, in the dark.

- **The shutter's noise** reaches both: E2 from the staff corridor, E3 from the staff room. They come at the opening together.
- **The opening is a 2 m bottleneck**, and the lit boiler room is a few steps back. Holding there, in the light, is the smart answer; fighting in the staff quarters means the flashlight, which gets him seen from 18 m.
- **Two at once** is where knockdowns matter: a charged heavy floors one for about 8 s, long enough to fight the other, then stomp.
- **No sneaking past:** the noise always wakes them, and the changing room is at the far end. Retreat is always possible (see below).

### Retreat and saving

The basement door closes behind Luca and enemies can't open doors, so going back up the stairs always breaks a chase. After 6 s without a sighting they lose track and S3 works again. That makes S3 a save spot "before a major encounter" where the player can't be trapped (gameplay.md). Dead enemies stay dead and leave corpses; living ones come back at their placed positions with full health when a save is loaded.

### Damage

A first-time player should take 2–5 hits across both fights, 15–25 each. The healing they carry in covers that ([Healing](#healing)).

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
| `pickup_key_front_door` | `key_front_door` | 1 | Basement changing room, the porter's locker |

`key_basement` is the puzzle's reward, not a pickup. Documents are listed [below](#documents).

### Healing

Nothing above ground hurts the player, so the whole healing stock is there for the basement: **2 health drinks and 1 first aid kit**, 130 health, about 6.5 hits of 20. That's the gameplay.md budget for the stretch from S3 to the end (healing for 4–6 enemy hits between save spots), at its generous end because these are the player's first fights. All three are on or next to the critical path, so a player reaches S3 with the full stock. No healing is placed in the basement.

### Weapons

The wooden plank (room 28's blockade) and the steel pipe (room 15), both from the gameplay spec. The pipe is the better weapon for the basement: more damage and reach for a little more stamina. The fire axe is midgame, so it isn't placed. There are no firearms, so the ammo budget doesn't apply.

## Save spots

| Id | Where | Notes |
|---|---|---|
| `save_2f_corridor` (S1) | 2F, west end of the corridor, by the stairs door | The last lit place before the dark. |
| `save_gf_lobby` (S2) | GF, lobby, near the glass doors | Before the puzzle and the return trip. |
| `save_basement_stairs` (S3) | Basement landing, outside the basement door | Before the encounters. Enemies can't reach it. |

Their look is placeholder (#91) until the art work. On a first run, S1 → S2 is about 12 minutes, S2 → S3 about 8, and S3 → end about 12, inside the 15-minute guideline.

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
| K3 | `key_basement` | Basement key | Key cabinet (P1) | `door_basement` |
| K4 | `key_front_door` | Front door key | Basement, the porter's locker | `door_front` |

## Examinables

Things to look at (#79). Each has one or two lines, and none is explained.

| Where | Object | Gist |
|---|---|---|
| Room 22 | Phone | No signal. Battery low, and a little lower each time he looks. |
| Room 22 | Wristband | The beach club's, from the closing party. |
| Room 22 | Nightstand | Before D3 is read: a clean spot in the dust where something stood. |
| Room 22 | Beds | Two singles pushed together, one side slept in. |
| Lift halls, lobby | Lift, before the power | *Out of order.* The floor indicator shows 3, a floor the hotel doesn't have. |
| Lift halls, lobby | Lift, after the power | It works. The indicator shows where it is. |
| 2F | Room 24's door | "Do not disturb." The TV behind it. |
| Room 28 | Chair | Set in the middle of the empty room, facing the window. |
| Room 12 | Beds | The same beds as 22, stripped, the mattresses rolled up. |
| Room 15, GF building site | Building work | Only these two rooms. No sign of who's doing it, or why. |
| Stairs, below GF | Basement door | Before K3: chained shut, cold air underneath. |
| Dining room | A table | Set for the closing dinner. The food is still warm. |
| Lobby | Clock wall | Five cities, five times, none of them right. |
| Lobby | Key board | Every key on its hook except 22's. |
| Basement corridor | Roller shutter | Before the power: the button does nothing. |
| Boiler room | Switchboard | Every breaker down, as if someone threw them all. |
| Changing room | The porter's locker | His coat on the hanger. The name card on the door is blank. |
| Lobby, after the power | The desk | The lamp on, the radio playing, the chair empty. |

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
| Monsters behind a chained door, under a hotel the porter calmly runs | The drug: the fear upstairs finally takes a shape | The chain was there to keep them in |
| The porter is gone once the power is back, before Luca has the key | He went to see what woke the building | He was only there to keep him in |
| The front door key in the porter's locker, with his coat | He left it for the morning shift | He never left, or was never there |

## What the slice needs beyond existing issues

- **The blockade** (room 28): an interactable that gives the plank and clears the doorway. Close to a pickup (#74), plus the collision removal.
- **The chute** (room 15): an interactable that plays a short sequence (#95) and moves the player to the skip on GF.
- **The obstacle** (GF): an interactable that rolls the sunbeds clear and frees `door_stairs_gf`.
- **The power** (basement): the switchboard interactable and the `power_restored` flag, with its effects: the boiler room lights and waking E1, the shutter, the lift, and the porter leaving.
- **The roller shutter**: blocks the corridor until it's powered and raised; raising it makes a noise event (#27).
- **The lift**: call buttons, doors and a short ride between GF, 1F and 2F once the power is back.
- **A dormant enemy start** for E1: no perception until an event wakes it (#27, #71).
- **A self-closing door** for `door_basement`. It has to close fast enough that a chasing enemy can't slip through.
- **The porter** (#98): the front door refusal, the staff-only line, and leaving when the power comes back.
- **The ending cutscene** (beat 19): #96 covers only the opening. It can reuse #95's cutscene support.
- **Tension events**: one-shot triggers that play a sound, move a door or flicker lights ([Tension](#tension)). No task covers them yet.
- **Lighting per floor**: 2F lit, 1F dark, GF dark except the porter's lamp, the basement dark until the boiler room lights. For the graybox (#70) and the art pass (#37).
- **Double doors** (dining room ↔ lobby): two `Door`s side by side, or one wider door scene.
- **Scripted world changes:** the clock appearing in room 22 and the porter's line progression. Both are saved state for #89.

### Saved world state

On top of what gameplay.md lists (pickups, doors, documents read, dead enemies), the slice saves:

- the blockade taken and the obstacle moved;
- `puzzle_key_cabinet` (solved);
- `power_restored`, which also means E1 awake, the porter gone and the lift working;
- the shutter up;
- whether the clock has appeared in room 22;
- the porter's line index.

## Playtest notes

Filled in by #72.
