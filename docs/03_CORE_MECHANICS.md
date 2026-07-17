# Core Mechanics

Source of truth for every number below: `autoload/game_manager.gd`,
`scripts/player/player_car.gd`, `scripts/components/movement_component.gd`.

## Drivetrain (`MovementComponent`)

- Throttle is always `1.0` — the player never controls it. `set_throttle()`
  and braking (`throttle < 0`) exist in the component but nothing in the
  current game ever calls for braking.
- `max_speed = 420` px/s, `acceleration = 170` px/s² (per-instance override:
  the player car's `MovementComponent` sets `acceleration = 80` in
  `player_car.tscn`).
- Acceleration tapers toward top speed via `accel_falloff` (1.4): the last
  few km/h take longer to reach, like an engine running out of torque.
- `power_scale` (0..1, clamped) multiplies both acceleration and the
  reachable top speed (`effective_max = max_speed * power_scale`). At
  `power_scale = 0` the car only coasts and decelerates
  (`coast_drag = 60` px/s²) to a full stop.

## Fuel

- `FUEL_FULL = 100`, burn rate `FUEL_PER_100M = 5` (percent per 100 m) — a
  full tank lasts exactly **2000 m**.
- `FUEL_DRY = 0.5`: below this the tank is forced to exactly `0`, so the car
  can't creep along asymptotically forever on fuel fumes.
- `report_distance()` only burns fuel for the *new* distance since the last
  report (`_consumed_upto_m`), so it's safe to call every frame.
- **Engine starvation:** `PlayerCar.low_fuel_threshold = 15` (percent).
  `set_fuel()` sets `power_scale = fuel_percent / 15`, clamped to `[0, 1]` by
  `MovementComponent`'s setter — so power is full (`1.0`) at any fuel level
  ≥ 15%, and fades linearly from `1.0` at 15% down to `0.0` at 0%.

## Money

- `START_MONEY = 50` ($), no income exists anywhere in the codebase — the
  budget only ever shrinks.
- `REFUEL_COST = 20` (fixed price, always fills the tank to 100%).
- `REFUEL_REFUSE_ABOVE = 95`: `try_refuel()` silently does nothing if fuel is
  already ≥ 95% (guards against double-charging near a full tank) or if
  `money < REFUEL_COST`.

## Trip goal / gas stations

- `FIRST_STATION_M = 800`, then every `STATION_SPACING_M = 1000` m after —
  comfortably under a full tank's 2000 m range so every leg is drivable
  after a refuel.
- A station (`GasStation`) is a dumb world object: a `Trigger` Area2D
  (140×80, `collision_mask = 1`, `monitorable = false`) that shows a hint
  label while the player is inside, and emits `refuel_requested` on `E` /
  `passed` on exit toward the far side (`area.global_position.x >
  global_position.x`).
- The station never touches fuel or money directly — `Main` routes its
  signals to `GameManager`. Only one station exists in the world at a time;
  `Main` frees the old one and spawns the next after `passed`.

## Player presence (collision)

- The player has a `PresenceArea` Area2D (`collision_layer = 1`, no mask) —
  the only thing on layer 1. It exists solely so the gas station's
  `Trigger` (`mask = 1`) can detect the player; it carries no gameplay logic
  of its own. This is the only collision-based mechanic left in the game
  after lane-switching/traffic/crash detection was removed (`13_DECISIONS.md`).
- The station's `passed` signal is connected with `CONNECT_DEFERRED`
  (`scripts/main.gd`) because it fires from inside a physics
  `area_exited` callback, and freeing/spawning Area2D-bearing nodes mid
  physics-flush is forbidden by Godot.

## World scale & telemetry

- `pixels_per_meter = 10` (on `PlayerCar`) is the single conversion point
  between world pixels and real-world meters/km-h; `GameManager` and `Main`
  both reuse it (e.g. to place a station at `next_station_m *
  pixels_per_meter`).
- Speed and distance signals only fire when the *displayed* value would
  actually change (`speed` ≥ 0.5 km/h delta, `distance` ≥ 1 m delta), so the
  HUD isn't rebuilt 60×/second for nothing.

## Ending and restart

- Exactly one end condition today: `RunEndReason.OUT_OF_FUEL`, triggered
  when `MovementComponent.power_scale <= 0` and `speed <= 0` simultaneously.
- `end_run()` is idempotent (`run_active` guard) — it can only fire once per
  run — and pauses the entire scene tree (`get_tree().paused = true`).
- `restart_run()` unpauses and **reloads the current scene** — this is a
  full reset, not an in-place state clear, so every streamed/pooled system
  (road chunks, camera, gas station) rebuilds from a clean slate.
