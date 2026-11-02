## Fades the whole screen to black and back, for short sequences such as the
## slide down the rubble chute. It keeps running while the game is paused, so a
## sequence can pause the game and still fade.

class_name ScreenFade
extends CanvasLayer

## The black rect that covers the screen (child).
@export var rect: ColorRect

var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_alpha(0.0)


## Fades to black over `duration` seconds. Await it to wait for the end.
func fade_out(duration: float) -> void:
	await _fade_to(1.0, duration)


## Fades back from black over `duration` seconds. Await it to wait for the end.
func fade_in(duration: float) -> void:
	await _fade_to(0.0, duration)


## Whether the screen is fully black.
func is_dark() -> bool:
	return rect.visible and is_equal_approx(rect.color.a, 1.0)


func _fade_to(alpha: float, duration: float) -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if duration <= 0.0:
		_set_alpha(alpha)
		return
	rect.visible = true
	_tween = create_tween()
	_tween.tween_method(_set_alpha, rect.color.a, alpha, duration)
	await _tween.finished


func _set_alpha(alpha: float) -> void:
	rect.color.a = alpha
	rect.visible = alpha > 0.0
