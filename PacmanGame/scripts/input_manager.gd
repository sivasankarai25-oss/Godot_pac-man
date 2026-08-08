extends Node
## NOT an autoload by name collision reasons -- but referenced globally via
## "InputManager" node name lookup pattern is avoided; instead this script
## is meant to be autoloaded too. Add to project.godot autoloads as
## "InputManager"="*res://scripts/input_manager.gd" (already wired below by
## Pacman._read_input_direction via `InputManager.has_pending_swipe()`).
## Handles swipe-to-move touch controls (section 6 of the spec) without
## interfering with keyboard play.

const SWIPE_MIN_DISTANCE: float = 30.0 # pixels, filters out taps/jitter

var _touch_start: Vector2 = Vector2.ZERO
var _touch_active: bool = false
var _pending_direction: Vector2i = Vector2i.ZERO
var _has_pending: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		else:
			if _touch_active:
				_evaluate_swipe(event.position)
			_touch_active = false
	elif event is InputEventScreenDrag:
		if _touch_active:
			# Evaluate continuously so a fast swipe registers even if the
			# finger is lifted off-screen or the release event is missed.
			var delta: Vector2 = event.position - _touch_start
			if delta.length() >= SWIPE_MIN_DISTANCE:
				_evaluate_swipe(event.position)
				_touch_start = event.position # reset for chained swipes

func _evaluate_swipe(end_pos: Vector2) -> void:
	var delta := end_pos - _touch_start
	if delta.length() < SWIPE_MIN_DISTANCE:
		return
	if abs(delta.x) > abs(delta.y):
		_pending_direction = Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
	else:
		_pending_direction = Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)
	_has_pending = true

func has_pending_swipe() -> bool:
	return _has_pending

func consume_swipe_direction() -> Vector2i:
	# Not truly "consumed" -- kept as the active swipe direction so Pac-Man
	# keeps moving that way until the next swipe, matching how holding an
	# arrow key behaves. This mirrors classic touch-Pacman feel.
	return _pending_direction

func clear() -> void:
	_has_pending = false
	_pending_direction = Vector2i.ZERO

## Public setter used by the on-screen D-pad (touch_dpad.gd) so it doesn't
## need to reach into private fields directly.
func set_direction_from_dpad(dir: Vector2i) -> void:
	_pending_direction = dir
	_has_pending = true
