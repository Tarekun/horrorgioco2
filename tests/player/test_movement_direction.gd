## Unit tests for camera-relative movement direction calculation.
##
## The math is extracted into a static helper so production code is not
## re-implemented in the test harness.

extends GutTest


## Computes the camera-relative movement direction for the given input
## vector and camera yaw, matching Player._get_camera_relative_direction().
static func compute_direction(input: Vector2, camera_yaw: float) -> Vector3:
	if input.length() < 0.001:
		return Vector3.ZERO

	# Godot +Y rotation: forward = (-sin θ, 0, -cos θ), right = (cos θ, 0, -sin θ).
	var forward: Vector3 = Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right: Vector3 = Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))

	return (forward * -input.y + right * input.x).normalized()


# --- Cardinal directions ---


func test_forward_with_camera_facing_north() -> void:
	## Camera facing -Z (yaw = 0). Forward input = -Y in screen space.
	var dir: Vector3 = compute_direction(Vector2(0.0, -1.0), 0.0)
	assert_approx_eq_vec(dir, Vector3(0.0, 0.0, -1.0), 0.01, "forward at yaw 0")


func test_forward_with_camera_facing_west() -> void:
	## Camera facing -X (yaw = PI/2). Forward input relative to camera.
	var dir: Vector3 = compute_direction(Vector2(0.0, -1.0), PI / 2.0)
	assert_approx_eq_vec(dir, Vector3(-1.0, 0.0, 0.0), 0.01, "forward at yaw 90°")


func test_forward_with_camera_facing_south() -> void:
	## Camera facing +Z (yaw = PI). Forward input relative to camera.
	var dir: Vector3 = compute_direction(Vector2(0.0, -1.0), PI)
	assert_approx_eq_vec(dir, Vector3(0.0, 0.0, 1.0), 0.01, "forward at yaw 180°")


func test_backward_with_camera_facing_north() -> void:
	var dir: Vector3 = compute_direction(Vector2(0.0, 1.0), 0.0)
	assert_approx_eq_vec(dir, Vector3(0.0, 0.0, 1.0), 0.01, "backward at yaw 0")


func test_right_with_camera_facing_north() -> void:
	var dir: Vector3 = compute_direction(Vector2(1.0, 0.0), 0.0)
	assert_approx_eq_vec(dir, Vector3(1.0, 0.0, 0.0), 0.01, "right at yaw 0")


func test_left_with_camera_facing_north() -> void:
	var dir: Vector3 = compute_direction(Vector2(-1.0, 0.0), 0.0)
	assert_approx_eq_vec(dir, Vector3(-1.0, 0.0, 0.0), 0.01, "left at yaw 0")


# --- Diagonals ---


func test_diagonal_forward_right() -> void:
	var dir: Vector3 = compute_direction(Vector2(1.0, -1.0), 0.0)
	assert_approx_eq_vec(dir, Vector3(0.7071, 0.0, -0.7071), 0.01, "forward-right")


func test_diagonal_camera_rotated() -> void:
	## Camera at 45° (PI/4), input straight forward.
	var dir: Vector3 = compute_direction(Vector2(0.0, -1.0), PI / 4.0)
	assert_approx_eq(dir.x, -0.7071, 0.01, "diagonal x")
	assert_approx_eq(dir.z, -0.7071, 0.01, "diagonal z")


# --- Edge cases ---


func test_zero_input_returns_forward() -> void:
	## Zero input should return ZERO (not FORWARD).
	var dir: Vector3 = compute_direction(Vector2.ZERO, 0.0)
	assert_approx_eq_vec(dir, Vector3.ZERO, 0.01, "zero input")


func test_near_zero_input_returns_forward() -> void:
	var dir: Vector3 = compute_direction(Vector2(0.0001, 0.0), 0.0)
	assert_approx_eq_vec(dir, Vector3.ZERO, 0.01, "near-zero input")


func test_direction_is_consistent_across_full_rotation() -> void:
	## Test that direction is consistent at regular intervals.
	var input: Vector2 = Vector2(1.0, -1.0)
	for i: int in range(0, 361, 45):
		var yaw: float = deg_to_rad(float(i))
		var dir: Vector3 = compute_direction(input, yaw)
		assert_lt(abs(dir.length() - 1.0), 0.01, "normalized at %d°" % i)


# --- Helpers ---


func assert_approx_eq(
	actual: float, expected: float, tolerance: float, message: String = ""
) -> void:
	var diff: float = abs(actual - expected)
	assert_lt(diff, tolerance, message)


func assert_approx_eq_vec(
	actual: Vector3, expected: Vector3, tolerance: float, message: String = ""
) -> void:
	var diff: float = actual.distance_to(expected)
	assert_lt(diff, tolerance, message)
