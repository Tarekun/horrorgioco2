## One floor of the lift: the doors in the lift hall with their frame, the call
## button and the floor indicator, and behind the doors the car as it stands
## at this floor, with a button for each floor on its back wall.
##
## Every floor has its own car, stacked in the shaft: the lift is "at" a floor
## when that floor's doors can open, and a ride moves the rider from one car to
## the same spot in another while both doors are shut (see Lift). The stop has
## no rules of its own: Lift calls down to it and listens to its signals.
##
## The origin is the middle of the doorway, on the line between the lift hall
## and the shaft, at floor level; the hall is towards +Z and the car towards -Z.

class_name LiftStop
extends Node3D

## Emitted when the call button is pressed.
signal called(actor: Node3D)

## Emitted when a button inside the car is pressed.
signal floor_picked(floor_index: int, actor: Node3D)

## How far each door panel slides to open (metres), half the doorway.
const DOOR_TRAVEL: float = 0.5

## The inside of the car, in the stop's own space: a rider whose position is
## in it rides.
const CAR_INSIDE: AABB = AABB(Vector3(-0.95, -0.5, -1.95), Vector3(1.9, 2.9, 1.95))

## The call button's light while the lift works.
@export var lit_material: Material

## The call button's light before the power.
@export var unlit_material: Material

## Whether the doors are open, or opening.
var is_open: bool = false

var _left_closed_x: float
var _right_closed_x: float

@onready var _call_button: LiftButton = %CallButton
@onready var _doors_button: LiftButton = %DoorsButton
@onready var _floor_buttons: Node3D = %FloorButtons
@onready var _left_door: Node3D = %LeftDoor
@onready var _right_door: Node3D = %RightDoor
@onready var _door_blocker: CollisionShape3D = %DoorBlocker
@onready var _indicator: Label3D = %Indicator
@onready var _call_light: MeshInstance3D = %CallLight


func _ready() -> void:
	_left_closed_x = _left_door.position.x
	_right_closed_x = _right_door.position.x
	_call_button.interacted.connect(_on_call_button_interacted)
	for button: LiftButton in get_floor_buttons():
		button.interacted.connect(_on_floor_button_interacted.bind(button.floor_index))


## The buttons inside the car.
func get_floor_buttons() -> Array[LiftButton]:
	var buttons: Array[LiftButton] = []
	for node: Node in _floor_buttons.get_children():
		var button := node as LiftButton
		if button:
			buttons.append(button)
	return buttons


## The button inside the car that goes to `floor_index`, or null.
func get_floor_button(floor_index: int) -> LiftButton:
	for button: LiftButton in get_floor_buttons():
		if button.floor_index == floor_index:
			return button
	return null


## The call button in the lift hall.
func get_call_button() -> LiftButton:
	return _call_button


## The doors, as something to press. Only an interactable while out of order.
func get_doors_button() -> LiftButton:
	return _doors_button


## Puts the stop out of order, with the doors and every button answering
## `message`, or back in service. In service the doors are no longer
## something to press and the call button is lit.
func set_out_of_order(is_out_of_order: bool, message: String) -> void:
	var answer: String = message if is_out_of_order else ""
	_call_button.answer = answer
	_doors_button.answer = answer
	for button: LiftButton in get_floor_buttons():
		button.answer = answer
	if is_out_of_order:
		_doors_button.add_to_group(Interactable.GROUP)
	else:
		_doors_button.remove_from_group(Interactable.GROUP)
	_call_light.material_override = unlit_material if is_out_of_order else lit_material


## Shows `label` on the floor indicator above the doors.
func show_floor(label: String) -> void:
	_indicator.text = label


## The text on the floor indicator.
func get_indicator_text() -> String:
	return _indicator.text


## Adds opening or closing the doors to `tween`, taking `seconds`, as the next
## step in its sequence. The doorway lets the player through only while the
## doors are fully open.
func add_doors_motion(tween: Tween, is_opening: bool, seconds: float) -> void:
	is_open = is_opening
	if is_opening:
		tween.tween_callback(_door_blocker.set_deferred.bind(&"disabled", true))
	var travel: float = DOOR_TRAVEL if is_opening else 0.0
	var left_x: float = _left_closed_x - travel
	var right_x: float = _right_closed_x + travel
	tween.tween_property(_left_door, ^"position:x", left_x, seconds)
	tween.parallel().tween_property(_right_door, ^"position:x", right_x, seconds)
	if not is_opening:
		tween.tween_callback(_door_blocker.set_deferred.bind(&"disabled", false))


## Whether `point` (global) is inside the car.
func contains(point: Vector3) -> bool:
	return CAR_INSIDE.has_point(to_local(point))


## The middle of the car, global.
func get_car_center() -> Vector3:
	return to_global(CAR_INSIDE.get_center())


func _on_call_button_interacted(actor: Node3D) -> void:
	called.emit(actor)


func _on_floor_button_interacted(actor: Node3D, floor_index: int) -> void:
	floor_picked.emit(floor_index, actor)
