## Tests for the hotel's tension events against slice.md's Tension table: all
## eleven are placed, each fires once when the player walks into (or looks from)
## its spot, and none hurts the player or wakes an enemy.

extends "res://tests/levels/hotel_level_test.gd"

const NoiseListener: GDScript = preload("res://tests/combat/noise_listener.gd")

## Event id -> where the player stands to set it off (feet).
const SPOTS: Dictionary[StringName, Vector3] = {
	&"tension_shower": Vector3(27.5, SECOND_Y + 0.1, 5),
	&"tension_phone": Vector3(21, SECOND_Y + 0.1, 0),
	&"tension_tray": Vector3(13, SECOND_Y + 0.1, 0),
	&"tension_coat": Vector3(9, SECOND_Y + 0.1, 0.2),
	&"tension_curtain": Vector3(27, SECOND_Y + 0.1, 0),
	&"tension_flicker": Vector3(4.5, SECOND_Y - 0.3, 3.4),
	&"tension_footsteps": Vector3(3, FIRST_Y + 0.1, 0),
	&"tension_wardrobe": Vector3(15, FIRST_Y + 0.1, 3),
	&"tension_basement": Vector3(1.5, BASEMENT_Y + 1.7, 6.2),
	&"tension_pot": Vector3(13.5, GROUND_Y + 0.1, 3),
	&"tension_sheets": Vector3(7, BASEMENT_Y + 0.1, -2),
}

## Physics frames to wait for a trigger to notice the player.
const MAX_FRAMES: int = 30

var _player: Player
var _eye: Camera3D


func before_each() -> void:
	await super.before_each()
	_player = _level.get_node("Player") as Player
	_eye = Camera3D.new()
	_level.add_child(_eye)


func test_the_events_are_the_ones_in_the_doc() -> void:
	var ids: Array[StringName] = []
	for event: TensionEvent in _events():
		ids.append(event.event_id)
		assert_not_null(event.trigger, "%s has a trigger" % event.event_id)
		assert_false(event.get_actions().is_empty(), "%s does something" % event.event_id)
	assert_eq(ids.size(), SPOTS.size())
	for event_id: StringName in SPOTS:
		assert_has(ids, event_id)


func test_each_event_fires_once_from_its_spot() -> void:
	await _open(&"door_room_26")
	for event: TensionEvent in _events():
		watch_signals(event)
		await _visit(event)
		assert_true(event.has_fired, "%s fires" % event.event_id)
		# Leave and come back: nothing more.
		_player.global_position = _spawn()
		await wait_physics_frames(3)
		await _visit(event)
		assert_signal_emit_count(event, "fired", 1, str(event.event_id))


func test_the_sight_events_need_a_clear_view() -> void:
	# Room 26's door is shut: the coat can't be seen from the corridor.
	var coat: TensionEvent = _event(&"tension_coat")
	var sight := coat.trigger as TensionSight
	await _visit(coat)
	assert_false(coat.has_fired, "door shut")
	await _open(&"door_room_26")
	await wait_seconds(_door(&"door_room_26").swing_time + 0.1)
	assert_true(sight.sees(_eye.global_transform), "door open")


func test_none_hurts_the_player_or_wakes_an_enemy() -> void:
	var listener: Node = NoiseListener.new()
	listener.add_to_group(NoiseEvent.HEARING_GROUP)
	add_child_autofree(listener)
	for event: TensionEvent in _events():
		event.fire()
		assert_eq(event.find_children("*", "Hitbox").size(), 0, str(event.event_id))
	await wait_seconds(3.0)
	assert_eq(listener.get(&"sink"), [] as Array[float], "no noise for enemies")
	var health: HealthComponent = _player.health_component
	assert_eq(health.current_health, health.max_health)
	for enemy: Enemy in _enemies():
		assert_false(enemy.is_chasing(), str(enemy.name))
	assert_true(_enemies()[0].is_dormant, "E1 still asleep")


func test_the_sounds_play_on_the_sfx_or_ambience_bus() -> void:
	var sounds: Array[Node] = _level.get_node("TensionEvents").find_children("*", "TensionSound")
	assert_gt(sounds.size(), 10)
	for node: Node in sounds:
		var sound := node as TensionSound
		assert_not_null(sound.stream, str(sound.get_path()))
		assert_has([AudioBuses.SFX, AudioBuses.AMBIENCE], sound.get_player().bus)


func test_the_shower_is_turned_off_with_interact() -> void:
	var shower: TensionEvent = _event(&"tension_shower")
	shower.fire()
	var water := shower.get_node("Water") as TensionSound
	var steam := shower.get_node("SteamParticles") as CPUParticles3D
	assert_true(water.is_playing())
	assert_true(steam.emitting)
	# In the bathroom doorway, facing the shower.
	_player.global_position = Vector3(25, SECOND_Y + 0.1, 3.4)
	_player.rotation.y = 0.0
	var interaction := _player.get_node("PlayerInteraction") as PlayerInteraction
	interaction.update_focus()
	assert_eq(interaction.focus, shower.get_node("Tap"))
	assert_true(interaction.interact())
	assert_false(water.is_playing(), "water off")
	assert_false(steam.emitting, "no more steam")


func test_the_phone_stops_as_luca_reaches_the_door() -> void:
	var phone: TensionEvent = _event(&"tension_phone")
	await _visit(phone)
	var ring := phone.get_node("Ring") as TensionSound
	assert_true(ring.is_playing(), "ringing")
	_player.global_position = Vector3(15, SECOND_Y + 0.1, 0.3)
	await wait_physics_frames(5)
	assert_false(ring.is_playing(), "stopped at the door")


func test_the_2f_lamps_flicker_and_stay_on() -> void:
	var lamp := _level.get_node("Lights/SecondFloor/CorridorLamp") as Light3D
	var energy: float = lamp.light_energy
	var flicker: TensionEvent = _event(&"tension_flicker")
	var lamps := flicker.get_node("Lamps") as TensionFlicker
	flicker.fire()
	await wait_seconds(lamps.delay + 0.05)
	assert_true(lamps.is_flickering())
	assert_lt(lamp.light_energy, energy, "dimmed")
	await wait_seconds(1.0)
	assert_false(lamps.is_flickering())
	assert_eq(lamp.light_energy, energy, "back on")


func test_the_props_the_events_move_are_theirs() -> void:
	assert_null(_level.get_node_or_null("Props/SecondFloor/Curtain"), "curtain moved out")
	var events: Node = _level.get_node("TensionEvents")
	var wardrobe := events.get_node("Wardrobe/Wardrobe/Body") as StaticBody3D
	assert_ne(wardrobe.collision_layer & CombatLayers.WORLD, 0, "the wardrobe collides")
	for path: String in ["Curtain/Curtain/Mesh", "Wardrobe/Wardrobe/LeftHinge/Door"]:
		var mesh := events.get_node(path) as MeshInstance3D
		assert_eq(mesh.gi_mode, GeometryInstance3D.GI_MODE_DYNAMIC, path)


func _events() -> Array[TensionEvent]:
	var events: Array[TensionEvent] = []
	for node: Node in _level.get_node("TensionEvents").get_children():
		if node is TensionEvent:
			events.append(node as TensionEvent)
	return events


func _event(event_id: StringName) -> TensionEvent:
	for event: TensionEvent in _events():
		if event.event_id == event_id:
			return event
	return null


## Puts the player on the event's spot and, for a sight, a camera at their eyes
## looking at what has to be seen; waits until it fires or MAX_FRAMES pass.
func _visit(event: TensionEvent) -> void:
	var spot: Vector3 = SPOTS[event.event_id]
	_player.global_position = spot
	var sight := event.trigger as TensionSight
	if sight:
		var eye := Transform3D(Basis.IDENTITY, spot + Vector3(0, 1.6, 0))
		_eye.global_transform = eye.looking_at(sight.target.global_position)
		_eye.make_current()
	for frame in MAX_FRAMES:
		await wait_physics_frames(1)
		if event.has_fired:
			break
