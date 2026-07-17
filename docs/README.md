# Road Trip Bible

Design and technical reference for the current build, kept in sync with the
actual implementation — not a wishlist. If a doc and the code disagree,
the code is right; file a fix.

| Doc | Covers |
|---|---|
| [00_VISION.md](00_VISION.md) | High concept, core fantasy, design pillars, explicit non-goals |
| [01_GAME_DESIGN_DOCUMENT.md](01_GAME_DESIGN_DOCUMENT.md) | Overview, controls, win/lose, UI, art style, scope |
| [02_GAME_LOOP.md](02_GAME_LOOP.md) | Moment-to-moment loop, signal wiring, step by step |
| [03_CORE_MECHANICS.md](03_CORE_MECHANICS.md) | Drivetrain, fuel, money, gas stations, collision, telemetry |
| [11_TECHNICAL_ARCHITECTURE.md](11_TECHNICAL_ARCHITECTURE.md) | Engine setup, composition root, autoload, pooling, gotchas |
| [12_ROADMAP.md](12_ROADMAP.md) | Shipped, in-place extension points, explicitly out of scope |
| [13_DECISIONS.md](13_DECISIONS.md) | Architecture-decision log, one entry per notable call |

v1.0 — replaces an earlier 21-file scaffold that assumed a much larger scope
(NPCs, cities, regions, items, story, saves) than what's built. See
`13_DECISIONS.md` for why.
