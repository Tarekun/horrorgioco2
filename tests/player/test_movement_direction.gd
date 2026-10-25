## Unit tests for the camera-relative movement direction math.
##
## Verifies that input vectors are correctly transformed into world-space
## movement directions relative to the camera's yaw angle.

extends GutTest


## Helper: compute the expected camera-relative direction for a given
## camera yaw and input vector, matching PlayerController's logic.
func _compute_direction(camera_yaw: float, input: Vector2) -> Vector3:
	if input.length() < 0.001:
		return Vector3.FORWARD

	var forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, sin(camera_yaw))
	return (forward * -input.y + right * input.x).normalized()


# --- Forward input ---


func test_forward_with_camera_facing_north() -> void:
	var camera_yaw: float = 0.0
	var input := Vector2(0, -1)
	var expected := _compute_direction(camera_yaw, input)

	## Forward input with camera at 0 should give FORWARD direction.
	assert_approx_eq(expected, Vector3.FORWARD, 0.001, "forward at 0 yaw")


func test_forward_with_camera_facing_east() -> void:
	var camera_yaw: float = PI / 2
	var input := Vector2(0, -1)
	var expected := _compute_direction(camera_yaw, input)

	## Camera facing east (+X); forward input should move along +X.
	assert_approx_eq(expected, Vector3.RIGHT, 0.001, "forward at 90 deg yaw")


func test_forward_with_camera_facing_south() -> void:
	var camera_yaw: float = PI
	var input := Vector2(0, -1)
	var expected := _compute_direction(camera_yaw, input)

	## Camera facing south (-Z); forward input should move along -Z.
	assert_approx_eq(expected, Vector3.BACK, 0.001, "forward at 180 deg yaw")


# --- Back input ---


func test_backward_with_camera_facing_north() -> void:
	var camera_yaw: float = 0.0
	var input := Vector2(0, 1)
	var expected := _compute_direction(camera_yaw, input)

	assert_approx_eq(expected, Vector3.BACK, 0.001, "backward at 0 yaw")


# --- Left / Right input ---


func test_right_with_camera_facing_north() -> void:
	var camera_yaw: float = 0.0
	var input := Vector2(1, 0)
	var expected := _compute_direction(camera_yaw, input)

	assert_approx_eq(expected, Vector3.RIGHT, 0.001, "right at 0 yaw")


func test_left_with_camera_facing_north() -> void:
	var camera_yaw: float = 0.0
	var input := Vector2(-1, 0)
	var expected := _compute_direction(camera_yaw, input)

	assert_approx_eq(expected, Vector3.LEFT, 0.001, "left at 0 yaw")


# --- Diagonal input ---


func test_diagonal_forward_right() -> void:
	var camera_yaw: float = 0.0
	var input := Vector2(1, -1)
	var expected := _compute_direction(camera_yaw, input)

	## Should be normalized and between forward and right.
	assert_approx_eq(expected, Vector3(1, 0, -1).normalized(), 0.001, "diagonal F-R")


func test_diagonal_camera_rotated() -> void:
	var camera_yaw: float = PI / 4
	var input := Vector2(1, -1)
	var expected := _compute_direction(camera_yaw, input)

	## Direction should be rotated 45 deg from the 0-yaw diagonal.
	var base := Vector3(1, 0, -1).normalized()
	var rotated := (
		Vector3(
			base.x * cos(PI / 4) - base.z * sin(PI / 4),
			0.0,
			base.x * sin(PI / 4) + base.z * cos(PI / 4)
		)
		. normalized()
	)
	assert_approx_eq(expected, rotated, 0.001, "diagonal with 45 deg rot")


# --- Zero input ---


func test_zero_input_returns_forward() -> void:
	var camera_yaw: float = PI / 3
	var input := Vector2.ZERO
	var expected := _compute_direction(camera_yaw, input)

	assert_approx_eq(expected, Vector3.FORWARD, 0.001, "zero input returns F")


# --- Near-zero input ---


func test_near_zero_input_returns_forward() -> void:
	var camera_yaw: float = PI / 3
	var input := Vector2(0.0001, -0.0001)
	var expected := _compute_direction(camera_yaw, input)

	assert_approx_eq(expected, Vector3.FORWARD, 0.001, "near-zero returns F")


# --- Full rotation coverage ---


func test_direction_is_consistent_across_full_rotation() -> void:
	## For any camera angle, forward input should produce a direction
	## that is exactly the camera's forward direction.
	for angle_deg in range(0, 360, 15):
		var camera_yaw: float = deg_to_rad(angle_deg)
		var input := Vector2(0, -1)
		var expected := _compute_direction(camera_yaw, input)

		var forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw))
		assert_approx_eq(expected, forward, 0.001, "forward at %d deg" % angle_deg)


# --- Helper: approximate equality for Vector3 ---


func assert_approx_eq(
	actual: Vector3, expected: Vector3, tolerance: float, message: String = ""
) -> void:
	var diff := actual - expected
	assert_lt(diff.length(), tolerance, message)
