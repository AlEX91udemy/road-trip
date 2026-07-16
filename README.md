# Road Trip — Day 2

Pixel-art side-view driving game (inspired by *Keep Driving*), built with
**Godot 4.4**, GDScript only.

Gameplay: the car accelerates on its own down an endless three-lane highway;
the player switches lanes to dodge oncoming traffic. Driving burns fuel — a
full tank lasts 2 km. Below 15% the engine gradually loses power, and on an
empty tank the car rolls to a stop: OUT OF FUEL. Gas stations stand along the
road (at 800 m, then every 1 000 m) as the trip goal; a fill-up costs a fixed
$20 out of the starting $50 budget, there is no income, so every trip ends
eventually — crash, dry tank, or an empty wallet down the line.

## How to run

1. Open Godot 4.4, click **Import**, and select this folder's `project.godot`.
2. Press **F5** (Play). The main scene is already configured — it runs immediately.
3. Controls:
   - **W / ↑** — move one lane up
   - **S / ↓** — move one lane down
   - **E** — refuel (inside a gas-station zone)
   - **R / Enter** — restart (on the Game Over screen)

## Project layout

| Path | Purpose |
|---|---|
| `scenes/main.tscn` | Composition root: parallax, road, traffic, player, camera, UI |
| `scenes/player_car.tscn` | Player car (sprites + movement/lane-switch/sway components) |
| `scenes/traffic_car.tscn` | Oncoming car (pooled; re-rolls its paint job on every spawn) |
| `scenes/road_chunk.tscn` | One pooled road segment, with roadside Marker2D slots |
| `scenes/gas_station.tscn` | Trip-goal gas station: refuel zone + hint (spawned by Main) |
| `scripts/main.gd` | Wires systems together via signals (the only coupling point) |
| `scripts/player/player_car.gd` | Input → lane switching → telemetry / crash signals |
| `scripts/components/movement_component.gd` | Reusable drivetrain (player and traffic) |
| `scripts/components/lane_switch_component.gd` | Discrete lane index + smooth glide between lanes |
| `scripts/components/sway_component.gd` | Cosmetic body bob/tilt |
| `scripts/components/node_pool.gd` | Generic scene-instance pool (leak-free) |
| `scripts/camera/follow_camera.gd` | Damped follow + speed-based look-ahead |
| `scripts/road/road_manager.gd` | Infinite road streaming (spawn/despawn via pool) |
| `scripts/road/road_chunk.gd` | Chunk data + decoration slots |
| `scripts/road/lane_set.gd` + `resources/lanes.tres` | Single source of truth for lane geometry |
| `scripts/road/gas_station.gd` | Station behavior: hint + refuel/passed intents |
| `scripts/traffic/traffic_manager.gd` | Spawns/recycles oncoming cars; keeps the road dodgeable |
| `scripts/traffic/traffic_car.gd` | One oncoming car: cruise left, spin wheels |
| `ui/hud.tscn`, `ui/hud.gd` | CanvasLayer HUD: speed, distance, fuel, money |
| `ui/game_over.tscn`, `ui/game_over.gd` | Game Over overlay (crash / out of fuel); emits a restart request |
| `ui/ui_format.gd` | Shared number formatting for HUD and Game Over |
| `autoload/game_manager.gd` | The one allowed singleton — run lifecycle, fuel, money, trip goal |
| `assets/sprites/` | Generated placeholder pixel art |
| `tools/generate_placeholder_art.py` | Regenerates all placeholder art (`python3 tools/generate_placeholder_art.py`) |

## Architecture

- Systems are independent; **all cross-system communication goes through
  signals**, connected in exactly one place (`scripts/main.gd`):
  crash/stall → `GameManager.end_run` → Game Over screen → restart, and
  station `refuel_requested` → `GameManager.try_refuel`. The player never
  references the TrafficManager; managers never reference the HUD.
- The fuel loop is two one-way signals: driving distance feeds
  `GameManager.report_distance` (burn), and `fuel_changed` feeds the car's
  engine `power_scale` back — low fuel gradually starves the engine instead
  of cutting it out (with a 0.5% dry cutoff so the car can't creep forever).
- The gas station is a dumb world object: it emits intents and knows nothing
  about money or fuel; `GameManager` owns the goal distance and the wallet,
  `Main` places each next station. No screens, no scene reloads mid-trip.
- The camera, road and traffic only know an abstract `Node2D` target/anchor,
  so any of them can be pointed at anything.
- Composition over inheritance: cars are assembled from `MovementComponent`,
  `LaneSwitchComponent` and `SwayComponent`; traffic reuses the player's
  drivetrain component unchanged.
- Lane geometry lives in one shared `LaneSet` resource (`resources/lanes.tres`),
  so the player, traffic and road art can never drift apart.
- `NodePool` recycles road chunks and traffic cars — endless driving allocates
  a fixed number of nodes, and pooled nodes stay parented to the tree, so
  nothing leaks.
- On a crash the whole tree pauses; the Game Over screen runs with
  `process_mode = ALWAYS` and asks `GameManager` to reload the scene.
- Tunables (speeds, damping, spawn distances, fairness gap, sway…) are
  `@export`ed, no magic numbers buried in logic.
- Scene note: exported node references require the `node_paths` attribute in
  `.tscn` node headers — hand-edited scenes must keep it in sync with the
  script's `@export var x: Node...` properties.

## Day 3 extension points (already in place)

- `RoadManager.chunk_spawned / chunk_despawned` — subscribe to decorate
  chunks with signs, props or events; `RoadChunk.roadside_slots`
  (Marker2D positions) + `chunk_index` give deterministic per-chunk content,
  and `clear_decorations()` keeps pooling clean.
- `GameManager.money` + `money_changed` — income (jobs, deliveries) only
  needs to write the property; the HUD already listens.
- Balance knobs live in `GameManager` consts: fuel burn, station spacing,
  refuel price, starting budget.
- `LaneSwitchComponent.lane_changed` — hook for lane-dependent systems
  (audio, score multipliers, AI reactions).
- `MovementComponent.power_scale` — already models engine starvation; also
  fits damage, weather or tuning effects for any vehicle.
