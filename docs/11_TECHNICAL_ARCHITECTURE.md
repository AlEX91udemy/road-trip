# Technical Architecture

## Stack

Godot 4.4, GDScript only (`config/features = ["4.4", "GL Compatibility"]`).
`renderer/rendering_method = "gl_compatibility"` for both desktop and mobile
targets — chosen for broad hardware and headless-CI compatibility, not for
any visual feature.

## Composition root

`scripts/main.gd` is the **only** place any two gameplay systems learn about
each other, and always through signals — never a direct method call across
systems. The full wiring table lives in `02_GAME_LOOP.md`. This means any
single system (camera, road, HUD, gas station) can be swapped by re-wiring
only `main.gd` / `main.tscn`.

## The one autoload

`GameManager` (`autoload/game_manager.gd`) is the only allowed singleton. It
owns run lifecycle and run resources (fuel, money, trip-goal distance) and
exposes all of it through signals (`fuel_changed`, `money_changed`,
`run_ended`) or setters that broadcast on change — no other system holds a
reference to it beyond what `Main` wires up.

## Composition over inheritance

`PlayerCar` is assembled from small, reusable `Node` components rather than
a deep class hierarchy:

- `MovementComponent` — scalar drivetrain (throttle → speed), knows nothing
  about input, sprites, or the scene tree.
- `SwayComponent` — cosmetic body bob/tilt, driven by a speed signal.

**Gotcha:** hand-edited `.tscn` files require a `node_paths=PackedStringArray(...)`
attribute on the node header listing every `@export var x: Node...` the
script declares — Godot does not infer this from the exported var itself.
Missing it makes the reference silently `null` at runtime with no error.
This has been the source of at least one real bug in this project (see
`13_DECISIONS.md`).

## Decoupled targets, not decoupled classes

`FollowCamera` and `RoadManager` never reference `PlayerCar` by type — they
take a generic `Node2D` (`target` / `view_anchor`) and derive whatever they
need (e.g. `FollowCamera` estimates velocity from position deltas itself,
rather than being told). Either could be pointed at any Node2D — a cutscene
dolly, a different vehicle — without modification.

## Object pooling

`NodePool` (`scripts/components/node_pool.gd`) is a generic instance pool:
`acquire()`/`release()`, prewarmed on `_ready()`. Released nodes are
re-parented *under the pool itself* (hidden, `PROCESS_MODE_DISABLED`)
instead of being freed or left floating, so nothing can leak. Currently used
by `RoadManager` for road chunks; it previously also pooled traffic cars,
before that system was removed (`13_DECISIONS.md`).

## Endless road streaming

`RoadManager` watches a `view_anchor` (the active camera) and:
- spawns chunks ahead within `spawn_ahead` (1000 px),
- recycles chunks that fall more than `keep_behind` (600 px) behind it.

It emits `chunk_spawned` / `chunk_despawned` and each `RoadChunk` exposes
`roadside_slots` (Marker2D positions) + a monotonic `chunk_index` —
infrastructure already in place for future roadside content (signs, props,
events) without changing `RoadManager` itself. See `12_ROADMAP.md`.

## Collision layers

- **Layer 1** = player presence. The player's `PresenceArea` (`collision_layer
  = 1`, no mask) is the only thing on this layer.
- The gas station's `Trigger` (`collision_mask = 1`, `monitorable = false`)
  is the sole listener — it only needs to *detect* the player, never be
  detected itself.
- `Main` connects the station's `passed` signal with `CONNECT_DEFERRED`
  because it's emitted from inside a physics `area_exited` callback, and
  Godot forbids freeing/spawning Area2D-bearing nodes while the physics
  server is mid-flush.

## Pause-based game over

`GameManager.end_run()` sets `get_tree().paused = true`, freezing every
gameplay node mid-frame in one call. `GameOverScreen`'s `CanvasLayer` runs
with `process_mode = ALWAYS` so it keeps receiving input while paused.
`restart_run()` unpauses, then calls `get_tree().reload_current_scene()` —
restart is a full reload, not an in-place reset.

## UI decoupling

`Hud` and `GameOverScreen` are pure presentation: dumb `display_*()` /
`open()` methods that take ready-to-show values. Neither pulls state itself
— `Main` pushes values in via signals — so either can be restyled or
replaced without touching gameplay code. `UiFormat` (static, stateless)
centralizes number→string formatting so the two screens can't drift apart
on how a distance or a dollar amount is displayed.

## Placeholder art pipeline

`tools/generate_placeholder_art.py` procedurally generates every current
sprite (car body/wheel, gas station, parallax layers, road surface) as flat
pixel-art PNGs. Regenerate with `python3 tools/generate_placeholder_art.py`.
No hand-authored art exists yet in this project.

## Known project gotchas

- **`node_paths` sync** — see Composition over inheritance above.
- **`CONNECT_DEFERRED` for physics-callback signal handlers** that mutate
  the tree (e.g. `queue_free`/`add_child` on Area2D-bearing nodes) — see
  Collision layers above.
- **Headless testing:** the Godot headless binary is not part of this repo;
  it's downloaded to a session scratchpad when needed. There is no system
  `pip`/`gdlint` available in this environment — static checks run via
  `godot --headless --check-only --script`, which does **not** see
  autoloads or `class_name` globals (a script referencing `GameManager`
  fails to compile under `--check-only` even though it works at real
  runtime) — verify those paths by actually running the game
  (`godot --headless res://scenes/main.tscn --quit-after N`) instead.
- External `-s` SceneTree scripts likewise can't see `class_name`/autoload
  identifiers — look nodes up by `get_node()` path or `script.get_global_name()`
  rather than by type.
