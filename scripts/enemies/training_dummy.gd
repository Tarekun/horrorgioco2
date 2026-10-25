## Minimal placeholder enemy for combat testing: it can be hit, staggered and
## killed, and it can hit back. Real enemy AI is a separate epic.
##
## Hits stagger it (cancelling an attack in progress). Call attack() to open
## its hitbox for a short window.

class_name TrainingDummy
extends CharacterBody3D

## Emitted when a hit interrupts the dummy.
signal staggered
## Emitted when the dummy dies.
signal died

## Seconds a hit keeps the dummy staggered.
@export var stagger_duration: float = 0.5

## Seconds the attack hitbox stays active.
@export var attack_duration: float = 0.3

@export var health_component: HealthComponent
@export var hurtbox: Hurtbox
@export var attack_hitbox: Hitbox

var is_staggered: bool = false

## How many times the dummy has been staggered.
var stagger_count: int = 0
var is_attacking: bool = false

var _stagger_left: float = 0.0
var _attack_left: float = 0.0


func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()

	if is_attacking:
		_attack_left -= delta
		if _attack_left <= 0.0:
			_end_attack()
	if is_staggered:
		_stagger_left -= delta
		if _stagger_left <= 0.0:
			is_staggered = false


## Swings at whatever is in front of the dummy. Returns false if it can't.
func attack() -> bool:
	if health_component.is_dead or is_staggered or is_attacking:
		return false
	is_attacking = true
	_attack_left = attack_duration
	attack_hitbox.activate()
	return true


func _end_attack() -> void:
	is_attacking = false
	attack_hitbox.deactivate()


func _on_hit_received(hit: HitData, damage_dealt: float) -> void:
	if damage_dealt <= 0.0 or not hit.causes_stagger or health_component.is_dead:
		return
	if is_attacking:
		_end_attack()
	is_staggered = true
	_stagger_left = stagger_duration
	stagger_count += 1
	staggered.emit()


func _on_died() -> void:
	remove_from_group(&"enemies")
	if is_attacking:
		_end_attack()
	is_staggered = false
	hurtbox.set_deferred(&"monitorable", false)
	rotation_degrees.x = -90.0
	died.emit()
