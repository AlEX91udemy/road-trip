# Vision

## High concept

A pixel-art, side-view driving game where the car drives itself and the
player's only real decisions are economic: when to stop, and whether you can
afford to. Tonal reference: *Keep Driving* (2023) — a calm highway, no
reflex challenge, tension that comes from resource pressure rather than
obstacles.

## Core fantasy

You're not dodging anything. You're watching two numbers — fuel and money —
tick down while the world slides by, and deciding whether the gas station
ahead is worth the stop. The game is a slow-burn budget puzzle wearing a
road-trip skin.

## Pillars

1. **Hands-off driving.** The throttle is always open (`PlayerCar` sets it to
   `1.0` every frame — see `scripts/player/player_car.gd`); the player never
   steers or brakes. All agency is economic, not reflexive.
2. **Two depleting resources, one inevitable end.** Fuel forces station
   visits (`GameManager.report_distance` burns fuel with distance); money
   makes each visit cost something real (`REFUEL_COST`); there is no income
   anywhere in the current build, so every run is finite by construction.
3. **Small, composable systems wired through signals.** No gameplay system
   holds a hard reference to another — `scripts/main.gd` is the single place
   that wires them together. This keeps any one system swappable without
   touching the rest (see `11_TECHNICAL_ARCHITECTURE.md`).

## Explicit non-goals (current scope)

- **Not an arcade dodge game.** Lane-switching, oncoming traffic, and
  crash-on-collision existed in the Day 1 build and were deliberately removed
  — see `13_DECISIONS.md`. The only way a run currently ends is running out
  of fuel.
- **Not (yet) an open-world / RPG.** An earlier documentation scaffold
  assumed NPCs, cities, regions, items, story chains and a save system. None
  of that has been designed or built. This Bible describes what exists, not
  that ambition — see `12_ROADMAP.md` for what's actually planned next.

## Reference

*Keep Driving* (YCJY Games, 2023) — tonal and structural inspiration for the
self-driving-car, resource-pressure loop. Not a 1:1 clone target; the scope
here is intentionally much smaller.
