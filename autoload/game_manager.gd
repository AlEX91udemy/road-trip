extends Node
## GameManager (autoload) — the only allowed singleton.
##
## Day 1: only holds the fuel placeholder so the HUD has a single source of
## truth for it. Day 2 will grow run state here (fuel consumption, money,
## event flow, pause/game-over), always exposed through signals so no system
## ever needs a hard reference to another gameplay system.

## Emitted whenever the fuel level changes. Day 1 never changes it, but the
## HUD already listens, so Day 2 fuel consumption plugs in with zero UI work.
signal fuel_changed(percent: float)

const FUEL_FULL := 100.0

## Fuel level in percent. Placeholder: stays at 100% for the whole of Day 1.
var fuel: float = FUEL_FULL:
	set(value):
		fuel = clampf(value, 0.0, FUEL_FULL)
		fuel_changed.emit(fuel)
