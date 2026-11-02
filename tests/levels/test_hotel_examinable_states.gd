## Tests for the hotel's examinables whose text reads the saved world state
## (slice.md, "Examinables"): the nightstand in room 22 and the porter's log,
## the lift, the desk, the shutter and the switchboard and the power, the
## basement door and its key, and the phone's battery.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/hotel_miramare.tscn")

const LIFTS: Array[String] = [
	"SecondFloor/LiftSecondFloor", "FirstFloor/LiftFirstFloor", "GroundFloor/LiftGroundFloor"
]

## Examinables that read the power: path -> when they can be examined.
const POWERED: Dictionary[String, StateExaminable.Shown] = {
	"SecondFloor/LiftSecondFloor": StateExaminable.Shown.ALWAYS,
	"FirstFloor/LiftFirstFloor": StateExaminable.Shown.ALWAYS,
	"GroundFloor/LiftGroundFloor": StateExaminable.Shown.ALWAYS,
	"GroundFloor/ReceptionDesk": StateExaminable.Shown.AFTER,
	"Basement/RollerShutter": StateExaminable.Shown.BEFORE,
	"Basement/Switchboard": StateExaminable.Shown.ALWAYS,
}

var _level: Node3D


func before_each() -> void:
	SaveSystem.reset()
	_level = LEVEL_SCENE.instantiate() as Node3D
	add_child_autofree(_level)


func after_each() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _examinable(path: String) -> StateExaminable:
	return _level.get_node("Examinables/" + path) as StateExaminable


func _flag(flag_name: String) -> LevelFlag:
	return _level.get_node("LevelFlags/" + flag_name) as LevelFlag


func _load_flag(flag_id: StringName) -> void:
	SaveSystem.world.record(flag_id, {"is_set": true})
	SaveSystem.world.apply(_level)


func test_the_porter_log_flag_is_placed() -> void:
	assert_eq(_flag("PorterLogRead").flag_id, &"doc_porter_log_read")
	assert_eq(_examinable("SecondFloor/NightstandRoom22").flag, _flag("PorterLogRead"))


func test_the_power_examinables_read_the_power() -> void:
	for path: String in POWERED:
		assert_eq(_examinable(path).flag, _flag("PowerRestored"), path)
		assert_eq(_examinable(path).shown, POWERED[path], path)


func test_the_nightstand_is_empty_until_the_log_is_read() -> void:
	var nightstand: StateExaminable = _examinable("SecondFloor/NightstandRoom22")
	var before: String = nightstand.interact(null)
	assert_string_contains(before, "dust")
	_flag("PorterLogRead").set_flag()
	var after: String = nightstand.interact(null)
	assert_string_contains(after, "clock")
	assert_ne(after, before)


func test_a_loaded_log_read_shows_the_clock_on_the_nightstand() -> void:
	_load_flag(&"doc_porter_log_read")
	assert_string_contains(_examinable("SecondFloor/NightstandRoom22").interact(null), "clock")


func test_the_lift_is_out_of_order_until_the_power() -> void:
	for path: String in LIFTS:
		var lift: StateExaminable = _examinable(path)
		assert_eq(lift.interact(null), "Out of order.", path)
		assert_string_contains(lift.interact(null), "3", path)
	_flag("PowerRestored").set_flag()
	for path: String in LIFTS:
		assert_eq(_examinable(path).interact(null), "It works now.", path)


func test_a_loaded_power_has_the_lift_working() -> void:
	_load_flag(&"power_restored")
	for path: String in LIFTS:
		assert_eq(_examinable(path).interact(null), "It works now.", path)


func test_the_desk_is_examinable_only_once_the_porter_is_gone() -> void:
	var desk: StateExaminable = _examinable("GroundFloor/ReceptionDesk")
	assert_false(desk.is_in_group(Interactable.GROUP))
	_flag("PowerRestored").set_flag()
	assert_true(desk.is_in_group(Interactable.GROUP))
	assert_string_contains(desk.interact(null), "lamp")
	assert_string_contains(desk.interact(null), "empty")


func test_a_loaded_power_leaves_the_desk_empty() -> void:
	_load_flag(&"power_restored")
	assert_true(_examinable("GroundFloor/ReceptionDesk").is_in_group(Interactable.GROUP))


func test_the_shutter_is_examinable_only_before_the_power() -> void:
	var shutter: StateExaminable = _examinable("Basement/RollerShutter")
	assert_true(shutter.is_in_group(Interactable.GROUP))
	assert_string_contains(shutter.interact(null), "shutter")
	_load_flag(&"power_restored")
	assert_false(shutter.is_in_group(Interactable.GROUP))


func test_the_breakers_stay_down_after_the_power() -> void:
	var switchboard: StateExaminable = _examinable("Basement/Switchboard")
	var before: String = switchboard.interact(null)
	assert_string_contains(before, "breaker")
	_flag("PowerRestored").set_flag()
	assert_ne(switchboard.interact(null), before)


func test_the_basement_door_examinable_follows_its_lock() -> void:
	var door := _level.get_node("Doors/Basement/DoorBasement") as Door
	var chain: StateExaminable = _examinable("Basement/BasementDoor")
	assert_eq(chain.door, door)
	var before: String = chain.interact(null)
	assert_string_contains(before, "Chained")
	door.unlock()
	assert_ne(chain.interact(null), before)


func test_a_loaded_unlocked_basement_door_drops_the_chain() -> void:
	SaveSystem.world.record(&"door_basement", {"is_locked": false})
	SaveSystem.world.apply(_level)
	assert_true(_examinable("Basement/BasementDoor").is_changed())


func test_the_phone_battery_drops_each_look() -> void:
	var phone := _level.get_node("Examinables/SecondFloor/PhoneRoom22") as PhoneExaminable
	var readings: Array[String] = []
	for i: int in 3:
		phone.restart()
		phone.interact(null)
		readings.append(phone.interact(null))
	assert_eq(readings, ["Battery 9%.", "Battery 8%.", "Battery 7%."] as Array[String])


func test_luca_reads_the_phone_on_waking() -> void:
	var player := _level.get_node("Player") as Player
	var phone := _level.get_node("Examinables/SecondFloor/PhoneRoom22") as Examinable
	player.global_position = Vector3(28.7, 6.4, -2.4)
	player.look_at(Vector3(phone.global_position.x, 6.4, phone.global_position.z))
	var interaction := player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, phone)
	interaction.interact()
	assert_eq(interaction.hint.message_label.text, "His phone. No signal.")
