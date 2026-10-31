## A metal roller shutter across a corridor (the hotel's is `shutter_staff`,
## in the basement). Down, its collider blocks the corridor for the player,
## enemies and sight. It has no controls of its own: something calls raise(),
## such as its ShutterButton once the power is back.
##
## Raising it is loud: it makes a noise event of `noise_radius` metres at the
## shutter as it starts, then the curtain rolls up into its box over
## `raise_time` seconds. Once it is up the collider is off and the navigation
## link through it is on, so the player and enemies can pass. It never comes
## down again.
##
## Shutters are persistent (see WorldState): raising one records it as up, and
## loading a save that has it up puts it straight up, with no sound and no
## noise. Like doors, enemies path through it only by its navigation link: the
## level's navmesh is baked with the shutter down (see tools/bake_navmesh.gd).

class_name RollerShutter
extends Node3D

## Emitted when the shutter starts going up: `is_loaded` is false when it was
## raised live with raise(), true when a loaded save put it up.
signal raised(is_loaded: bool)
## Emitted when the shutter is all the way up and the corridor is open.
signal opened

## Stable id for saves. Left empty, it is the shutter's path inside its level.
@export var shutter_id: StringName

## Seconds the curtain takes to roll up.
@export var raise_time: float = 3.0

## How far (metres) the noise of raising it carries (slice.md: 12 m, working
## value).
@export var noise_radius: float = 12.0

## Height of the curtain when it is down, from the floor to the box.
@export var curtain_height: float = 2.56

## What is left of the curtain's height, as a fraction, once rolled up: its
## bottom bar, under the box.
@export_range(0.01, 1.0) var rolled_fraction: float = 0.05

## The slats that roll up (child).
@export var curtain: Node3D

## Blocks the corridor while the shutter is down (child).
@export var collision_shape: CollisionShape3D

## Lets enemies path through the shutter once it is up (child).
@export var navigation_link: NavigationLink3D

## Played as it rolls up. Optional.
@export var raise_sound: AudioStreamPlayer3D

## Whether the shutter is up or going up. This is what saves keep.
var is_up: bool = false

## Whether it is all the way up, so the corridor is open.
var is_open: bool = false

var _tween: Tween


func _ready() -> void:
	add_to_group(WorldState.GROUP)
	if shutter_id.is_empty():
		shutter_id = WorldState.default_id(self)
	navigation_link.enabled = false
	collision_shape.disabled = false
	_set_openness(0.0)


## Rolls the shutter up, loudly, and records it as up. Does nothing if it is
## already up.
func raise() -> void:
	if is_up:
		return
	is_up = true
	SaveSystem.world.record(shutter_id, {"is_up": true})
	raised.emit(false)
	if raise_sound:
		raise_sound.play()
	NoiseEvent.emit_noise(get_tree(), global_position, noise_radius)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_openness, 0.0, 1.0, raise_time)
	_tween.tween_callback(_open_way)


func get_persistent_id() -> StringName:
	return shutter_id


## Takes back a recorded state: puts the shutter straight up if the save had
## it up.
func load_state(state: Dictionary) -> void:
	var saved: Variant = state.get("is_up")
	if not (saved is bool and saved) or is_up:
		return
	is_up = true
	raised.emit(true)
	_set_openness(1.0)
	_open_way()


## How far the curtain has rolled up, from 0 (down) to 1 (up): its bottom edge
## rises while the curtain squeezes into the box.
func _set_openness(openness: float) -> void:
	if curtain == null:
		return
	var height: float = lerpf(1.0, rolled_fraction, openness)
	curtain.position.y = curtain_height * (1.0 - height)
	curtain.scale.y = height


func _open_way() -> void:
	is_open = true
	collision_shape.disabled = true
	navigation_link.enabled = true
	opened.emit()
