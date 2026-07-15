# Drive Car — Day 1 Prototype

Pixel-art side-view driving prototype (inspired by *Keep Driving*), built with
**Godot 4.4**, GDScript only. Day 1 scope: movement + presentation. No fuel
consumption, traffic, collisions, events or NPCs.

## How to run

1. Open Godot 4.4, click **Import**, and select this folder's `project.godot`.
2. Press **F5** (Play). The main scene is already configured — it runs immediately.
3. Controls: **W / ↑** accelerate · **S / ↓** brake.

## Project layout

| Path | Purpose |
|---|---|
| `scenes/main.tscn` | Composition root: parallax, road, player, camera, HUD |
| `scenes/player_car.tscn` | Player car (sprites + movement + sway components) |
| `scenes/road_chunk.tscn` | One pooled road segment, with roadside Marker2D slots |
| `scripts/main.gd` | Wires systems together via signals (the only coupling point) |
| `scripts/player/player_car.gd` | Input → movement → telemetry signals |
| `scripts/components/movement_component.gd` | Reusable drivetrain (speed simulation) |
| `scripts/components/sway_component.gd` | Cosmetic body bob/tilt |
| `scripts/components/node_pool.gd` | Generic scene-instance pool (leak-free) |
| `scripts/camera/follow_camera.gd` | Damped follow + speed-based look-ahead |
| `scripts/road/road_manager.gd` | Infinite road streaming (spawn/despawn via pool) |
| `scripts/road/road_chunk.gd` | Chunk data + decoration slots |
| `ui/hud.tscn`, `ui/hud.gd` | CanvasLayer HUD: speed, distance, fuel placeholder |
| `autoload/game_manager.gd` | The one allowed singleton — fuel placeholder + signals |
| `assets/sprites/` | Generated placeholder pixel art |
| `tools/generate_placeholder_art.py` | Regenerates all placeholder art (`python3 tools/generate_placeholder_art.py`) |

## Architecture rules (enforced by structure)

- Systems are independent; **all cross-system communication goes through
  signals**, connected in exactly one place (`scripts/main.gd`).
- The player never references the RoadManager; the RoadManager never
  references the HUD. The camera and road only know an abstract `Node2D`
  target/anchor.
- Composition over inheritance: the car is assembled from `MovementComponent`
  and `SwayComponent`; both are reusable by Day 2 traffic vehicles.
- `NodePool` recycles road chunks — endless driving allocates a fixed number
  of nodes, and pooled nodes stay parented to the tree, so nothing leaks.
- Tunables (speeds, damping, spawn distances, sway…) are `@export`ed, no
  magic numbers buried in logic.

## Day 2 extension points (already in place)

- `RoadManager.chunk_spawned / chunk_despawned` — subscribe to decorate
  chunks with gas stations, signs, or traffic spawn points.
- `RoadChunk.roadside_slots` (Marker2D positions) + `chunk_index` for
  deterministic per-chunk content; `clear_decorations()` keeps pooling clean.
- `GameManager.fuel` + `fuel_changed` — the HUD already listens; fuel
  consumption only needs to write the property.
- `MovementComponent.set_throttle()` — feed it from an AI controller instead
  of input to get traffic cars for free.
