class_name Hud
extends CanvasLayer
## Pure presentation layer. Exposes dumb display_* methods that take
## ready-to-show values; it holds no game state and pulls nothing itself.
## Whoever owns the data (Main / GameManager) pushes values in via signals,
## so this HUD can be restyled or replaced without touching gameplay code.

@export var speed_label: Label
@export var distance_label: Label
@export var fuel_label: Label

func display_speed(speed_kmh: float) -> void:
	speed_label.text = "%3.0f km/h" % speed_kmh


func display_distance(distance_m: float) -> void:
	if distance_m < 1000.0:
		distance_label.text = "%.0f m" % distance_m
	else:
		distance_label.text = "%.2f km" % (distance_m / 1000.0)


func display_fuel(percent: float) -> void:
	fuel_label.text = "Fuel %.0f%%" % percent
