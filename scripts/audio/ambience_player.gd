## Plays a looping ambient track on the Ambience bus for as long as it is in
## the scene tree.
##
## Playback starts after a short delay, a beat after the level loads. It also
## keeps a headless one-frame run (tools/check.sh) from exiting with a sound
## still playing, which makes Godot report a leaked resource.

class_name AmbiencePlayer
extends AudioStreamPlayer

## Seconds to wait after entering the tree before the track starts.
@export var start_delay: float = 0.25


func _ready() -> void:
	bus = AudioBuses.AMBIENCE
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout
	if is_inside_tree():
		play()
