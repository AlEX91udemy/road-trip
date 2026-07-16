# Road Trip — Day 1

Pixel-art side-view driving game (inspired by *Keep Driving*), built with
**Godot 4.4**, GDScript only.

Day 1 gameplay: the car accelerates on its own down an endless three-lane
highway; the player switches lanes to dodge oncoming traffic. One collision
ends the run on a Game Over screen showing the distance driven, and the run
can be restarted instantly.

## How to run

1. Open Godot 4.4, click **Import**, and select this folder's `project.godot`.
2. Press **F5** (Play). The main scene is already configured — it runs immediately.
3. Controls:
   - **W / ↑** — move one lane up
   - **S / ↓** — move one lane down
   - **R / Enter** — restart (on the Game Over screen)

## Project layout

| Path | Purpose |
|---|---|
| `scenes/main.tscn` | Composition root: parallax, road, traffic, player, camera, UI |
| `scenes/player_car.tscn` | Player car (sprites + movement/lane-switch/sway components) |
| `scenes/traffic_car.tscn` | Oncoming car (pooled; re-rolls its paint job on every spawn) |
| `scenes/road_chunk.tscn` | One pooled road segment, with roadside Marker2D slots |
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
| `scripts/traffic/traffic_manager.gd` | Spawns/recycles oncoming cars; keeps the road dodgeable |
| `scripts/traffic/traffic_car.gd` | One oncoming car: cruise left, spin wheels |
| `ui/hud.tscn`, `ui/hud.gd` | CanvasLayer HUD: speed, distance, fuel placeholder |
| `ui/game_over.tscn`, `ui/game_over.gd` | Game Over overlay; emits a restart request |
| `ui/ui_format.gd` | Shared number formatting for HUD and Game Over |
| `autoload/game_manager.gd` | The one allowed singleton — run lifecycle + fuel placeholder |
| `assets/sprites/` | Generated placeholder pixel art |
| `tools/generate_placeholder_art.py` | Regenerates all placeholder art (`python3 tools/generate_placeholder_art.py`) |

## Architecture

- Systems are independent; **all cross-system communication goes through
  signals**, connected in exactly one place (`scripts/main.gd`):
  crash → `GameManager.end_run` → Game Over screen → restart. The player
  never references the TrafficManager; managers never reference the HUD.
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

## Day 2 extension points (already in place)

- `RoadManager.chunk_spawned / chunk_despawned` — subscribe to decorate
  chunks with gas stations, signs, or props; `RoadChunk.roadside_slots`
  (Marker2D positions) + `chunk_index` give deterministic per-chunk content,
  and `clear_decorations()` keeps pooling clean.
- `GameManager.fuel` + `fuel_changed` — the HUD already listens; fuel
  consumption only needs to write the property.
- `LaneSwitchComponent.lane_changed` — hook for lane-dependent systems
  (audio, score multipliers, AI reactions).
- `MovementComponent.set_throttle()` — already drives traffic; any future
  vehicle AI gets the same drivetrain for free.
