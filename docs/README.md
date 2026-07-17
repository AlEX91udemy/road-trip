# Road Trip Bible

Two kinds of document live here. `00_VISION.md` and `06_ART_DIRECTION.md`
are design intent — where the project is headed, deliberately bigger than
what's built today. Everything else (`01`–`03`, `11`–`13`) is kept in sync
with the actual implementation: if one of those and the code disagree, the
code is right; file a fix. Vision/Art Direction don't work that way — they
describe the target, not a snapshot of the build.

| Doc | Covers |
|---|---|
| [00_VISION.md](00_VISION.md) | High concept, core fantasy, design pillars — aspirational |
| [01_GAME_DESIGN_DOCUMENT.md](01_GAME_DESIGN_DOCUMENT.md) | Overview, controls, win/lose, UI, art style, scope |
| [02_GAME_LOOP.md](02_GAME_LOOP.md) | Moment-to-moment loop, signal wiring, step by step |
| [03_CORE_MECHANICS.md](03_CORE_MECHANICS.md) | Drivetrain, fuel, money, gas stations, collision, telemetry |
| [06_ART_DIRECTION.md](06_ART_DIRECTION.md) | Visual reference, palette, lighting, layers, camera — aspirational |
| [11_TECHNICAL_ARCHITECTURE.md](11_TECHNICAL_ARCHITECTURE.md) | Engine setup, composition root, autoload, pooling, gotchas |
| [12_ROADMAP.md](12_ROADMAP.md) | Shipped, in-place extension points, explicitly out of scope |
| [13_DECISIONS.md](13_DECISIONS.md) | Architecture-decision log, one entry per notable call |

v1.0 — replaces an earlier 21-file scaffold that assumed a much larger scope
(NPCs, cities, regions, items, story, saves) than what's built. See
`13_DECISIONS.md` for why.
