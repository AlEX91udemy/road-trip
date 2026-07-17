class_name PlayerCar
extends Node2D
## The player's car. Composed from small, replaceable components:
##  - MovementComponent — speed simulation (throttle -> smooth px/s)
##  - SwayComponent     — cosmetic body bob/tilt (wired to movement via
##                        signal inside player_car.tscn)
##
## Keep-Driving-style driving model: the car cruises on its own along a calm
## highway — the framing keeps it visually still while the world slides past.
## There is nothing to dodge; fuel is the pressure. Low fuel starves the
## engine (power fades), an empty tank rolls the car to a stop.
##
## This script only: applies motion, spins the wheels and broadcasts
## telemetry. It knows NOTHING about the road, the camera or the HUD — the
## Main scene wires those up through signals, so any of them can be swapped
## without touching this file.

## Current speed for display, in km/h. Connected to the HUD by Main.
signal speed_changed(speed_kmh: float)
## Total distance travelled, in meters. Connected to the HUD by Main.
signal distance_changed(distance_m: float)
## The engine died (no fuel) and the car has rolled to a complete stop.
## Emitted exactly once.
signal stalled

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
## Fuel level (percent) below which the engine starts losing power: top speed
## fades linearly from here down to a dead stop at 0%.
@export var low_fuel_threshold := 15.0

## Total distance travelled so far, in meters. Read-only telemetry.
var distance_m: float:
	get:
		return _distance_m

var _distance_m := 0.0
var _last_speed_kmh := -1.0
var _last_distance_m := -1.0
var _stalled := false

func _physics_process(delta: float) -> void:
	if movement == null:
		return

	# Cruise: the throttle stays open, MovementComponent shapes the ramp.
	movement.set_throttle(1.0)
	var speed_px := movement.step(delta)

	# Move the car through the world; everything else (camera, road, parallax)
	# reacts to that on its own.
	position.x += speed_px * delta
	_distance_m += speed_px * delta / pixels_per_meter
	_spin_wheels(speed_px, delta)
	_emit_telemetry(speed_px)

	if movement.power_scale <= 0.0 and speed_px <= 0.0 and not _stalled:
		_stalled = true
		stalled.emit()


## Fed the fuel level (percent) by Main; translates it into engine power so
## a draining tank gradually starves the drivetrain instead of cutting out.
func set_fuel(percent: float) -> void:
	if movement != null:
		movement.power_scale = percent / low_fuel_threshold


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
