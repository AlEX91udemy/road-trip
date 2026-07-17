# Road Trip

Pixel-art side-view road-trip game (inspired by *Keep Driving*), built with
**Godot 4.4**, GDScript only.

## Description

Road Trip is an atmospheric game about a drive across the country. It is
**not** a game about collisions, and **not** about dodging oncoming traffic
— the car drives itself down the road. Core loop: drive → make decisions →
explore → refuel → keep going.

The only constant pressure is fuel: it burns with distance, and running dry
ends the trip. Gas stations along the road are the recurring decision point
— stop and pay to refuel, or press on and hope the tank lasts.

## Currently implemented mechanics

- **Endless road** — the road streams forever out of pooled segments ahead
  of the camera and recycles them behind it; no hand-placed level.
- **Car movement** — the car accelerates on its own down the road; there is
  no steering or lane input. The only pressure is fuel.
- **Fuel consumption** — the tank drains with distance driven; below 15% the
  engine gradually loses power, and an empty tank rolls the car to a stop.
- **Gas stations** — spawn ahead as the trip goal (first at 800 m, then
  every 1000 m); entering the station's zone and pressing **E** refuels for
  a fixed price out of the starting budget.
- **HUD** — live speed, distance travelled, fuel %, and money.
- **Game Over on empty fuel** — the only way a run currently ends; shows the
  distance driven and lets the player restart.

## How to run

1. Open Godot 4.4, click **Import**, and select this folder's `project.godot`.
2. Press **F5** (Play). The main scene is already configured — it runs immediately.
3. Controls:
   - **E** — refuel (inside a gas-station zone)
   - **R / Enter** — restart (on the Game Over screen)

The car needs no driving input at all — there is nothing else to press.

## Project layout

| Path | Purpose |
|---|---|
| `scenes/main.tscn` | Composition root: parallax, road, player, camera, UI |
| `scenes/player_car.tscn` | Player car (sprites + movement/sway components) |
| `scenes/road_chunk.tscn` | One pooled road segment, with roadside Marker2D slots |
| `scenes/gas_station.tscn` | Trip-goal gas station: refuel zone + hint (spawned by Main) |
| `scripts/main.gd` | Wires systems together via signals (the only coupling point) |
| `scripts/player/player_car.gd` | Auto-drive, engine power from fuel, telemetry / stall signal |
| `scripts/components/movement_component.gd` | Reusable drivetrain (throttle → speed) |
| `scripts/components/sway_component.gd` | Cosmetic body bob/tilt |
| `scripts/components/node_pool.gd` | Generic scene-instance pool (leak-free) |
| `scripts/camera/follow_camera.gd` | Damped follow + speed-based look-ahead |
| `scripts/road/road_manager.gd` | Infinite road streaming (spawn/despawn via pool) |
| `scripts/road/road_chunk.gd` | Chunk data + decoration slots |
| `scripts/road/gas_station.gd` | Station behavior: hint + refuel/passed intents |
| `ui/hud.tscn`, `ui/hud.gd` | CanvasLayer HUD: speed, distance, fuel, money |
| `ui/game_over.tscn`, `ui/game_over.gd` | Game Over overlay (out of fuel); emits a restart request |
| `ui/ui_format.gd` | Shared number formatting for HUD and Game Over |
| `autoload/game_manager.gd` | The one allowed singleton — run lifecycle, fuel, money, trip goal |
| `assets/sprites/` | Generated placeholder pixel art |
| `tools/generate_placeholder_art.py` | Regenerates all placeholder art (`python3 tools/generate_placeholder_art.py`) |
| `docs/` | Road Trip Bible — vision, design, mechanics, architecture, roadmap, decisions |

## Architecture

- Systems are independent; **all cross-system communication goes through
  signals**, connected in exactly one place (`scripts/main.gd`): the stall
  signal → `GameManager.end_run` → Game Over screen → restart, and station
  `refuel_requested` → `GameManager.try_refuel`. Managers never reference
  the HUD.
- The fuel loop is two one-way signals: driving distance feeds
  `GameManager.report_distance` (burn), and `fuel_changed` feeds the car's
  engine `power_scale` back — low fuel gradually starves the engine instead
  of cutting it out (with a 0.5% dry cutoff so the car can't creep forever).
- The gas station is a dumb world object: it emits intents and knows nothing
  about money or fuel; `GameManager` owns the goal distance and the wallet,
  `Main` places each next station. No screens, no scene reloads mid-trip.
- The camera and road only know an abstract `Node2D` target/anchor, so
  either can be pointed at anything.
- Composition over inheritance: the car is assembled from
  `MovementComponent` and `SwayComponent`.
- `NodePool` recycles road chunks — endless driving allocates a fixed number
  of nodes, and pooled nodes stay parented to the tree, so nothing leaks.
- On an empty tank the whole tree pauses; the Game Over screen runs with
  `process_mode = ALWAYS` and asks `GameManager` to reload the scene.
- Tunables (speeds, damping, spawn distances, sway…) are `@export`ed, no
  magic numbers buried in logic.
- Scene note: exported node references require the `node_paths` attribute in
  `.tscn` node headers — hand-edited scenes must keep it in sync with the
  script's `@export var x: Node...` properties.

## Roadmap

Next stage of the project, in no particular order — see `docs/` for the full
design (Vision, Game Design Document, Roadmap):

- **Events** — things that can happen along the road beyond refueling.
- **Exploration** — reasons to notice and engage with the world, not just
  drive through it.
- **Map** — a sense of place and progress across the trip.
- **Economy** — sources of money, not just the current one-way spend.
- **Saves** — persisting a trip across sessions.
