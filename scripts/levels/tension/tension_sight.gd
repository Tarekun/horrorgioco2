## A trigger that goes off when the player, standing in its area, looks at
## `target`: the target is within `max_distance` of the camera and
## `view_angle` of where it points, and no wall or closed door stands between.
## Its area is the spot to look from, such as a doorway or a landing.

class_name TensionSight
extends TensionTrigger

## The point that has to be seen.
@export var target: Node3D

## How far (metres) from the camera the target can be seen.
@export var max_distance: float = 10.0

## Half angle (degrees) around the camera's forward in which the target counts as seen.
@export_range(1.0, 90.0) var view_angle: float = 30.0

## A line of sight that hits something this close (metres) to the target still
## sees it: the target's own collider.
@export var target_radius: float = 0.4

## Layers that block the line of sight.
@export_flags_3d_physics var occlusion_mask: int = CombatLayers.WORLD


func _ready() -> void:
	super._ready()
	body_exited.connect(_on_body_exited)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera and sees(camera.global_transform):
		set_physics_process(false)
		triggered.emit()


func disarm() -> void:
	super.disarm()
	set_physics_process(false)


## Whether an eye at `eye` (looking down its -Z) sees the target.
func sees(eye: Transform3D) -> bool:
	if target == null:
		return false
	var point: Vector3 = target.global_position
	if not is_in_view(eye.origin, -eye.basis.z, point, max_distance, view_angle):
		return false
	return not _is_hidden(eye.origin, point)


## Whether `point` is within `max_distance` of `eye` and `view_angle` degrees of
## `forward`.
static func is_in_view(
	eye: Vector3, forward: Vector3, point: Vector3, max_distance: float, view_angle: float
) -> bool:
	var to_point: Vector3 = point - eye
	var distance: float = to_point.length()
	if distance > max_distance:
		return false
	if distance < 0.001:
		return true
	return rad_to_deg(forward.normalized().angle_to(to_point)) <= view_angle


func _on_player_entered(_player: Player) -> void:
	if monitoring:
		set_physics_process(true)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		set_physics_process(false)


func _is_hidden(eye: Vector3, point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(eye, point, occlusion_mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var hit_position: Vector3 = hit[&"position"]
	return hit_position.distance_to(point) > target_radius
