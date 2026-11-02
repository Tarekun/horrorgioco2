## The hotel's lift (slice.md, "The lift"): one car serving GF, 1F and 2F,
## with a LiftStop on each floor. It doesn't go down to the basement.
##
## Until `power_flag` is set it is out of order: the doors and every button
## answer *Out of order.*, the floor indicators show 3, a floor the hotel
## doesn't have, and the *out of order* signs hang on the doors. Once the power
## is back (live or from a save) the signs are gone and the lift waits at
## `home_floor` with its doors shut, and the indicators show where it is.
##
## A call button brings the lift to its floor and opens the doors. Inside, a
## button for each floor: the doors close, the hum of the ride, and the doors
## open on the chosen floor. Every floor has its own car, so the ride moves
## whoever pressed the button, if they're still inside when the doors have
## shut, to the same spot in the other car. Nothing else rides: enemies never
## press a button, and the cars are carved out of the navmesh.
##
## The lift isn't saved: after loading it is back at `home_floor`, shut.

class_name Lift
extends Node3D

## Emitted when the lift has stopped at a floor and its doors are open.
signal arrived(floor_index: int)

## What the doors and buttons say before the power.
const OUT_OF_ORDER: String = "Out of order."

## What the floor indicators show before the power.
const DEAD_FLOOR_LABEL: String = "3"

## The power (the hotel's `power_restored`).
@export var power_flag: LevelFlag

## The stops, by floor from GF up.
@export var stops: Array[LiftStop] = []

## The floor indicators' label for each floor, in the same order.
@export var floor_labels: PackedStringArray = ["0", "1", "2"]

## The floor the lift waits at once the power is back.
@export var home_floor: int = 0

## The *out of order* signs on the doors, hidden once the lift works.
@export var out_of_order_signs: Array[Node3D] = []

## Seconds for the doors to open or close.
@export var door_seconds: float = 1.2

## Seconds the car takes from one floor to the next.
@export var seconds_per_floor: float = 1.8

@export_group("Sound")
## The hum of the moving car, played where the player hears it.
@export var hum_sound: AudioStreamPlayer3D
## The chime on arriving at a floor, played at that floor's doors.
@export var chime_sound: AudioStreamPlayer3D

## The floor the lift is at, or passing.
var current_floor: int = 0

## Whether the lift is busy: moving, or opening or closing its doors.
var is_moving: bool = false

var _tween: Tween


func _ready() -> void:
	current_floor = home_floor
	for index: int in stops.size():
		stops[index].called.connect(_on_stop_called.bind(index))
		stops[index].floor_picked.connect(_on_stop_floor_picked.bind(index))
	_set_out_of_order(true)
	if power_flag == null:
		push_warning("Lift %s has no power flag." % name)
		return
	power_flag.flag_set.connect(_on_power_flag_set)
	if power_flag.is_set:
		_on_power_flag_set(true)


## Whether the lift works: the power is back.
func is_working() -> bool:
	return power_flag != null and power_flag.is_set


## What the floor indicators show: 3 before the power, then the lift's floor.
func get_indicator_label() -> String:
	if not is_working():
		return DEAD_FLOOR_LABEL
	return floor_labels[current_floor]


## Brings the lift to `floor_index` and opens its doors there. Does nothing
## before the power or while the lift is busy.
func call_to(floor_index: int) -> void:
	if not is_working() or is_moving:
		return
	_start_trip(floor_index, null)


## Takes the lift to `floor_index` from inside the car: the doors close and,
## if `rider` is still in the car then, they ride along. Choosing the floor
## the lift is at just opens the doors. Does nothing before the power or while
## the lift is busy.
func ride_to(floor_index: int, rider: Node3D) -> void:
	if not is_working() or is_moving:
		return
	_start_trip(floor_index, rider)


func _start_trip(target: int, rider: Node3D) -> void:
	if target < 0 or target >= stops.size():
		return
	var start: LiftStop = stops[current_floor]
	if target == current_floor and start.is_open:
		return
	is_moving = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if target != current_floor:
		if start.is_open:
			start.add_doors_motion(_tween, false, door_seconds)
		_tween.tween_callback(_depart.bind(target, rider))
		var step: int = signi(target - current_floor)
		for i: int in absi(target - current_floor):
			_tween.tween_interval(seconds_per_floor)
			_tween.tween_callback(_pass_floor.bind(step))
		_tween.tween_callback(_stop_hum)
	_tween.tween_callback(_chime.bind(target))
	stops[target].add_doors_motion(_tween, true, door_seconds)
	_tween.tween_callback(_arrive.bind(target))


## The doors have shut: whoever is still in the car is taken along, and the
## hum starts in the car at the floor the lift is going to, where the player
## is: inside it, or waiting outside.
func _depart(target: int, rider: Node3D) -> void:
	var start: LiftStop = stops[current_floor]
	var destination: LiftStop = stops[target]
	if rider != null and is_instance_valid(rider) and start.contains(rider.global_position):
		_move_rider(rider, destination.global_position - start.global_position)
	if hum_sound:
		hum_sound.global_position = destination.get_car_center()
		hum_sound.play()


## Moves the rider into the other car while both doors are shut, so the floor
## they step out on is the chosen one. The cars are identical, so nothing on
## screen jumps.
func _move_rider(rider: Node3D, offset: Vector3) -> void:
	var player := rider as Player
	if player:
		player.move_by(offset)
	else:
		rider.global_position += offset


func _pass_floor(step: int) -> void:
	current_floor += step
	_show_indicators()


func _stop_hum() -> void:
	if hum_sound:
		hum_sound.stop()


func _chime(floor_index: int) -> void:
	if chime_sound:
		chime_sound.global_position = stops[floor_index].global_position + Vector3(0.0, 2.3, 0.2)
		chime_sound.play()


func _arrive(floor_index: int) -> void:
	is_moving = false
	arrived.emit(floor_index)


func _set_out_of_order(is_out_of_order: bool) -> void:
	for stop: LiftStop in stops:
		stop.set_out_of_order(is_out_of_order, OUT_OF_ORDER)
	for sign_node: Node3D in out_of_order_signs:
		if sign_node:
			sign_node.visible = is_out_of_order
	_show_indicators()


func _show_indicators() -> void:
	var label: String = get_indicator_label()
	for stop: LiftStop in stops:
		stop.show_floor(label)


func _on_power_flag_set(_is_loaded: bool) -> void:
	current_floor = home_floor
	_set_out_of_order(false)


func _on_stop_called(_actor: Node3D, floor_index: int) -> void:
	call_to(floor_index)


func _on_stop_floor_picked(floor_index: int, actor: Node3D, stop_index: int) -> void:
	# Only the car the lift is at can be stood in.
	if stop_index == current_floor:
		ride_to(floor_index, actor)
