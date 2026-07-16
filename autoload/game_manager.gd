extends Node
## GameManager (autoload) — the only allowed singleton.
##
## Owns run lifecycle and run resources (fuel): a run is active until the
## player crashes or runs the tank dry, the whole tree pauses on game over,
## and restart_run reloads the scene for a fresh start. Everything is exposed
## through signals so no gameplay system ever needs a hard reference to
## another one.

## Emitted whenever the fuel level changes. The HUD displays it and the
## player car derives its engine power from it.
signal fuel_changed(percent: float)
## Emitted whenever the money amount changes. The HUD displays it.
signal money_changed(amount: int)
## The current run just ended. Carries the final distance and why it ended.
signal run_ended(distance_m: float, reason: RunEndReason)

enum RunEndReason { CRASHED, OUT_OF_FUEL }

## Money the player starts a run with. There is no income — the budget only
## shrinks, which is what eventually ends every trip.
const START_MONEY := 50
## Fixed price of one visit to the pump: the tank is always filled up whole.
const REFUEL_COST := 20
## No refuel above this level — a moving car is never at exactly 100%, and
## without the margin a double-press at the pump would charge twice.
const REFUEL_REFUSE_ABOVE := 95.0

## Where the first gas station stands, in meters from the start.
const FIRST_STATION_M := 800.0
## Distance between consecutive stations, in meters. Must stay comfortably
## under a full tank's range (2 000 m) so every leg is drivable after refuel.
const STATION_SPACING_M := 1000.0

const FUEL_FULL := 100.0
## Fuel burned per 100 m driven, in percent: a full tank lasts 2 000 m.
const FUEL_PER_100M := 5.0
## Below this the tank counts as empty. Without a cutoff the car would creep
## asymptotically forever: less fuel -> slower -> the last drops burn slower.
const FUEL_DRY := 0.5

## Fuel level in percent. The setter clamps and broadcasts every change.
var fuel: float = FUEL_FULL:
	set(value):
		fuel = clampf(value, 0.0, FUEL_FULL)
		fuel_changed.emit(fuel)

## Money on hand. The setter clamps and broadcasts every change.
var money: int = START_MONEY:
	set(value):
		money = maxi(value, 0)
		money_changed.emit(money)

## True while the player is driving; false between crash and restart.
var run_active := false

## Distance of the current trip goal (the next gas station), in meters.
## Main reads it to place the station in the world.
var next_station_m := FIRST_STATION_M

var _consumed_upto_m := 0.0  # distance already billed for fuel

## Called by Main on scene (re)load: resets run state for a fresh start.
func start_run() -> void:
	run_active = true
	fuel = FUEL_FULL
	money = START_MONEY
	next_station_m = FIRST_STATION_M
	_consumed_upto_m = 0.0
	get_tree().paused = false


## Fed by the player's distance telemetry (wired in Main): burns fuel for the
## meters driven since the last report.
func report_distance(distance_m: float) -> void:
	if not run_active:
		return
	var meters := distance_m - _consumed_upto_m
	if meters <= 0.0:
		return
	_consumed_upto_m = distance_m
	var remaining := fuel - meters * FUEL_PER_100M / 100.0
	fuel = 0.0 if remaining < FUEL_DRY else remaining


## Fills the tank for the fixed price. Silently refuses when the tank is
## practically full or the money isn't there — the HUD tells the player why.
func try_refuel() -> void:
	if not run_active or fuel >= REFUEL_REFUSE_ABOVE or money < REFUEL_COST:
		return
	money -= REFUEL_COST
	fuel = FUEL_FULL


## Moves the trip goal to the next station down the road. Called by Main
## once the player has driven past the current one.
func advance_station() -> void:
	next_station_m += STATION_SPACING_M


## Ends the run exactly once: freezes the world and announces the result.
## Pausing the tree stops every gameplay node mid-frame; the game-over screen
## runs with process_mode ALWAYS, so it stays interactive.
func end_run(distance_m: float, reason: RunEndReason) -> void:
	if not run_active:
		return
	run_active = false
	get_tree().paused = true
	run_ended.emit(distance_m, reason)


## Unpauses and reloads the current scene; start_run() then re-arms the state.
func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
