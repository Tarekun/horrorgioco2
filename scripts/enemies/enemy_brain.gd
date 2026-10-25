## The enemy's state machine, as plain logic with no scene dependencies.
##
## IDLE and WANDER are the calm states: the enemy stands, then walks to a point
## nearby, then stands again. Noticing a target starts a CHASE; close enough
## (and ready to strike) it ATTACKs, then goes back to chasing. A hit that
## staggers it enters STAGGER, which interrupts whatever it was doing. A
## knocked down enemy (zero health, or a heavy blow) lies in DOWNED until its
## timer runs out and it gets up; only a stomp kills it for good, into the
## terminal DEAD state.
##
## The owner feeds tick() what it observed this frame in a Senses and acts on
## `state`, so every transition can be tested without physics.

class_name EnemyBrain
extends RefCounted

## Emitted after every state change.
signal state_changed(old_state: State, new_state: State)

enum State { IDLE, WANDER, CHASE, ATTACK, STAGGER, DOWNED, DEAD }

## Seconds spent standing before wandering off.
var idle_duration: float = 3.0
## Longest a single wander walk may last before the enemy gives up on it.
var wander_timeout: float = 8.0
## Seconds a hit keeps the enemy staggered.
var stagger_duration: float = 0.5

## Seconds spent down, set by each knock_down().
var downed_duration: float = 8.0

var state: State = State.IDLE
var time_in_state: float = 0.0


## Advances the machine by `delta` seconds.
func tick(delta: float, senses: EnemySenses) -> void:
	time_in_state += delta
	match state:
		State.IDLE:
			if senses.has_target:
				_enter(State.CHASE)
			elif time_in_state >= idle_duration:
				_enter(State.WANDER)
		State.WANDER:
			if senses.has_target:
				_enter(State.CHASE)
			elif senses.has_arrived or time_in_state >= wander_timeout:
				_enter(State.IDLE)
		State.CHASE:
			if not senses.has_target:
				_enter(State.WANDER)
			elif senses.can_attack:
				_enter(State.ATTACK)
		State.ATTACK:
			if senses.is_attack_finished:
				_enter(State.CHASE if senses.has_target else State.WANDER)
		State.STAGGER:
			if time_in_state >= stagger_duration:
				_enter(State.CHASE if senses.has_target else State.IDLE)
		State.DOWNED:
			if time_in_state >= downed_duration:
				_enter(State.CHASE if senses.has_target else State.IDLE)


## A hit interrupts the enemy. Ignored while down or dead.
func stagger() -> void:
	if state != State.DEAD and state != State.DOWNED:
		_enter(State.STAGGER)


## Knocks the enemy down for `duration` seconds. Ignored while already down
## (the first timer keeps running) and once dead.
func knock_down(duration: float) -> void:
	if state == State.DEAD or state == State.DOWNED:
		return
	downed_duration = duration
	_enter(State.DOWNED)


## The enemy dies for good, down or not.
func kill() -> void:
	if state != State.DEAD:
		_enter(State.DEAD)


func is_dead() -> bool:
	return state == State.DEAD


func is_downed() -> bool:
	return state == State.DOWNED


func _enter(new_state: State) -> void:
	var old_state: State = state
	state = new_state
	time_in_state = 0.0
	state_changed.emit(old_state, new_state)
