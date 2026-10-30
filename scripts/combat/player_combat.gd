## The player's melee attacks: a light combo and a charged heavy attack.
##
## Tap `attack` for a light swing (decided on release, so a tap can be told from
## a hold). Press again during the last part of a swing to queue the next hit of
## the combo. Hold `attack` past the charge start time to charge a heavy attack
## and release to swing it. Each swing opens the hitbox for a window and hits
## every enemy at most once. Swings cost stamina, paid in full up front; a
## swing that can't be afforded doesn't start. The player stands still while
## attacking and turns toward the nearest enemy when a swing starts.
##
## Pressing `attack` near a downed enemy stomps it instead of swinging: the
## stomp costs no stamina, takes a while and kills the enemy for good partway
## through, leaving the player exposed (a hit interrupts it).
##
## The state machine is driven by tick(), so tests can step it without input.

class_name PlayerCombat
extends Node

## Emitted when a swing starts; `kind` is &"light" or &"heavy".
signal swing_started(kind: StringName, combo_index: int)
## Emitted when the swing ends (finished or interrupted).
signal swing_finished
## Emitted when a swing damaged a hurtbox.
signal hit_landed(hurtbox: Hurtbox, damage_dealt: float)
## Emitted when a stomp starts on a downed enemy.
signal stomp_started(enemy: Enemy)
## Emitted when a stomp lands and kills the enemy.
signal stomp_landed(enemy: Enemy)
## Emitted when the attacker freezes on contact.
signal hitstop_started(duration: float)
## Emitted when another weapon is equipped.
signal weapon_changed(new_weapon: MeleeWeapon)

enum State { IDLE, PENDING, CHARGING, SWING_LIGHT, SWING_HEAVY, STOMP }

## Group the soft-targeting looks for enemies in.
const ENEMY_GROUP: StringName = &"enemies"

## Soft-targeting range (metres) and half-angle (degrees).
@export var soft_target_distance: float = 2.5
@export var soft_target_angle: float = 60.0

## How close (metres) a downed enemy must be to be stomped.
@export var stomp_range: float = 1.2

## Seconds a stomp takes, and the fraction of it after which the enemy dies.
@export var stomp_duration: float = 0.8
@export_range(0.0, 1.0) var stomp_hit_time: float = 0.5

## The equipped weapon.
@export var weapon: MeleeWeapon

@export var player: Player
@export var stamina_component: StaminaComponent
@export var model: PlayerModel

## The hitbox swung in front of the player.
@export var hitbox: Hitbox

## While false, new attacks don't start (set by the dodge).
var is_enabled: bool = true

var state: State = State.IDLE

var _held: float = 0.0
var _swing_time: float = 0.0
var _swing_duration: float = 0.0
var _combo_index: int = 0
var _is_next_hit_queued: bool = false
var _is_window_open: bool = false
var _hitstop_left: float = 0.0
var _stomp_target: Enemy
var _is_stomp_landed: bool = false


func _ready() -> void:
	hitbox.hit_landed.connect(_on_hit_landed)
	_apply_weapon_reach()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"attack"):
		attack_pressed()
	if Input.is_action_just_released(&"attack"):
		attack_released()
	tick(delta)


## Handles the attack button going down.
func attack_pressed() -> void:
	match state:
		State.IDLE:
			if not is_enabled:
				return
			var downed: Enemy = find_stompable_enemy()
			if downed:
				_start_stomp(downed)
			elif stamina_component.can_afford(weapon.light_stamina):
				_held = 0.0
				_set_state(State.PENDING)
		State.SWING_LIGHT:
			var queue_from: float = _swing_duration * (1.0 - weapon.queue_window)
			if _swing_time >= queue_from and _combo_index + 1 < weapon.combo_length():
				_is_next_hit_queued = true


## Handles the attack button coming up.
func attack_released() -> void:
	match state:
		State.PENDING:
			_start_light(0)
		State.CHARGING:
			_start_heavy()


## Advances the swing timers and the hold timer by `delta` seconds.
func tick(delta: float) -> void:
	if _hitstop_left > 0.0:
		_hitstop_left -= delta
		if _hitstop_left <= 0.0:
			model.set_frozen(false)
		return

	match state:
		State.PENDING:
			_held += delta
			if _held >= weapon.charge_start_time:
				_begin_charge()
		State.CHARGING:
			_held += delta
		State.SWING_LIGHT, State.SWING_HEAVY:
			_advance_swing(delta)
		State.STOMP:
			_advance_stomp(delta)


## The nearest downed enemy within stomp range, or null.
func find_stompable_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_distance: float = stomp_range
	for node: Node in get_tree().get_nodes_in_group(Enemy.DOWNED_GROUP):
		var enemy := node as Enemy
		if enemy == null:
			continue
		var offset: Vector3 = enemy.global_position - player.global_position
		offset.y = 0.0
		if offset.length() <= nearest_distance:
			nearest = enemy
			nearest_distance = offset.length()
	return nearest


## True while the player is attacking and can't move.
func is_acting() -> bool:
	return state != State.IDLE


## How far through the current swing we are (0 to 1); 0 when not swinging.
func get_swing_progress() -> float:
	if state != State.SWING_LIGHT and state != State.SWING_HEAVY:
		return 0.0
	return clampf(_swing_time / _swing_duration, 0.0, 1.0)


## True while in a swing's recovery: after the hitbox window, before it ends.
## A dodge may cancel the swing then.
func is_in_recovery() -> bool:
	var is_swinging: bool = state == State.SWING_LIGHT or state == State.SWING_HEAVY
	return is_swinging and _swing_time >= _swing_duration * weapon.active_end


## Holds `new_weapon` from now on, ending any attack in progress.
func equip(new_weapon: MeleeWeapon) -> void:
	if new_weapon == null or new_weapon == weapon:
		return
	interrupt()
	weapon = new_weapon
	_apply_weapon_reach()
	weapon_changed.emit(weapon)


## Stops whatever is in progress: no more hits, the player is free to move.
func interrupt() -> void:
	if state == State.IDLE:
		return
	var was_swinging: bool = state == State.SWING_LIGHT or state == State.SWING_HEAVY
	_close_window()
	_is_next_hit_queued = false
	_hitstop_left = 0.0
	_stomp_target = null
	model.set_frozen(false)
	_set_state(State.IDLE)
	model.return_to_locomotion()
	if was_swinging:
		swing_finished.emit()


func _begin_charge() -> void:
	if stamina_component.try_spend(weapon.heavy_stamina):
		_set_state(State.CHARGING)
		model.play_action(&"attack_heavy_charge")
	else:
		# Not enough for a heavy attack: nothing happens, the press is spent.
		_set_state(State.IDLE)


func _start_light(index: int) -> void:
	if not stamina_component.try_spend(weapon.light_stamina):
		_end_swing()
		return
	_combo_index = index
	_is_next_hit_queued = false
	hitbox.damage = weapon.light_damage[index]
	hitbox.damage_multiplier = 1.0
	hitbox.causes_knockdown = false
	_begin_swing(State.SWING_LIGHT, weapon.light_duration(index))
	model.play_action(StringName("attack_light_%d" % (index + 1)), weapon.light_duration(index))
	swing_started.emit(&"light", index)


func _start_heavy() -> void:
	hitbox.damage = weapon.heavy_damage
	hitbox.damage_multiplier = weapon.heavy_scale(_held)
	hitbox.causes_knockdown = weapon.is_fully_charged(_held)
	_combo_index = 0
	_begin_swing(State.SWING_HEAVY, weapon.heavy_duration)
	model.play_action(&"attack_heavy_swing", weapon.heavy_duration)
	swing_started.emit(&"heavy", 0)


func _begin_swing(swing_state: State, duration: float) -> void:
	_face_nearest_enemy()
	_swing_time = 0.0
	_swing_duration = duration
	_set_state(swing_state)


func _advance_swing(delta: float) -> void:
	_swing_time += delta
	var open_at: float = _swing_duration * weapon.active_start
	var close_at: float = _swing_duration * weapon.active_end
	if not _is_window_open and _swing_time >= open_at and _swing_time < close_at:
		_is_window_open = true
		hitbox.activate()
	elif _is_window_open and _swing_time >= close_at:
		_close_window()

	if _swing_time >= _swing_duration:
		if _is_next_hit_queued:
			_close_window()
			_start_light(_combo_index + 1)
		else:
			_end_swing()


func _start_stomp(enemy: Enemy) -> void:
	_stomp_target = enemy
	_is_stomp_landed = false
	_swing_time = 0.0
	_swing_duration = stomp_duration
	_set_state(State.STOMP)
	var to_enemy: Vector3 = enemy.global_position - player.global_position
	to_enemy.y = 0.0
	if not to_enemy.is_zero_approx():
		player.rotation.y = atan2(-to_enemy.x, -to_enemy.z)
	# No stomp clip yet: the heavy swing's downward strike stands in for it.
	model.play_action(&"attack_heavy_swing", stomp_duration)
	stomp_started.emit(enemy)


func _advance_stomp(delta: float) -> void:
	_swing_time += delta
	if not _is_stomp_landed and _swing_time >= _swing_duration * stomp_hit_time:
		_is_stomp_landed = true
		# The enemy may have got up in the meantime.
		if is_instance_valid(_stomp_target) and _stomp_target.stomp():
			stomp_landed.emit(_stomp_target)
	if _swing_time >= _swing_duration:
		_stomp_target = null
		_set_state(State.IDLE)
		model.return_to_locomotion()


func _end_swing() -> void:
	_close_window()
	_set_state(State.IDLE)
	model.return_to_locomotion()
	swing_finished.emit()


func _close_window() -> void:
	if _is_window_open:
		_is_window_open = false
		hitbox.deactivate()


func _set_state(new_state: State) -> void:
	state = new_state
	player.is_movement_locked = new_state != State.IDLE
	player.external_velocity = Vector3.ZERO


## Turns the player toward the nearest enemy near the input (or facing)
## direction, if there is one.
func _face_nearest_enemy() -> void:
	var positions: Array[Vector3] = []
	for node: Node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := node as Node3D
		if enemy:
			positions.append(enemy.global_position)

	var reference: Vector3 = player.get_movement_direction()
	if reference.is_zero_approx():
		reference = -player.global_basis.z
	var origin: Vector3 = player.global_position
	var index: int = SoftTargeting.pick(
		origin, reference, positions, soft_target_distance, soft_target_angle
	)
	if index < 0:
		return
	var to_target: Vector3 = positions[index] - origin
	to_target.y = 0.0
	if not to_target.is_zero_approx():
		player.rotation.y = atan2(-to_target.x, -to_target.z)


func _apply_weapon_reach() -> void:
	for child: Node in hitbox.get_children():
		var shape_node := child as CollisionShape3D
		var box := shape_node.shape as BoxShape3D if shape_node else null
		if box:
			box.size.z = weapon.reach
			shape_node.position.z = -(weapon.reach / 2.0 + 0.2)


func _on_hit_landed(hurtbox: Hurtbox, damage_dealt: float) -> void:
	hit_landed.emit(hurtbox, damage_dealt)
	if damage_dealt > 0.0 and weapon.hitstop_duration > 0.0:
		_hitstop_left = weapon.hitstop_duration
		model.set_frozen(true)
		hitstop_started.emit(weapon.hitstop_duration)
