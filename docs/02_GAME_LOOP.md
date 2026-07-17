# Game Loop

## Signal wiring (the whole loop in one table)

Everything below is wired in exactly one place, `scripts/main.gd`, always
through signals (`Main._ready()`):

```
PlayerCar.speed_changed / distance_changed  ──►  HUD
PlayerCar.distance_changed                  ──►  GameManager (fuel burn)
PlayerCar.stalled                           ──►  GameManager.end_run
GameManager.fuel_changed                    ──►  HUD + PlayerCar power
GameManager.run_ended                       ──►  GameOverScreen.open
GameOverScreen.restart_requested            ──►  GameManager.restart_run
GasStation.refuel_requested                 ──►  GameManager.try_refuel
GasStation.passed                           ──►  next goal + next station
```

## Step by step

1. **Run starts** — `GameManager.start_run()`: fuel = 100%, money = $50,
   trip goal = the first gas station at 800 m, tree unpaused.
2. **The car cruises on its own.** `PlayerCar` holds the throttle fully open
   every physics frame; `MovementComponent` ramps speed up toward its max
   (420 px/s) with a torque-falloff curve. The player does nothing here.
3. **Fuel drains with distance.** `PlayerCar.distance_changed` feeds
   `GameManager.report_distance()`, which burns 5% fuel per 100 m travelled
   (a full tank is good for 2000 m).
4. **The HUD reflects state continuously**: speed, distance, fuel %, money —
   pushed by `Main`, displayed by `Hud` (pure presentation, no logic).
5. **A gas station is always ahead.** `Main._spawn_station()` places the next
   one at `GameManager.next_station_m`, converted to world pixels via
   `PlayerCar.pixels_per_meter`.
6. **Entering the station's trigger zone** shows a refuel hint
   (`GasStation` shows/hides `HintLabel` on `area_entered`/`area_exited` of
   its `Trigger` Area2D).
7. **The player decides: refuel or not.** Pressing `E` inside the zone emits
   `refuel_requested` → `GameManager.try_refuel()`, which charges a fixed
   $20 and fills the tank — but only if fuel is below 95% (avoids
   double-charging a near-full tank) and there's enough money. Refuse is
   silent; the HUD is the only feedback (fuel/money don't move).
8. **Passing the station** (leaving its trigger zone on the far side) fires
   `passed` → `Main._on_station_passed()`: the current station is freed and
   the next one is spawned 1000 m further down the road
   (`GameManager.advance_station()`).
9. **Below 15% fuel, the engine starves.** `GameManager.fuel_changed` feeds
   `PlayerCar.set_fuel()`, which sets `MovementComponent.power_scale =
   fuel% / 15` (clamped 0..1) — both acceleration and reachable top speed
   fade linearly as fuel drops from 15% to 0%.
10. **At 0% fuel the car rolls to a stop.** Below `FUEL_DRY` (0.5%) the tank
    is treated as empty; once speed and power both hit zero, `PlayerCar`
    emits `stalled` exactly once.
11. **The run ends.** `Main` routes `stalled` to
    `GameManager.end_run(distance, OUT_OF_FUEL)`, which pauses the entire
    scene tree and emits `run_ended`.
12. **Game Over.** `GameOverScreen.open()` shows "OUT OF FUEL" and the total
    distance driven. It runs with `process_mode = ALWAYS` so it keeps
    receiving input while everything else is frozen.
13. **Restart.** Pressing `R`/`Enter` emits `restart_requested` →
    `GameManager.restart_run()`, which unpauses and reloads the scene —
    every system (fuel, money, road streaming, camera) rebuilds from
    scratch via step 1.

## Design note: two independent ways to fail, one enforced ending

Only `OUT_OF_FUEL` actually ends a run today. Running out of money doesn't
end anything by itself — `try_refuel()` just silently refuses — but since
there's no income anywhere in the game, an empty wallet makes a later
`OUT_OF_FUEL` inevitable. In practice the loop has one hard failure state
and one soft one that guarantees the hard one eventually triggers.
