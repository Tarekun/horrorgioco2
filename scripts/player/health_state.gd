## The player's three health states, from the Health section of the gameplay
## spec. Each state has screen, audio and rumble cues (PlayerHealthCues);
## health itself is never shown as a number or a bar.

class_name HealthState
extends RefCounted

enum State { FINE, CAUTION, DANGER }

## Lowest health of Fine (60 to 100) and of Caution (30 to 59); below it is Danger.
const FINE_MIN: float = 60.0
const CAUTION_MIN: float = 30.0

## Every movement speed is multiplied by this in Danger.
const DANGER_SPEED_MULTIPLIER: float = 0.8

## The word the inventory screen's status readout shows for each state.
const STATE_NAMES: Dictionary[State, String] = {
	State.FINE: "Fine",
	State.CAUTION: "Caution",
	State.DANGER: "Danger",
}


## The state for `health` points: Fine from 60, Caution from 30, else Danger.
static func from_health(health: float) -> State:
	if health >= FINE_MIN:
		return State.FINE
	if health >= CAUTION_MIN:
		return State.CAUTION
	return State.DANGER


## The movement speed multiplier of `state`.
static func speed_multiplier(state: State) -> float:
	return DANGER_SPEED_MULTIPLIER if state == State.DANGER else 1.0


## The word for `state`: Fine, Caution or Danger.
static func state_name(state: State) -> String:
	return STATE_NAMES[state]
