# Roadmap

## Shipped

**Day 1 — driving feel.** `MovementComponent` drivetrain, endless road
streaming (`RoadManager` + `NodePool` + `RoadChunk`), parallax background,
`FollowCamera` with speed-based look-ahead. Originally included
lane-switching, oncoming traffic, and crash-on-collision — all since
removed (see Pivot, below, and `13_DECISIONS.md`).

**Day 2 — fuel & economy.** Fuel drain tied to distance, low-fuel engine
starvation, dry-tank stall; money; gas stations as the trip goal with a
fixed-price refuel; HUD (speed/distance/fuel/money); Game Over screen with
restart.

**Pivot (same repository, after Day 2).** Removed lane-switching,
`TrafficManager`, the traffic car scene/sprites, `lanes.tres`, and
crash-on-collision entirely. The car now cruises on its own down a calm
highway with nothing to dodge; fuel/money pressure is the only mechanic.
Widened the viewport for the calmer framing and regenerated placeholder art
without the traffic paint-job variants. In the course of this change, a
collision-layer regression was caught and fixed before it shipped — the
removed crash `Hitbox` had doubled as the only thing on layer 1, which the
gas station's trigger depends on to detect the player at all; replaced with
a dedicated `PresenceArea`.

## Extension points already in place (not yet used)

These exist in the current architecture specifically so the next features
don't require refactoring:

- **Roadside content:** `RoadManager.chunk_spawned` / `chunk_despawned` +
  `RoadChunk.roadside_slots` (Marker2D positions) + `chunk_index` give
  deterministic per-chunk content (signs, props, scripted events) without
  any change to `RoadManager` itself.
- **Income:** `GameManager.money` + `money_changed` already support
  arbitrary writes and already push to the HUD — a job/delivery system only
  needs to write the property.
- **Balance tuning:** fuel burn rate, station spacing, refuel price, and
  starting budget are all `GameManager` consts, not buried in logic.
- **Engine starvation as a general effect:** `MovementComponent.power_scale`
  already models gradual power loss from fuel; the same mechanism could
  drive damage, weather, or tuning effects for any vehicle without new code.

## Explicitly out of scope right now

An earlier documentation scaffold assumed a much larger game — NPCs,
cities, regions, items, story chains, a save system. **None of that has
been designed or built**, and nothing in the current codebase assumes it
will be. Before any of it becomes a roadmap item it needs an actual design
pass; until then it stays out of this Bible so the docs don't drift ahead
of the implementation.

Also not planned, with no supporting code today: multiplayer, mobile input,
controller support, save/load persistence.
