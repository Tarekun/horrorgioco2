## The builders' rubble chute from room 15 (1F) down to the skip in the GF
## building site (docs/design/slice.md, "The chute"). It sits at the chute's
## top, where the player uses it with *"Slide down."*
##
## Sliding plays a short sequence: the screen goes dark with the noise of the
## slide, the player is put next to the skip on GF, and the screen comes back.
## The game is paused meanwhile, as the menus do, so every player input is
## locked until the end. It's one way only: from GF the chute's mouth answers
## that it can't be climbed. It stays usable, so sliding again is allowed.
##
## The chute's look comes from the hotel's props (tools/dress_hotel.gd); this
## scene only adds the interactions, the landing spot and the sequence. Until
## in-engine cutscenes (#95) exist, the sequence is the fade and the noise.

class_name RubbleChute
extends Interactable

## Emitted when the slide starts, with the player sliding.
signal slide_started(player: Player)
## Emitted when the slide is over and the player has control again.
signal landed(player: Player)

const PROMPT: String = "Slide down."
## What the chute's mouth on GF answers.
const NO_WAY_BACK_MESSAGE: String = "No way back up that."

## Seconds the screen takes to go dark.
@export var fade_out_time: float = 0.5

## Seconds the screen stays dark, with the noise of the slide.
@export var dark_time: float = 1.6

## Seconds the screen takes to come back.
@export var fade_in_time: float = 0.8

## The chute's mouth over the skip on GF, which can't be climbed (child).
@export var mouth: Examinable

## Where the player lands, and the way they face (child).
@export var landing: Node3D

## Covers the screen during the slide (child).
@export var screen_fade: ScreenFade

## Plays the noise of the slide (child).
@export var slide_noise: AudioStreamPlayer

## True from the start of a slide until the player has control again.
var is_sliding: bool = false

var _has_paused: bool = false


func _ready() -> void:
	super._ready()
	prompt = PROMPT
	mouth.lines = PackedStringArray([NO_WAY_BACK_MESSAGE])
	# It plays through the pause the slide puts the game in.
	slide_noise.process_mode = Node.PROCESS_MODE_ALWAYS


## Slides the player who uses it down to GF.
func interact(actor: Node3D) -> String:
	interacted.emit(actor)
	var player := actor as Player
	if player:
		slide(player)
	return ""


## Plays the slide and puts `player` at the landing spot on GF. Await it to wait
## for the player to have control again. Does nothing during another slide.
func slide(player: Player) -> void:
	if is_sliding:
		return
	is_sliding = true
	if not get_tree().paused:
		_has_paused = true
		get_tree().paused = true
	slide_noise.play()
	slide_started.emit(player)
	await screen_fade.fade_out(fade_out_time)
	player.place_at(landing)
	if dark_time > 0.0:
		await get_tree().create_timer(dark_time, true).timeout
	await screen_fade.fade_in(fade_in_time)
	if _has_paused:
		_has_paused = false
		get_tree().paused = false
	is_sliding = false
	landed.emit(player)
