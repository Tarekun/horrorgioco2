## Base for scene-level combat tests: a floor, the real player scene with its
## combat nodes, and a training dummy 1.2 m in front (towards -Z). Presses are
## sent through the combat node's methods so frames are exact.

class_name CombatSceneTest
extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/enemies/training_dummy.tscn")
const DT: float = 1.0 / 60.0

var _player: Player
var _combat: PlayerCombat
var _stamina: StaminaComponent
var _dummy: TrainingDummy


func before_each() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_child_autofree(floor_body)

	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_combat = _player.get_node("PlayerCombat") as PlayerCombat
	_stamina = _player.stamina_component
	_dummy = _spawn_dummy(Vector3(0.0, 0.0, -1.2))
	await _physics_frames(2)


func after_each() -> void:
	Input.action_release(&"attack")
	Input.action_release(&"dodge")
	Input.action_release(&"move_forward")
	Input.action_release(&"move_back")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _spawn_dummy(position: Vector3) -> TrainingDummy:
	var dummy := DUMMY_SCENE.instantiate() as TrainingDummy
	dummy.position = position
	add_child_autofree(dummy)
	return dummy


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _seconds(seconds: float) -> void:
	await _physics_frames(int(ceil(seconds / DT)))


## A quick tap, which swings once released. Waits a frame so the animation
## tree has switched state.
func _tap() -> void:
	_combat.attack_pressed()
	await _physics_frames(2)
	_combat.attack_released()
	await _physics_frames(1)
