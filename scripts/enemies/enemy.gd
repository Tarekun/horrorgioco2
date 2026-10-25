## A standard enemy: wanders, notices the player, chases along the navmesh and
## attacks with a melee hitbox.
##
## EnemyBrain decides the state; this node carries it out. Movement follows the
## NavigationAgent3D over the level's navigation mesh. An attack winds up, opens
## the hitbox for a short window and then recovers, and its damage goes through
## the player's Hurtbox and HealthComponent. Hits stagger the enemy, which
## cancels an attack in progress.

class_name Enemy
extends CharacterBody3D

## Emitted when the state machine changes state.
signal state_changed(old_state: EnemyBrain.State, new_state: EnemyBrain.State)
## Emitted when a swing starts.
signal attack_started
## Emitted when the enemy dies.
signal died

## Group enemies join, used by soft targeting and level logic.
const ENEMY_GROUP: StringName = &"enemies"

## Group the player joins.
const PLAYER_GROUP: StringName = &"player"

@export_group("Movement")
@export var wander_speed: float = 1.2
@export var chase_speed: float = 3.0
## Turn rate toward the movement direction in degrees per second.
@export var turn_speed: float = 360.0
## How far from its spawn point the enemy wanders (metres).
@export var wander_radius: float = 6.0

@export_group("Attack")
## Distance to the target (metres) from which the enemy strikes.
@export var attack_range: float = 1.6
## Seconds between the swing starting and the hitbox opening.
@export var attack_windup: float = 0.5
## Seconds the hitbox stays open.
@export var attack_active: float = 0.25
## Seconds after the swing before the enemy chases again.
@export var attack_recovery: float = 0.4
## Seconds after a swing ends before the next may begin.
@export var attack_cooldown: float = 1.0

@export_group("Timing")
@export var idle_duration: float = 3.0
@export var stagger_duration: float = 0.5

@export_group("Nodes")
@export var health_component: HealthComponent
@export var hurtbox: Hurtbox
@export var attack_hitbox: Hitbox
@export var navigation_agent: NavigationAgent3D
@export var perception: EnemyPerception

## The player being hunted. Found in the player group when not set.
var target: Node3D

var brain := EnemyBrain.new()
var is_attacking: bool = false

## Random source for wander points, replaceable for tests.
var rng := RandomNumberGenerator.new()

var _spawn_position: Vector3
var _attack_time: float = 0.0
var _cooldown_left: float = 0.0
var _has_wander_point: bool = false


func _ready() -> void:
	_spawn_position = global_position
	rng.randomize()
	add_to_group(ENEMY_GROUP)
	brain.idle_duration = idle_duration
	brain.stagger_duration = stagger_duration
	brain.state_changed.connect(_on_state_changed)
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

	perception.update(delta, _get_target())
	var senses := _gather_senses()
	brain.tick(delta, senses)
	_run_state(delta)
	move_and_slide()


## Current state of the state machine.
func get_state() -> EnemyBrain.State:
	return brain.state


## Picks a random point near the spawn that the navmesh can reach. Returns
## the spawn position itself when the navigation map is empty.
func pick_wander_point() -> Vector3:
	var offset := Vector3(
		rng.randf_range(-wander_radius, wander_radius),
		0.0,
		rng.randf_range(-wander_radius, wander_radius)
	)
	var point: Vector3 = _spawn_position + offset
	var map: RID = navigation_agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return _spawn_position
	return NavigationServer3D.map_get_closest_point(map, point)


func _gather_senses() -> EnemySenses:
	var senses := EnemySenses.new()
	var player: Node3D = _get_target()
	senses.has_target = perception.is_alert()
	senses.can_attack = (
		senses.has_target
		and perception.is_target_visible
		and not is_attacking
		and _cooldown_left <= 0.0
		and _distance_to(player) <= attack_range
	)
	senses.has_arrived = _has_wander_point and navigation_agent.is_navigation_finished()
	senses.is_attack_finished = (
		is_attacking and _attack_time >= attack_windup + attack_active + attack_recovery
	)
	return senses


func _get_target() -> Node3D:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	return target


func _distance_to(node: Node3D) -> float:
	var offset: Vector3 = node.global_position - global_position
	offset.y = 0.0
	return offset.length()


func _run_state(delta: float) -> void:
	match brain.state:
		EnemyBrain.State.IDLE, EnemyBrain.State.STAGGER, EnemyBrain.State.DEAD:
			_stop()
		EnemyBrain.State.WANDER:
			_move_along_path(wander_speed, delta)
		EnemyBrain.State.CHASE:
			navigation_agent.target_position = perception.last_known_position
			_move_along_path(chase_speed, delta)
		EnemyBrain.State.ATTACK:
			_stop()
			_run_attack(delta)


func _run_attack(delta: float) -> void:
	var player: Node3D = _get_target()
	if player and _attack_time < attack_windup:
		_face(player.global_position - global_position, delta)
	var previous: float = _attack_time
	_attack_time += delta
	if previous < attack_windup and _attack_time >= attack_windup:
		attack_hitbox.activate()
	if previous < attack_windup + attack_active and _attack_time >= attack_windup + attack_active:
		attack_hitbox.deactivate()


func _move_along_path(speed: float, delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		_stop()
		return
	var next: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next - global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		_stop()
		return
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face(direction, delta)


func _stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _face(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	var target_angle: float = atan2(-direction.x, -direction.z)
	var max_turn: float = deg_to_rad(turn_speed) * delta
	rotation.y += clampf(angle_difference(rotation.y, target_angle), -max_turn, max_turn)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * delta
	else:
		velocity.y = 0.0


func _start_attack() -> void:
	is_attacking = true
	_attack_time = 0.0
	attack_started.emit()


func _end_attack() -> void:
	if is_attacking:
		is_attacking = false
		attack_hitbox.deactivate()
		_cooldown_left = attack_cooldown


func _on_state_changed(old_state: EnemyBrain.State, new_state: EnemyBrain.State) -> void:
	if old_state == EnemyBrain.State.ATTACK:
		_end_attack()
	match new_state:
		EnemyBrain.State.ATTACK:
			_start_attack()
		EnemyBrain.State.WANDER:
			navigation_agent.target_position = pick_wander_point()
			_has_wander_point = true
		_:
			_has_wander_point = false
	state_changed.emit(old_state, new_state)


func _on_hit_received(hit: HitData, damage_dealt: float) -> void:
	if damage_dealt <= 0.0 or not hit.causes_stagger or health_component.is_dead:
		return
	if hit.attacker:
		perception.alert_to(hit.attacker.global_position)
	brain.stagger()


func _on_died() -> void:
	brain.kill()
	perception.lose_track()
	remove_from_group(ENEMY_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	rotation_degrees.x = -90.0
	died.emit()
