extends Node2D
## Composition root. The ONLY place where systems learn about each other,
## and always through signals:
##
##   PlayerCar.speed_changed / distance_changed  ──►  HUD
##   PlayerCar.crashed                           ──►  GameManager.end_run
##   GameManager.fuel_changed                    ──►  HUD
##   GameManager.run_ended                       ──►  GameOverScreen.open
##   GameOverScreen.restart_requested            ──►  GameManager.restart_run
##
## Camera / RoadManager / TrafficManager targets are plain Node2D refs set in
## the scene. Player never references TrafficManager; TrafficManager never
## references the HUD. Swapping any single system means re-wiring only this
## file / scene.

@export var player: PlayerCar
@export var hud: Hud
@export var game_over: GameOverScreen

func _ready() -> void:
	if player == null or hud == null or game_over == null:
		push_error("Main scene is missing its player/hud/game_over wiring.")
		return

	# Gameplay -> UI, signals only.
	player.speed_changed.connect(hud.display_speed)
	player.distance_changed.connect(hud.display_distance)
	GameManager.fuel_changed.connect(hud.display_fuel)

	# Crash -> run end -> game over screen -> restart, still signals only.
	player.crashed.connect(_on_player_crashed)
	GameManager.run_ended.connect(game_over.open)
	game_over.restart_requested.connect(GameManager.restart_run)

	# Prime the HUD so it shows correct values before the first signal fires.
	hud.display_speed(0.0)
	hud.display_distance(0.0)
	hud.display_fuel(GameManager.fuel)

	GameManager.start_run()


func _on_player_crashed() -> void:
	# The player only announces the crash; consequences are decided here.
	GameManager.end_run(player.distance_m)
