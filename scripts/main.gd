extends Node2D
## Composition root. The ONLY place where systems learn about each other,
## and always through signals:
##
##   PlayerCar.speed_changed / distance_changed  ──►  HUD
##   GameManager.fuel_changed                    ──►  HUD
##   Camera / RoadManager targets are plain Node2D refs set in the scene.
##
## Player never references RoadManager; RoadManager never references the HUD.
## Swapping any single system means re-wiring only this file / scene.

@export var player: PlayerCar
@export var hud: Hud

func _ready() -> void:
	if player == null or hud == null:
		push_error("Main scene is missing its player/hud wiring.")
		return

	# Gameplay -> UI, signals only.
	player.speed_changed.connect(hud.display_speed)
	player.distance_changed.connect(hud.display_distance)
	GameManager.fuel_changed.connect(hud.display_fuel)

	# Prime the HUD so it shows correct values before the first signal fires.
	hud.display_speed(0.0)
	hud.display_distance(0.0)
	hud.display_fuel(GameManager.fuel)
