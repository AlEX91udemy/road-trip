extends Node2D
## Composition root. The ONLY place where systems learn about each other,
## and always through signals:
##
##   PlayerCar.speed_changed / distance_changed  ──►  HUD
##   PlayerCar.distance_changed                  ──►  GameManager (fuel burn)
##   PlayerCar.crashed / stalled                 ──►  GameManager.end_run
##   GameManager.fuel_changed                    ──►  HUD + PlayerCar power
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

	# Fuel loop: driving burns fuel, the fuel level feeds engine power back.
	player.distance_changed.connect(GameManager.report_distance)
	GameManager.fuel_changed.connect(player.set_fuel)

	# Run end (crash or dry tank) -> game over screen -> restart, signals only.
	player.crashed.connect(_on_player_crashed)
	player.stalled.connect(_on_player_stalled)
	GameManager.run_ended.connect(game_over.open)
	game_over.restart_requested.connect(GameManager.restart_run)

	# Prime the HUD so it shows correct values before the first signal fires.
	hud.display_speed(0.0)
	hud.display_distance(0.0)
	hud.display_fuel(GameManager.fuel)

	GameManager.start_run()


func _on_player_crashed() -> void:
	# The player only announces what happened; consequences are decided here.
	GameManager.end_run(player.distance_m, GameManager.RunEndReason.CRASHED)


func _on_player_stalled() -> void:
	GameManager.end_run(player.distance_m, GameManager.RunEndReason.OUT_OF_FUEL)
