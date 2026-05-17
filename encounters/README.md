# Encounters

Encounter `.tres` + matching `.tscn` pairs that compose enemy instances into a single fight. Consumed by `custom_resources/battle_stats_pool.gd` and selected by `scenes/map/map_generator.gd:_tier_for(role)`. The runtime resource class is still `BattleStats` — only the directory was renamed for clarity.

## Tier ↔ act mapping

| Act | Early (regular) | Late (regular) | Boss |
|---|---|---|---|
| 1 | tier 0 | tier 1 | tier 2 |
| 2 | tier 3 | tier 3 | tier 5 |
| 3 | tier 6 | tier 6 | tier 8 |

- **Tier 4 is intentionally skipped** — reserved by `_tier_for()` for future "late"-only Act 2 content.
- **Tier 5 currently holds only `tier_5_toxic_ghost`** (Act 2 boss). Add alternates here when designing Act 2 boss variety.
- **Tier 2 has 3 encounters** vs Tier 1's 9 — fill in as you author Act 1 late-game content.
- **Acts 3+ have no encounters yet** — tier 6 / 8 are placeholders; the map currently won't populate Act 3 with combat rooms.

## Naming convention
`tier_<n>_<short_name>.tres` for regular encounters. Elite encounters live under `elite/` and are pulled via `battle_stats_pool.elite_pool`, independent of tier.
