## Plays a footstep sound each time the character's foot lands.
##
## Listens to the model's footstep_taken signal, which the walk and run
## animations raise at foot contact, so the sound is locked to the animation.
## Walking is quieter than running and sprinting, and the variant and pitch
## change a little each step.

class_name Footsteps
extends AudioStreamPlayer3D

## Footstep sounds to choose between.
@export var variants: Array[AudioStream] = []

## Random pitch variation, as a fraction either way.
@export_range(0.0, 0.5) var pitch_variation: float = 0.08

## Volume in dB at walk speed and at sprint speed.
@export var walk_volume_db: float = -9.0
@export var sprint_volume_db: float = 0.0

## Speeds (m/s) that map to the walk and sprint volumes.
@export var walk_speed: float = 1.5
@export var sprint_speed: float = 5.5

## The character whose footsteps are played.
@export var model: PlayerModel

var _last_variant: int = -1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	bus = AudioBuses.SFX
	_rng.randomize()
	if model:
		model.footstep_taken.connect(_on_footstep_taken)


## Volume in dB for a footstep at `speed`, rising from walk to sprint.
static func volume_for_speed(
	speed: float, walk: float, sprint: float, walk_db: float, sprint_db: float
) -> float:
	var weight: float = clampf(inverse_lerp(walk, sprint, speed), 0.0, 1.0)
	return lerpf(walk_db, sprint_db, weight)


## Picks a variant index in [0, count) from `roll` in [0, 1), never repeating
## `last` when there is more than one variant.
static func pick_variant(count: int, last: int, roll: float) -> int:
	if count <= 1:
		return 0
	if last < 0 or last >= count:
		return mini(int(roll * count), count - 1)
	var index: int = mini(int(roll * (count - 1)), count - 2)
	return index + 1 if index >= last else index


## Plays one footstep for a character moving at `speed`.
func play_footstep(speed: float) -> void:
	if variants.is_empty():
		return
	_last_variant = pick_variant(variants.size(), _last_variant, _rng.randf())
	stream = variants[_last_variant]
	volume_db = volume_for_speed(speed, walk_speed, sprint_speed, walk_volume_db, sprint_volume_db)
	pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	play()


func _on_footstep_taken(speed: float) -> void:
	play_footstep(speed)
