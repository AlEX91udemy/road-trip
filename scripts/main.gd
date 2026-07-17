extends Node2D
## Composition root. The ONLY place where systems learn about each other,
## and always through signals:
##
##   PlayerCar.speed_changed / distance_changed  ──►  HUD
##   PlayerCar.distance_changed                  ──►  GameManager (fuel burn)
##   PlayerCar.stalled                           ──►  GameManager.end_run
##   GameManager.fuel_changed                    ──►  HUD + PlayerCar power
##   GameManager.run_ended                       ──►  GameOverScreen.open
##   GameOverScreen.restart_requested            ──►  GameManager.restart_run
##   GasStation.refuel_requested                 ──►  GameManager.try_refuel
##   GasStation.passed                           ──►  next goal + next station
##   PlayerCar.distance_changed                  ──►  EventManager (event roll)
##   EventManager.event_triggered                ──►  EventPopup.open
##   EventPopup.resolved                         ──►  EventManager.complete_event
##
## Camera / RoadManager targets are plain Node2D refs set in the scene.
## The player never references the road; managers never reference the HUD.
## Swapping any single system means re-wiring only this file / scene.

@export var player: PlayerCar
@export var hud: Hud
@export var game_over: GameOverScreen
## Scene for the trip-goal gas station, spawned ahead of the player.
@export var gas_station_scene: PackedScene
## World Y where a station's base sits (the road's far shoulder).
@export var station_ground_y := 262.0
@export var event_manager: EventManager
@export var event_popup: EventPopup

var _station: GasStation

func _ready() -> void:
	if player == null or hud == null or game_over == null or gas_station_scene == null \
			or event_manager == null or event_popup == null:
		push_error("Main scene is missing its player/hud/game_over/gas_station/event wiring.")
		return

	# Gameplay -> UI, signals only.
	player.speed_changed.connect(hud.display_speed)
	player.distance_changed.connect(hud.display_distance)
	GameManager.fuel_changed.connect(hud.display_fuel)
	GameManager.money_changed.connect(hud.display_money)

	# Fuel loop: driving burns fuel, the fuel level feeds engine power back.
	player.distance_changed.connect(GameManager.report_distance)
	GameManager.fuel_changed.connect(player.set_fuel)

	# Run end (dry tank) -> game over screen -> restart, signals only.
	player.stalled.connect(_on_player_stalled)
	GameManager.run_ended.connect(_on_run_ended)
	game_over.restart_requested.connect(GameManager.restart_run)

	# Roadside events: distance rolls the next event, the popup shows it,
	# and resolving it re-arms the manager for the next check.
	player.distance_changed.connect(event_manager.report_distance)
	event_manager.event_triggered.connect(event_popup.open)
	event_popup.resolved.connect(_on_event_resolved)

	# Prime the HUD so it shows correct values before the first signal fires.
	hud.display_speed(0.0)
	hud.display_distance(0.0)
	hud.display_fuel(GameManager.fuel)
	hud.display_money(GameManager.money)

	GameManager.start_run()
	_spawn_station()


## Places the current trip goal in the world, far enough ahead that the
## player sees it approaching long before reaching it.
func _spawn_station() -> void:
	_station = gas_station_scene.instantiate()
	_station.position = Vector2(
			GameManager.next_station_m * player.pixels_per_meter, station_ground_y)
	_station.refuel_requested.connect(GameManager.try_refuel)
	# Deferred: `passed` is emitted from a physics callback (area_exited), and
	# freeing/spawning Area2D nodes while the physics server is flushing
	# queries is forbidden — so handle it on the next idle frame.
	_station.passed.connect(_on_station_passed, CONNECT_DEFERRED)
	add_child(_station)


func _on_station_passed() -> void:
	# The old goal is done with — it vanishes and the next one appears ahead.
	GameManager.advance_station()
	_station.queue_free()
	_spawn_station()


func _on_player_stalled() -> void:
	# The player only announces what happened; consequences are decided here.
	GameManager.end_run(player.distance_m, GameManager.RunEndReason.OUT_OF_FUEL)


func _on_run_ended(distance_m: float, reason: GameManager.RunEndReason) -> void:
	# An event could in principle still be open the instant the tank runs
	# dry; close it so it can't stay stacked on top of the Game Over screen.
	event_popup.close()
	game_over.open(distance_m, reason)


func _on_event_resolved() -> void:
	event_manager.complete_event()
