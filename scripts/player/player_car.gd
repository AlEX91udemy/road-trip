class_name PlayerCar
extends Node2D
## The player's car. Composed from small, replaceable components:
##  - MovementComponent — speed simulation (reusable by Day 2 traffic)
##  - SwayComponent     — cosmetic body bob/tilt (wired to movement via signal
##                        inside player_car.tscn)
##
## This script only: reads input, applies the resulting motion, spins the
## wheels, and broadcasts telemetry. It knows NOTHING about the road, the
## camera or the HUD — the Main scene wires those up through signals, so any
## of them can be swapped without touching this file.

## Current speed for display, in km/h. Connected to the HUD by Main.
signal speed_changed(speed_kmh: float)
## Total distance travelled, in meters. Connected to the HUD by Main.
signal distance_changed(distance_m: float)

## The drivetrain component driving this car.
@export var movement: MovementComponent
## Wheel sprites, rotated visually according to speed.
@export var front_wheel: Sprite2D
@export var back_wheel: Sprite2D
## Visual wheel radius in pixels (used to convert speed into spin rate).
@export var wheel_radius_px := 6.0
## World scale: how many pixels equal one meter. Owns the unit conversion so
## km/h and meters are computed in exactly one place.
@export var pixels_per_meter := 10.0

const ACTION_ACCELERATE := "accelerate"
const ACTION_BRAKE := "brake"

var _distance_m := 0.0
var _last_speed_kmh := -1.0
var _last_distance_m := -1.0

func _physics_process(delta: float) -> void:
	if movement == null:
		return

	# get_axis: brake pulls toward -1, accelerate toward +1.
	movement.set_throttle(Input.get_axis(ACTION_BRAKE, ACTION_ACCELERATE))
	var speed_px := movement.step(delta)

	# Move the car through the world; everything else (camera, road, parallax)
	# reacts to that on its own.
	position.x += speed_px * delta
	_distance_m += speed_px * delta / pixels_per_meter
	_spin_wheels(speed_px, delta)
	_emit_telemetry(speed_px)


func _spin_wheels(speed_px: float, delta: float) -> void:
	var spin := (speed_px / wheel_radius_px) * delta  # radians: v = ω·r
	for wheel in [front_wheel, back_wheel]:
		if wheel != null:
			wheel.rotation += spin


func _emit_telemetry(speed_px: float) -> void:
	# Only emit when the displayed value would actually change,
	# so HUD labels are not rebuilt 60 times per second for nothing.
	var speed_kmh := speed_px / pixels_per_meter * 3.6
	if absf(speed_kmh - _last_speed_kmh) >= 0.5:
		_last_speed_kmh = speed_kmh
		speed_changed.emit(speed_kmh)
	if _distance_m - _last_distance_m >= 1.0:
		_last_distance_m = _distance_m
		distance_changed.emit(_distance_m)
