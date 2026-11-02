## Tests for TensionEvent, its area trigger and the action base: an event fires
## once per level load, runs its actions after their delays, and saves nothing.

extends GutTest


## An action that counts its runs and stops.
class CountingAction:
	extends TensionAction

	var starts: int = 0
	var ends: int = 0

	func _start() -> void:
		starts += 1

	func _end() -> void:
		ends += 1


var _event: TensionEvent
var _trigger: TensionTrigger
var _action: CountingAction


func before_each() -> void:
	SaveSystem.world.clear()
	_event = TensionEvent.new()
	_event.event_id = &"tension_test"
	_trigger = TensionTrigger.new()
	_event.add_child(_trigger)
	_action = CountingAction.new()
	_event.add_child(_action)
	add_child_autofree(_event)


func test_the_first_trigger_child_sets_it_off() -> void:
	assert_eq(_event.trigger, _trigger)
	assert_eq(_event.get_actions(), [_action] as Array[TensionAction])


func test_it_fires_once_however_often_its_trigger_goes_off() -> void:
	watch_signals(_event)
	_trigger.triggered.emit()
	_trigger.triggered.emit()
	assert_false(_event.fire(), "already fired")
	assert_signal_emit_count(_event, "fired", 1)
	assert_eq(_action.starts, 1)
	assert_true(_event.has_fired)


func test_firing_disarms_the_trigger() -> void:
	_event.fire()
	await wait_physics_frames(1)
	assert_false(_trigger.monitoring)


func test_a_fresh_load_fires_again_and_nothing_is_saved() -> void:
	_event.fire()
	var reloaded := TensionEvent.new()
	reloaded.add_child(TensionTrigger.new())
	add_child_autofree(reloaded)
	assert_false(reloaded.has_fired)
	assert_true(reloaded.fire())
	assert_true(SaveSystem.world.is_empty(), "no world state recorded")
	assert_false(_event.is_in_group(WorldState.GROUP))


func test_the_trigger_watches_only_the_player() -> void:
	assert_eq(_trigger.collision_mask, CombatLayers.PLAYER)
	assert_eq(_trigger.collision_layer, 0)
	watch_signals(_trigger)
	var crate := Node3D.new()
	autofree(crate)
	_trigger.body_entered.emit(crate)
	assert_signal_not_emitted(_trigger, "triggered")
	var player := Player.new()
	autofree(player)
	_trigger.body_entered.emit(player)
	assert_signal_emitted(_trigger, "triggered")


func test_an_action_waits_for_its_delay() -> void:
	_action.delay = 0.2
	_event.fire()
	assert_eq(_action.starts, 0, "not yet")
	await wait_seconds(0.3)
	assert_eq(_action.starts, 1)
	assert_true(_action.has_started)


func test_stopping_a_delayed_action_cancels_it() -> void:
	_action.delay = 0.2
	_event.fire()
	_action.stop()
	await wait_seconds(0.3)
	assert_eq(_action.starts, 0)
	assert_eq(_action.ends, 1)
