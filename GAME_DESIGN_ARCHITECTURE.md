# Diggy Game Design and Architecture Summary

## Project Shape

Diggy: Caverns of Chance is a compact Godot 4.5 arcade mining survival game. The project is intentionally small:

- `project.godot` configures the Godot app, window scaling, GL compatibility rendering, icon, and `res://scenes/main.tscn` as the entry scene.
- `scenes/main.tscn` contains a single root `Node2D` named `Main` with `res://scripts/main.gd` attached.
- `scripts/main.gd` is the game. It owns simulation state, procedural generation, input, UI, rendering, save data, audio synthesis, progression, and balancing tables.
- `tools/balance_check.py` is a static sanity check for upgrade, research, achievement, map, and beacon-mod references.
- `.github/workflows/web-export.yml` validates the Godot project headlessly, exports the Web build, uploads the artifact, and deploys to GitHub Pages.

The architecture is therefore a single-script, custom-rendered Godot game rather than a node-heavy scene hierarchy. Most runtime entities are represented as dictionaries and arrays inside `main.gd`.

## Core Game Design

The game is a mining extraction loop inspired by arcade dig-and-chase games:

1. The player starts near the surface of a 22 by 34 cell cavern.
2. They dig tunnels through dirt, collect gems, super gems, treasure, cave keys, and buried relics.
3. Keys open optional locked vault rooms that preview reward type and danger.
4. Enemies spawn from existing tunnels, side breaches, newly carved dens, and vault alerts.
5. The player fights primarily with a directional lance that pins, pumps, damages, and can apply elemental or relic effects.
6. Runs escalate through depth tiers, enemy variety, pressure surges, boss milestones, and an endgame Reaper.
7. The extraction beacon arms when fully charged or when the run timer expires. The player must reach it and interact to win.
8. Completed or failed runs award long-term research and runes based on survival time, gems, kills, vaults, relics, and extraction.

The main design tension is extraction versus greed: digging creates routes and access to rewards, but keys and vaults ask whether a risky detour is worth the time, traps, enemy alerts, and possible route decay. The player is encouraged to use the cave layout itself as a weapon through choke points, boulders, lance lines, and upgrade synergies.

## Runtime State Model

`main.gd` keeps all state in script-level variables. The key groups are:

- Board state: `grid`, `dig_masks`, `tunnel_edges`, `tunnel_age`, `terrain_cells`, `crystal_cells`, and the soil `Image`/`ImageTexture`.
- Entity arrays: `rocks`, `gems`, `super_gems`, `treasure_chests`, `key_pickups`, `vault_rooms`, `xp_pickups`, `enemies`, and `run_relics`.
- Player/run state: position, facing, HP, level, XP, run timer, beacon charge, score, combo, depth tier, boss/reaper flags, and run statistics.
- Combat state: lance activity, attached enemy index, pump timing, hit cells, cooldowns, and temporary effects.
- Upgrade state: permanent run upgrades in `owned_upgrades`, temporary field/loadout upgrades in `temp_upgrades`, derived stat variables, and family tracking.
- Meta state: `meta`, selected map/loadout/beacon mod, settings, achievements, lifetime progress, research, and runes.
- UI/audio/feedback state: pause, guide/inventory flags, touch-control state, messages, screen shake, feedback arrays, and audio players.

The script uses numeric constants for tiles, enemy kinds, and game states:

- Tiles: dirt, tunnel, beacon, vault gate.
- Enemies: grub, burrower, Fygar, spitter, shieldbug, leech, brood pod, boss, Reaper.
- States: meta hub, playing, choosing upgrade, game over, win.

## Main Loop

`_ready()` loads meta progression, initializes audio, applies layout scaling, and starts in the meta hub.

`_process(delta)` is the central tick. It always updates timers, audio, feedback, camera, and visual interpolation, then branches by state:

- Meta hub: redraw only.
- Paused/result/upgrade-inventory states: release lance if needed, keep visuals/camera moving, redraw.
- Playing: update cooldowns and run timer, depth tier, pressure surge, boss spawning, lance, player motion, enemy spawning, enemies, rocks, treasure, XP pickups, tunnel regrowth, beacon scanner, and beacon arming.

`_unhandled_input(event)` handles keyboard, mouse, and touch. It supports desktop and mobile controls, meta hub setup cycling, pause/settings, guide pages, upgrade choice, inventory, restart/rerun, lance, and beacon interaction.

Rendering is entirely custom in `_draw()` and helper functions. The board, actors, effects, UI panels, modals, touch controls, guide, meta hub, pixel sprites, and synthesized-looking effects are drawn with Godot canvas calls.

## Board, Digging, and Terrain

The board is a fixed grid, but digging is more granular than one cell. Each cell has a 4 by 4 subcell mask:

- `dig_masks` tracks partial openings.
- `DIG_FULL_MASK` represents a fully open cell.
- The player's body path marks subcells as dug while moving.
- A dirt cell promotes into a scored/open tunnel after enough subcells are dug.
- `tunnel_edges` records directional connections between open cells.

The soil is backed by an `ImageTexture`. Digging clears rectangles/circles from that texture, which allows partial-dig visuals without adding many nodes.

Map generation starts with a full dirt board, carves the surface and player start, places the beacon near the bottom, carves patrol galleries, then places rocks, gems, super gems, crystal terrain, run relics, initial enemies, treasure chests, a deep treasure signal, locked vault rooms, and cave keys.

Vaults are sealed side rooms. Closed vault gates block movement and digging until the player spends a key through the interact action. Vault interiors stay dormant and hidden until opened, then connect to the tunnel network and trigger time, trap, or enemy-alert danger.

Maps are data-defined:

- Old Mine: baseline dirt, rocks, gems, and den pressure.
- Crystal Veins: crystal soil, harder shale/seals, richer gems, fewer rocks, more spitters/leeches.
- Obsidian Rift: harder pressure, more rocks/enemies, richer chest relic odds.

## Player and Combat

Movement is grid-directed with visual interpolation. Digging slows movement according to `move_delay`, `dig_delay_mult`, and terrain modifiers.

The lance is the primary weapon:

- `_start_lance()` traces forward along the facing direction, requiring an open line through the tunnel.
- If it finds an enemy, the lance attaches and pins it.
- `_update_lance()` handles hit delay, repeated pump timing, tap acceleration, release, and retract behavior.
- Pumping applies damage and control, then upgrade effects such as range, stun, pierce, rupture, beacon charge, and elemental statuses.

Elemental branches are mutually shaped by current element and unlock state:

- Ice freezes, chills, shatters, and enables brittle damage.
- Fire ignites, spreads, scorches, bursts, and can stun.
- Thunder shocks, chains, overloads, adds static fields, and cross-synergizes.
- Hybrid upgrades such as Steam Core, Storm Cell, and Glacier Rod depend on researched element combinations.

Boulder play is a separate branch. Boulder Lance can spawn boulders from lance kills, while gravity/snare/chute/ledger upgrades make falling rocks more reliable and rewarding.

## Enemies and Escalation

Enemies are dictionaries in the `enemies` array. Each stores position, visual position, kind, HP, speed, status timers, special attack timers, phasing state, bounty state, and boss fields.

Enemy selection is weighted by depth tier, run time, player level, and map bonuses:

- Grubs are the baseline.
- Burrowers, Fygars, spitters, shieldbugs, leeches, and brood pods join as time/level/depth thresholds are met.
- Bosses spawn at 120, 240, and 360 seconds.
- A Reaper spawns near the end of the eight-minute run and can force the beacon to arm.
- Late-run regular enemies can become "uber" variants with extra HP and speed.

Enemy updates process status effects first, then inflation/recovery, phasing, stuns, melee, ranged fire/spit, brood-pod summoning, boss summoning, ghosting, and movement.

Spawning tries several routes:

- Carve a new enemy den.
- Breach from adjacent dirt into the connected tunnel network.
- Spawn in a valid connected open tunnel.

Spawn scoring favors distance from the player, depth, spread from recent spawns/enemy clusters, and useful tunnel adjacency.

## Rocks, Treasure, and Rewards

Rocks can become loose and fall through open cells. Falling rocks can kill the player, crush enemies, damage bosses, and interact with boulder upgrades. Boulder snare can pull enemies into falling lanes. Crusher vaults intentionally provide boulder lanes and enemies so boulder combo kills remain a tempting optional score play.

Gems and super gems provide score, XP, and beacon charge. Super gems also feed lifetime achievement progress and can prime elemental lance damage.

Treasure chests spawn over time and can award gems, healing, or temporary field upgrades. Deep treasure is placed lower in the map and can be hinted by beacon mods.

XP drops as individual pickups that magnetize toward the player. Leveling opens an upgrade-choice modal, and choosing an upgrade applies run-long stat changes.

## Progression and Meta Hub

The game starts in `STATE_META`, a playable hub screen drawn by the same script. The player selects:

- Map
- Starting loadout
- Beacon mod
- Meta upgrade purchases

Meta save data lives at `user://diggy_meta.json`. `_default_meta()` defines the save schema and `_merge_meta()` migrates known keys from existing saves.

Long-term progression has three layers:

- Relic research: earned after each run and checked against milestone costs to unlock more relics.
- Runes: earned after runs and spent on meta upgrades.
- Achievements: unlock maps, loadouts, beacon mods, elemental research, and relics.

Meta upgrades currently include:

- Deep Pockets: starting beacon charge.
- Sturdy Frame: starting max hearts.
- Field Notes: extra relic research.
- Cache Sense: higher upgrade-chest odds.

Important achievements include first extraction, first boulder kill, first boss kill, 10 super gems, and 10 Fygar kills.

## Data Tables and Balance Touchpoints

Most content tuning is embedded in `main.gd`:

- Top-level constants control board size, timings, spawn caps, pressure surge behavior, HP, XP, score, run length, colors, and UI geometry.
- `_map_defs()` controls map identities and map modifiers.
- `_loadout_defs()` controls starting loadouts.
- `_beacon_mod_defs()` controls beacon modifiers.
- `_meta_upgrade_defs()` controls permanent upgrades and rune costs.
- `_achievement_defs()` controls unlock rewards.
- `_relic_research_milestones()` controls research unlock pacing.
- `_upgrade_pool()` defines relic/upgrades and display text.
- `_apply_upgrade()` and `_apply_temp_upgrade()` implement upgrade effects.
- `_choose_enemy_kind()`, enemy HP/speed helpers, spawn constants, and boss timing constants control combat pacing.

After editing progression or upgrade IDs, run:

```bash
python tools/balance_check.py
```

The checker verifies that referenced upgrade IDs exist, research costs are ordered, meta upgrade costs match max levels, and achievement map/mod constants resolve.

## Rendering and Audio

The game uses no external art assets beyond the icon. Visuals are custom pixel-style drawing in code:

- Soil texture generated from color rules and terrain.
- Board, tunnels, gems, enemies, rocks, player, effects, UI, hub, and modals drawn in `_draw_*` helpers.
- Pixel sprites are small row/palette patterns rendered through `_draw_pixel_sprite()`.

Audio is also generated in code:

- `_build_sfx_stream()` creates short WAV streams for UI, dig, lance, gems, enemy kills, boss cues, etc.
- `_build_music_loop_stream()` and `_build_ambience_loop_stream()` synthesize looping background audio.
- Settings control master audio, music toggle, SFX volume, and music volume.

## Platform and Layout

The project supports desktop and mobile/touch layouts:

- Desktop base: 960 by 640.
- Mobile portrait base: 640 by 960.
- `_should_show_touch_controls()` switches layout based on platform/touch/viewport.
- `_apply_content_scale()` changes the content scale size.
- Touch UI includes a d-pad, lance button, pause button, and tappable hub panels.

The Web export preset writes to `dist/web/index.html`, enables PWA output, and uses the theme color/description from the export preset.

## Maintenance Notes

This codebase optimizes for compactness and iteration speed over modular separation. The tradeoff is that changes often require touching multiple nearby systems in `main.gd`. When adding content, check all of these paths:

- Display definition in the relevant `*_defs()` or `_upgrade_pool()` function.
- Unlock/discovery logic if it should be gated.
- Availability logic if it should appear only at certain run conditions.
- Application logic in `_apply_upgrade()` and `_apply_temp_upgrade()`.
- Effective-stat helper if permanent and temporary versions should stack.
- Rendering/UI text if the player needs feedback.
- `tools/balance_check.py` if introducing a new table reference category.

For larger future work, the most natural extraction points would be data tables, save/meta progression, procedural generation, enemy behavior, and rendering helpers. Until then, the strongest convention is to keep changes local, preserve the dictionary-based state model, and update the balance checker when new content references become possible.
