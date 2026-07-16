class_name Hud
extends CanvasLayer
## Pure presentation layer. Exposes dumb display_* methods that take
## ready-to-show values; it holds no game state and pulls nothing itself.
## Whoever owns the data (Main / GameManager) pushes values in via signals,
## so this HUD can be restyled or replaced without touching gameplay code.

@export var speed_label: Label
@export var distance_label: Label
@export var fuel_label: Label
@export var money_label: Label

func display_speed(speed_kmh: float) -> void:
	speed_label.text = UiFormat.speed_text(speed_kmh)


func display_distance(distance_m: float) -> void:
	distance_label.text = UiFormat.distance_text(distance_m)


func display_money(amount: int) -> void:
	money_label.text = UiFormat.money_text(amount)


func display_fuel(percent: float) -> void:
	fuel_label.text = "Fuel %.0f%%" % percent
