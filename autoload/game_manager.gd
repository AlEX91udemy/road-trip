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
## The current run just ended. Carries the final distance and why it ended.
signal run_ended(distance_m: float, reason: RunEndReason)

enum RunEndReason { CRASHED, OUT_OF_FUEL }

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

## True while the player is driving; false between crash and restart.
var run_active := false

var _consumed_upto_m := 0.0  # distance already billed for fuel

## Called by Main on scene (re)load: resets run state for a fresh start.
func start_run() -> void:
	run_active = true
	fuel = FUEL_FULL
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
