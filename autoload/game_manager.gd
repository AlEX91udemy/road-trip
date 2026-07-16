extends Node
## GameManager (autoload) — the only allowed singleton.
##
## Owns run lifecycle state: a run is active until the player crashes
## (end_run), the whole tree pauses on game over, and restart_run reloads the
## scene for a fresh start. Everything is exposed through signals so no
## gameplay system ever needs a hard reference to another one.

## Emitted whenever the fuel level changes. Day 1 never changes it, but the
## HUD already listens, so Day 2 fuel consumption plugs in with zero UI work.
signal fuel_changed(percent: float)
## The current run just ended (player crashed). Carries the final distance.
signal run_ended(distance_m: float)

const FUEL_FULL := 100.0

## Fuel level in percent. Placeholder: stays at 100% for the whole of Day 1.
var fuel: float = FUEL_FULL:
	set(value):
		fuel = clampf(value, 0.0, FUEL_FULL)
		fuel_changed.emit(fuel)

## True while the player is driving; false between crash and restart.
var run_active := false

## Called by Main on scene (re)load: resets run state for a fresh start.
func start_run() -> void:
	run_active = true
	fuel = FUEL_FULL
	get_tree().paused = false


## Ends the run exactly once: freezes the world and announces the result.
## Pausing the tree stops every gameplay node mid-frame; the game-over screen
## runs with process_mode ALWAYS, so it stays interactive.
func end_run(distance_m: float) -> void:
	if not run_active:
		return
	run_active = false
	get_tree().paused = true
	run_ended.emit(distance_m)


## Unpauses and reloads the current scene; start_run() then re-arms the state.
func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
