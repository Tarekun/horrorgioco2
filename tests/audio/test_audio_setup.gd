## Tests for the audio buses, the level ambience and the placeholder assets.

extends GutTest

const LEVEL_SCENE: PackedScene = preload("res://scenes/levels/test_level.tscn")


func test_layout_defines_the_four_buses_sending_to_master() -> void:
	var layout := load("res://default_bus_layout.tres") as AudioBusLayout
	assert_not_null(layout)
	assert_eq(
		ProjectSettings.get_setting("audio/buses/default_bus_layout"),
		"res://default_bus_layout.tres"
	)
	for bus_name: StringName in AudioBuses.ALL:
		var index: int = AudioServer.get_bus_index(bus_name)
		assert_ne(index, -1, "bus %s exists at runtime" % bus_name)
		assert_eq(
			AudioServer.get_bus_send(index), AudioBuses.MASTER, "%s sends to Master" % bus_name
		)


func test_level_ambience_loops_on_the_ambience_bus() -> void:
	var level: Node = LEVEL_SCENE.instantiate()
	add_child_autofree(level)
	var ambience := level.get_node("Ambience") as AmbiencePlayer
	assert_not_null(ambience)
	assert_eq(ambience.bus, AudioBuses.AMBIENCE)
	await wait_seconds(ambience.start_delay + 0.2)
	assert_true(ambience.playing, "starts with the level")
	var stream := ambience.stream as AudioStreamWAV
	assert_not_null(stream)
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "loops")
	assert_gt(stream.get_length(), 5.0, "long enough not to be obviously repetitive")


func test_footstep_sounds_are_short_and_do_not_loop() -> void:
	for i: int in [1, 2, 3]:
		var stream := load("res://assets/audio/footstep_%d.wav" % i) as AudioStreamWAV
		assert_not_null(stream, "footstep_%d" % i)
		assert_lt(stream.get_length(), 0.5)
		assert_ne(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
