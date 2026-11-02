## Tests for the Lift (slice.md, "The lift"): out of order until the power is
## back, then called to a floor, and ridden from one floor to another.

extends GutTest

const LIFT_SCENE: PackedScene = preload("res://scenes/levels/lift.tscn")
const STEP: float = 0.05
const STOREY: float = 3.2

var _flag: LevelFlag
var _sign: Node3D
var _lift: Lift


func before_each() -> void:
	SaveSystem.reset()
	_flag = LevelFlag.new()
	_flag.flag_id = &"power_restored"
	add_child_autofree(_flag)
	_sign = Node3D.new()
	add_child_autofree(_sign)
	_lift = LIFT_SCENE.instantiate() as Lift
	_lift.power_flag = _flag
	_lift.out_of_order_signs = [_sign]
	_lift.door_seconds = STEP
	_lift.seconds_per_floor = STEP
	add_child_autofree(_lift)


func after_each() -> void:
	SaveSystem.reset()


func _stop(floor_index: int) -> LiftStop:
	return _lift.stops[floor_index]


## A stand-in for whoever presses a button, at `local` in a stop's own space.
func _actor_at(floor_index: int, local: Vector3) -> Node3D:
	var actor := Node3D.new()
	add_child_autofree(actor)
	actor.global_position = _stop(floor_index).to_global(local)
	return actor


func _wait_for_arrival(floors: int) -> void:
	await wait_for_signal(_lift.arrived, STEP * (floors + 2) + 1.0)


func test_it_has_a_stop_on_gf_1f_and_2f() -> void:
	assert_eq(_lift.stops.size(), 3)
	for floor_index: int in 3:
		assert_almost_eq(_stop(floor_index).position.y, STOREY * floor_index, 0.001)


func test_before_the_power_the_indicators_show_3() -> void:
	for stop: LiftStop in _lift.stops:
		assert_eq(stop.get_indicator_text(), "3")
	assert_true(_sign.visible, "the out of order sign hangs on the doors")


func test_before_the_power_the_doors_and_call_button_answer_out_of_order() -> void:
	var actor: Node3D = _actor_at(0, Vector3(0.0, 0.0, 1.0))
	for stop: LiftStop in _lift.stops:
		assert_true(stop.get_doors_button().is_in_group(Interactable.GROUP))
		assert_eq(stop.get_doors_button().interact(actor), "Out of order.")
		assert_eq(stop.get_call_button().interact(actor), "Out of order.")
	assert_false(_lift.is_moving, "nothing moves")
	assert_false(_stop(0).is_open)


func test_before_the_power_calling_does_nothing() -> void:
	_lift.call_to(2)
	await wait_seconds(STEP * 6)
	assert_false(_lift.is_moving)
	for stop: LiftStop in _lift.stops:
		assert_false(stop.is_open)
		assert_eq(stop.get_indicator_text(), "3")


func test_after_the_power_it_works_and_shows_where_it_is() -> void:
	_flag.set_flag()
	assert_true(_lift.is_working())
	assert_false(_sign.visible)
	for stop: LiftStop in _lift.stops:
		assert_eq(stop.get_indicator_text(), "0", "waiting at GF")
		assert_false(stop.get_doors_button().is_in_group(Interactable.GROUP))
		assert_eq(stop.get_call_button().answer, "")
		assert_false(stop.is_open, "shut until called")


func test_a_loaded_power_puts_it_in_service_too() -> void:
	SaveSystem.world.record(&"power_restored", {"is_set": true})
	SaveSystem.world.apply(self)
	assert_true(_lift.is_working())
	assert_false(_sign.visible)
	assert_eq(_stop(1).get_indicator_text(), "0")


func test_a_call_button_brings_the_lift_and_opens_its_doors() -> void:
	_flag.set_flag()
	watch_signals(_lift)
	var actor: Node3D = _actor_at(2, Vector3(0.0, 0.0, 1.0))
	_stop(2).get_call_button().interact(actor)
	assert_true(_lift.is_moving)
	await _wait_for_arrival(2)
	assert_signal_emitted_with_parameters(_lift, "arrived", [2])
	assert_eq(_lift.current_floor, 2)
	assert_true(_stop(2).is_open)
	assert_false(_stop(0).is_open)
	for stop: LiftStop in _lift.stops:
		assert_eq(stop.get_indicator_text(), "2")


func test_the_indicator_follows_the_lift_floor_by_floor() -> void:
	_flag.set_flag()
	_lift.call_to(2)
	await wait_seconds(STEP * 1.5)
	assert_eq(_stop(0).get_indicator_text(), "1", "passing 1F")
	await _wait_for_arrival(2)
	assert_eq(_stop(0).get_indicator_text(), "2")


func test_calling_it_where_it_is_just_opens_the_doors() -> void:
	_flag.set_flag()
	_lift.call_to(0)
	await _wait_for_arrival(0)
	assert_true(_stop(0).is_open)
	assert_eq(_lift.current_floor, 0)


func test_a_ride_takes_the_rider_to_the_chosen_floor() -> void:
	_flag.set_flag()
	_lift.call_to(0)
	await _wait_for_arrival(0)
	var rider: Node3D = _actor_at(0, Vector3(0.3, 0.0, -1.2))
	var start: Vector3 = rider.global_position
	_stop(0).get_floor_button(2).interact(rider)
	await _wait_for_arrival(3)
	assert_eq(_lift.current_floor, 2)
	assert_almost_eq(
		rider.global_position, start + Vector3(0.0, 2.0 * STOREY, 0.0), Vector3.ONE * 0.001
	)
	assert_true(_stop(2).contains(rider.global_position))
	assert_true(_stop(2).is_open, "the doors open on 2F")
	assert_false(_stop(0).is_open)


func test_the_doors_close_before_the_ride() -> void:
	_flag.set_flag()
	_lift.call_to(0)
	await _wait_for_arrival(0)
	var rider: Node3D = _actor_at(0, Vector3(0.0, 0.0, -1.0))
	var start: Vector3 = rider.global_position
	_lift.ride_to(1, rider)
	await wait_seconds(STEP * 0.5)
	assert_false(_stop(0).is_open, "closing")
	assert_eq(rider.global_position, start, "still there while the doors close")
	await _wait_for_arrival(2)
	assert_almost_eq(rider.global_position.y, start.y + STOREY, 0.001)


func test_a_rider_who_steps_out_stays_behind() -> void:
	_flag.set_flag()
	_lift.call_to(0)
	await _wait_for_arrival(0)
	var rider: Node3D = _actor_at(0, Vector3(0.0, 0.0, -1.0))
	_lift.ride_to(2, rider)
	rider.global_position = _stop(0).to_global(Vector3(0.0, 0.0, 1.0))
	var outside: Vector3 = rider.global_position
	await _wait_for_arrival(3)
	assert_eq(_lift.current_floor, 2, "the lift goes anyway")
	assert_eq(rider.global_position, outside)


func test_only_the_rider_rides() -> void:
	_flag.set_flag()
	_lift.call_to(0)
	await _wait_for_arrival(0)
	var rider: Node3D = _actor_at(0, Vector3(-0.4, 0.0, -1.0))
	var stowaway: Node3D = _actor_at(0, Vector3(0.4, 0.0, -1.0))
	var stowaway_start: Vector3 = stowaway.global_position
	_lift.ride_to(1, rider)
	await _wait_for_arrival(2)
	assert_eq(stowaway.global_position, stowaway_start, "nothing else is carried")


func test_picking_the_floor_it_is_at_reopens_the_doors() -> void:
	_flag.set_flag()
	_lift.call_to(1)
	await _wait_for_arrival(1)
	var rider: Node3D = _actor_at(1, Vector3(0.0, 0.0, -1.0))
	var start: Vector3 = rider.global_position
	_stop(1).get_floor_button(1).interact(rider)
	assert_false(_lift.is_moving, "already open: nothing to do")
	assert_eq(rider.global_position, start)


func test_a_busy_lift_ignores_other_calls() -> void:
	_flag.set_flag()
	_lift.call_to(2)
	_lift.call_to(1)
	await _wait_for_arrival(2)
	assert_eq(_lift.current_floor, 2)
	assert_false(_stop(1).is_open)


func test_the_buttons_of_a_car_the_lift_is_not_at_do_nothing() -> void:
	_flag.set_flag()
	var actor: Node3D = _actor_at(2, Vector3(0.0, 0.0, -1.0))
	_stop(2).get_floor_button(1).interact(actor)
	assert_false(_lift.is_moving)
	assert_eq(_lift.current_floor, 0)
