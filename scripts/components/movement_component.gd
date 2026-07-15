class_name MovementComponent
extends Node
## Reusable scalar "drivetrain": turns a throttle intent (-1..1) into a smooth
## forward speed in pixels/second.
##
## Deliberately knows nothing about input, sprites or the scene tree — the
## owner reads input (or AI, for Day 2 traffic) and calls set_throttle(),
## then steps the component from its own _physics_process. That keeps update
## order deterministic and lets any vehicle reuse this unchanged.

## Emitted whenever the speed meaningfully changes (px/s). Other components
## (sway, wheel spin, audio later) drive themselves from this.
signal speed_changed(speed: float)

## Top speed in pixels/second.
@export var max_speed := 420.0
## Base acceleration in px/s². Tapers off near max_speed for a natural ramp.
@export var acceleration := 170.0
## Deceleration applied while braking, in px/s².
@export var brake_strength := 380.0
## Passive deceleration while coasting (no throttle), in px/s².
@export var coast_drag := 60.0
## Exponent shaping the acceleration falloff toward max speed (higher = the
## last few km/h take longer, like a real engine running out of torque).
@export_range(1.0, 3.0) var accel_falloff := 1.4

## Current forward speed in px/s. Read-only for owners; write via step().
var speed := 0.0

var _throttle := 0.0
var _last_emitted_speed := -1.0

## Throttle intent: 1 = full accelerator, -1 = full brake, 0 = coast.
func set_throttle(value: float) -> void:
	_throttle = clampf(value, -1.0, 1.0)


## Advance the simulation by delta seconds. Called by the owner every physics
## frame; returns the new speed for convenience.
func step(delta: float) -> float:
	var accel := 0.0
	if _throttle > 0.0:
		# Smooth ramp: full torque from standstill, fading to zero at max speed.
		accel = _throttle * acceleration * (1.0 - pow(speed / max_speed, accel_falloff))
	elif _throttle < 0.0:
		accel = _throttle * brake_strength
	elif speed > 0.0:
		accel = -coast_drag

	speed = clampf(speed + accel * delta, 0.0, max_speed)
	if speed < 1.0 and _throttle <= 0.0:
		speed = 0.0  # snap to rest instead of crawling forever

	if not is_equal_approx(speed, _last_emitted_speed):
		_last_emitted_speed = speed
		speed_changed.emit(speed)
	return speed
