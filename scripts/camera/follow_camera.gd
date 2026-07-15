class_name FollowCamera
extends Camera2D
## Smooth-follow camera with speed-based look-ahead.
##
## Fully decoupled: it only needs *a* Node2D target and estimates the target's
## velocity itself from position deltas — no signal from, or knowledge of, the
## player. Point it at anything (a cutscene dolly, a traffic car) and it works.
##
## Both the follow and the look-ahead use exponential damping
## (1 - exp(-k·dt)), which is frame-rate independent and can never overshoot
## or oscillate — hence no shaking by construction.

## The node to follow.
@export var target: Node2D
## Follow stiffness. Higher = snappier, lower = floatier.
@export var position_damping := 6.0
## How many seconds of current travel to look ahead of the target.
@export var look_ahead_time := 0.35
## Hard cap on the look-ahead offset, in pixels.
@export var max_look_ahead := 120.0
## How quickly the look-ahead offset eases toward its new value.
@export var look_ahead_damping := 2.5
## Side-scroller: keep the camera on a fixed horizon line.
@export var lock_vertical := true
## Vertical world position the camera stays at when locked.
@export var fixed_y := 180.0

var _look_ahead := 0.0
var _last_target_x := 0.0
var _initialized := false

func _physics_process(delta: float) -> void:
	if target == null or delta <= 0.0:
		return

	var target_x := target.global_position.x
	if not _initialized:
		# First frame: snap instead of easing in from the world origin.
		_initialized = true
		_last_target_x = target_x
		global_position = Vector2(target_x, fixed_y if lock_vertical else global_position.y)
		return

	# Estimate target velocity from movement — no coupling to its script.
	var velocity_x := (target_x - _last_target_x) / delta
	_last_target_x = target_x

	var desired_look := clampf(velocity_x * look_ahead_time, -max_look_ahead, max_look_ahead)
	_look_ahead = lerpf(_look_ahead, desired_look, 1.0 - exp(-look_ahead_damping * delta))

	var desired_x := target_x + _look_ahead
	global_position.x = lerpf(global_position.x, desired_x, 1.0 - exp(-position_damping * delta))
	if lock_vertical:
		global_position.y = fixed_y
