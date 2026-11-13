## A standard enemy: wanders, notices the player, chases along the navmesh and
## attacks with a melee hitbox. When it goes down it must be stomped.
##
## EnemyBrain decides the state; this node carries it out. Movement follows the
## NavigationAgent3D over the level's navigation mesh. An attack winds up, opens
## the hitbox for a short window and then recovers, and its damage goes through
## the player's Hurtbox and HealthComponent. Hits stagger the enemy, which
## cancels an attack in progress.
##
## Its health and the damage of its hits come from the Scarcity resource.
##
## At zero health, or hit by a knockdown blow, the enemy falls and joins the
## downed group. After a few seconds it gets up with some health, unless the
## player stomps it first: stomp() kills it for good and it stays as a corpse.
##
## A dormant enemy stands still, blind and deaf, until a level event calls
## wake() or the player hits it; either way it wakes alerted to the player.
## A level loading a save where the event already happened wakes it unalerted,
## as placed.
##
## Its EnemyModel shows all this: it is fed the enemy's speed, and plays the
## attack, stagger, fall and get-up clips as the state changes. A downed enemy
## lies on its back; the model is turned back upright inside the lying body,
## so its own fall animation shows it going down.
##
## Enemies are persistent (see WorldState): dying records the corpse's
## position in SaveSystem.world, and loading a save lays the corpse there
## again. Living enemies record nothing, so a load brings them back where they
## were placed with full health.

class_name Enemy
extends CharacterBody3D

## Emitted when the state machine changes state.
signal state_changed(old_state: EnemyBrain.State, new_state: EnemyBrain.State)
## Emitted when a swing starts.
signal attack_started
## Emitted when the enemy falls down, from zero health or a heavy blow.
signal downed
## Emitted when a downed enemy gets back up.
signal got_up
## Emitted when the enemy dies for good (stomped).
signal died

## Group enemies join, used by soft targeting and level logic.
const ENEMY_GROUP: StringName = &"enemies"

## Group of the enemies that are down and can be stomped.
const DOWNED_GROUP: StringName = &"downed_enemies"

## Group the player joins.
const PLAYER_GROUP: StringName = &"player"

## Stable id for saves. Left empty, it is the enemy's path inside its level.
@export var enemy_id: StringName

## Starts asleep: stands still and neither sees nor hears until wake() is
## called or it is hit.
@export var is_dormant: bool = false

@export_group("Movement")
@export var wander_speed: float = 1.2
@export var chase_speed: float = 3.0
## Turn rate toward the movement direction in degrees per second.
@export var turn_speed: float = 360.0
## How far from its spawn point the enemy wanders (metres).
@export var wander_radius: float = 6.0
## How far the chased position must move before the enemy plans a new path
## (metres). Planning every frame starts the path over from the closest point
## on the navmesh each time, which holds the enemy back at a door's link.
@export var repath_distance: float = 0.5

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
## Seconds a downed enemy stays down, plus or minus the variation.
@export var downed_duration: float = 8.0
@export var downed_variation: float = 2.0
## Seconds a downed enemy takes to get up, standing still.
@export var get_up_duration: float = 1.2
## Seconds the fall animation takes.
@export var fall_duration: float = 1.2
## Fraction of its maximum health an enemy gets back up with.
@export_range(0.0, 1.0) var get_up_health_ratio: float = 0.4

@export_group("Nodes")
@export var health_component: HealthComponent
@export var hurtbox: Hurtbox
@export var attack_hitbox: Hitbox
@export var navigation_agent: NavigationAgent3D
@export var perception: EnemyPerception
## The animated body. Optional: without one the enemy still works, unseen.
@export var model: EnemyModel

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
var _getting_up_left: float = 0.0


func _ready() -> void:
	_spawn_position = global_position
	rng.randomize()
	var scarcity: Scarcity = Scarcity.current()
	health_component.max_health = scarcity.enemy_max_health
	health_component.current_health = scarcity.enemy_max_health
	add_to_group(ENEMY_GROUP)
	add_to_group(WorldState.GROUP)
	if enemy_id.is_empty():
		enemy_id = WorldState.default_id(self)
	brain.idle_duration = idle_duration
	brain.stagger_duration = stagger_duration
	brain.state_changed.connect(_on_state_changed)
	hurtbox.hit_received.connect(_on_hit_received)
	health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	if is_dormant:
		_stop()
	else:
		perception.update(delta, _get_target())
		var senses := _gather_senses()
		brain.tick(delta, senses)
		_run_state(delta)
		if _getting_up_left > 0.0:
			_getting_up_left -= delta
			_stop()
	move_and_slide()
	_update_model()


## Current state of the state machine.
func get_state() -> EnemyBrain.State:
	return brain.state


## Whether the enemy is lying down, where it can be stomped.
func is_downed() -> bool:
	return brain.is_downed()


## Whether the enemy is dead for good.
func is_dead() -> bool:
	return brain.is_dead()


## Whether the enemy is after the player: alive, on its feet and alert. The
## player can't save while any enemy is.
func is_chasing() -> bool:
	return not brain.is_dead() and not brain.is_downed() and perception.is_alert()


## Finishes a downed enemy off for good. Returns false if it isn't down.
func stomp() -> bool:
	if not brain.is_downed():
		return false
	brain.kill()
	return true


func get_persistent_id() -> StringName:
	return enemy_id


## Wakes a dormant enemy, already alerted to the player unless `is_alerted`
## is false (a loaded save wakes it as placed, like any other enemy).
func wake(is_alerted: bool = true) -> void:
	if not is_dormant:
		return
	is_dormant = false
	var player: Node3D = _get_target()
	if player and is_alerted:
		perception.alert_to(player.global_position)


## Takes back a recorded state: a dead enemy becomes a corpse where it lay.
func load_state(state: Dictionary) -> void:
	var saved_dead: Variant = state.get("is_dead")
	if not (saved_dead is bool and saved_dead):
		return
	global_position = WorldState.decode_vector(state.get("position"), global_position)
	rotation = WorldState.decode_vector(state.get("rotation"), rotation)
	brain.kill()
	_keep_model_upright()
	if model:
		model.finish_action(&"fall")


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
		EnemyBrain.State.IDLE, EnemyBrain.State.STAGGER:
			_stop()
		EnemyBrain.State.DOWNED, EnemyBrain.State.DEAD:
			_stop()
		EnemyBrain.State.WANDER:
			_move_along_path(wander_speed, delta)
		EnemyBrain.State.CHASE:
			_chase(perception.last_known_position)
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


## Heads for `point`, keeping the current path while it ends near enough.
func _chase(point: Vector3) -> void:
	var target_moved: float = navigation_agent.target_position.distance_to(point)
	if navigation_agent.is_navigation_finished() or target_moved > repath_distance:
		navigation_agent.target_position = point


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
	attack_hitbox.damage = Scarcity.current().roll_enemy_damage(rng)
	if model:
		model.play_action(&"attack", attack_windup + attack_active + attack_recovery)
	attack_started.emit()


func _end_attack() -> void:
	if is_attacking:
		is_attacking = false
		attack_hitbox.deactivate()
		_cooldown_left = attack_cooldown


func _on_state_changed(old_state: EnemyBrain.State, new_state: EnemyBrain.State) -> void:
	if old_state == EnemyBrain.State.ATTACK:
		_end_attack()
	if old_state == EnemyBrain.State.DOWNED and new_state != EnemyBrain.State.DEAD:
		_get_up()
	match new_state:
		EnemyBrain.State.ATTACK:
			_start_attack()
		EnemyBrain.State.STAGGER:
			if model:
				model.play_action(&"stagger", stagger_duration)
		EnemyBrain.State.DOWNED:
			_fall()
		EnemyBrain.State.DEAD:
			_become_corpse()
		EnemyBrain.State.WANDER:
			navigation_agent.target_position = pick_wander_point()
			_has_wander_point = true
		_:
			_has_wander_point = false
	state_changed.emit(old_state, new_state)


func _on_hit_received(hit: HitData, damage_dealt: float) -> void:
	if damage_dealt <= 0.0 or health_component.is_dead or brain.is_dead():
		return
	wake()
	if hit.attacker:
		perception.alert_to(hit.attacker.global_position)
	if hit.causes_knockdown:
		knock_down()
	elif hit.causes_stagger:
		brain.stagger()


## Falls as if hit by a knockdown blow, with the usual downed duration
## roll. Melee knockdown hits and the shotgun's pellet count both route
## through here.
func knock_down() -> void:
	if health_component.is_dead or brain.is_dead():
		return
	wake()
	brain.knock_down(_roll_downed_duration())


func _on_died() -> void:
	brain.knock_down(_roll_downed_duration())


func _roll_downed_duration() -> float:
	return maxf(downed_duration + rng.randf_range(-downed_variation, downed_variation), 0.1)


func _fall() -> void:
	add_to_group(DOWNED_GROUP)
	# On its back, the way the fall animation lands.
	rotation_degrees.x = 90.0
	_keep_model_upright()
	if model:
		model.play_action(&"fall", fall_duration)
	downed.emit()


func _get_up() -> void:
	remove_from_group(DOWNED_GROUP)
	rotation_degrees.x = 0.0
	_keep_model_upright()
	_getting_up_left = get_up_duration
	if model:
		model.play_action(&"get_up", get_up_duration)
	if health_component.is_dead:
		health_component.revive(health_component.max_health * get_up_health_ratio)
	got_up.emit()


## Feeds the model the speed the enemy moves at.
func _update_model() -> void:
	if model:
		model.set_speed(Vector2(velocity.x, velocity.z).length())


## Turns the model back against the body's tilt, so its animations play
## standing on the floor whether the body is up or lying down.
func _keep_model_upright() -> void:
	if model:
		model.rotation.x = -rotation.x


func _become_corpse() -> void:
	perception.lose_track()
	remove_from_group(DOWNED_GROUP)
	remove_from_group(ENEMY_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)
	var corpse: Dictionary = {
		"is_dead": true,
		"position": WorldState.encode_vector(global_position),
		"rotation": WorldState.encode_vector(rotation),
	}
	SaveSystem.world.record(enemy_id, corpse)
	died.emit()
