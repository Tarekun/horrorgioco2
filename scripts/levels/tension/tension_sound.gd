## A tension action that plays a sound where it stands: a phone ringing behind a
## door, footsteps crossing the floor above.
##
## The sound is only heard. It never goes through NoiseEvent, so no enemy reacts
## to it.

class_name TensionSound
extends TensionAction

## What to play. A looping stream plays until `duration` runs out or stop().
@export var stream: AudioStream

## The bus: SFX for things happening, Ambience for a lasting background.
@export var bus: StringName = AudioBuses.SFX

@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0

## Distance (metres) at which the sound starts to fade.
@export var unit_size: float = 3.0

## Distance (metres) beyond which it is silent; 0 is no limit.
@export var max_distance: float = 0.0

## Seconds it plays before stopping; 0 plays a one-shot to its end and a loop
## until stop().
@export var duration: float = 0.0

## How far it moves while it plays (over `duration`, or the stream's length):
## footsteps walking across a room.
@export var travel: Vector3 = Vector3.ZERO

var _player: AudioStreamPlayer3D
var _motion: Tween


func _ready() -> void:
	_player = AudioStreamPlayer3D.new()
	_player.name = "Player"
	_player.stream = stream
	_player.bus = bus
	_player.volume_db = volume_db
	_player.pitch_scale = pitch_scale
	_player.unit_size = unit_size
	_player.max_distance = max_distance
	add_child(_player)


## Whether the sound is playing.
func is_playing() -> bool:
	return _player.playing


## The node that plays it.
func get_player() -> AudioStreamPlayer3D:
	return _player


func _start() -> void:
	_player.position = Vector3.ZERO
	_player.play()
	var seconds: float = duration
	if seconds <= 0.0 and stream:
		seconds = stream.get_length() / maxf(pitch_scale, 0.01)
	if travel == Vector3.ZERO and duration <= 0.0:
		return
	_motion = create_tween()
	if travel != Vector3.ZERO and seconds > 0.0:
		_motion.tween_property(_player, ^"position", travel, seconds)
	else:
		_motion.tween_interval(seconds)
	if duration > 0.0:
		_motion.tween_callback(_end)


func _end() -> void:
	if _motion:
		_motion.kill()
		_motion = null
	_player.stop()
