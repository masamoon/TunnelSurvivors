# Diggy: Caverns of Chance

Diggy is a compact arcade mining extraction game built in Godot 4. Dig through the cavern, collect gems and relics, find cave keys, decide which locked vaults are worth the risk, then reach the extraction beacon before the den catches you.

## Controls

- Move: `WASD` or arrow keys
- Lance / pump: hold `Space`, release to disengage
- Interact with armed beacon / vault gate: `E` or `Enter`
- Upgrade inventory: `I`
- Guide / codex: `H`
- Pause / settings: `Esc` or `P`
- Hub / rerun after a run: `Enter` for hub, `R` to rerun

When multiple movement keys are held, the most recently pressed direction wins; releasing it restores the previous held direction. Pumping can be changed to toggle mode in pause settings, where impact hit-stop can also be reduced or disabled.

On touch devices, use the on-screen directional pad, `LANCE` button, contextual `KEY` / `BEACON` interaction button, and pause button. Combat and interaction remain separate, so standing beside a gate never consumes an attack. Hub panels can be tapped to cycle unlocked setup options.

## Keys and Vaults

Runs now include cave keys and optional locked side rooms. Vault gates preview their reward type and danger: cache, tool, relic, and crusher vaults each ask whether the loot, route risk, trap setup, or boulder combo opportunity is worth delaying extraction. Keys are never required to extract, so spending time on vaults is a greed decision rather than a soft-lock.

## Progression

Every run opens with a choice between Ice, Fire, Thunder, and Boulder Lance. This starter plan lasts for that run and immediately enables its matching follow-up relics, so a fresh profile gets a mechanic-changing decision before its first extraction.

Level-up cards show numerical before/after effects and how each relic compounds the current build. Full Heart only appears when healing would restore missing health. Run relics reset on rerun; research milestones permanently add relics to future rotations, while runes buy hub upgrades and alternate starts. Achievements can also unlock maps, loadouts, elements, and special relics early.

Relics from the field, chests, and starting loadouts contribute to the same family bonuses as drafted relics. Each relic counts once; an already-owned field relic becomes another available relic, or a gem cache when the pool is exhausted. Field Dressing always adds its advertised heart, including in the Field Kit loadout. Prospector reveals one super gem near explored tunnels immediately, so its reward can be collected during the current cavern.

Restarting or returning to the hub abandons the current run and awards no research or runes. A short defeat remains eligible once the player has meaningfully participated by digging, collecting, opening a vault, or landing a successful pump.

The boulder upgrade branch includes Boulder Lance, a shorter weaker lance that can create boulders where lance-killed enemies fall. Later ranks improve its boulder chance, and those ranks can appear in chests once unlocked. Your first boulder crush also unlocks the Stonecaller starting build, which begins runs with Boulder Lance.

Each cave now stages a mirrored rock ambush, a flankable loop, and a guarded gem vein alongside the optional crusher vault. Generic generation preserves their approach, reward, and escape cells. Only boulders released by player digging or an explicit player tool advance Rock Plan progress; incidental cave-ins still defeat enemies and drop XP.

Prepared tunnels move at 3.2 cells per second while fresh digging moves at 2.5; basic pursuit keeps an independent 2.0 cells-per-second baseline. Pump beats escalate through lock, pressure, and critical states with optional capped hit-stop. Boulder damage resolves when the sprite reaches the impact cell, with falling acceleration, landing dust, weighted audio, and combat-cause traces for tuning.

The base lance branch uses standalone upgrades such as Anchor Chain, Snap Reel, Piston Head, Rupture Wave, and Beacon Coupler. These do not require elemental status setups to pay off.

The pause settings include master audio, music, SFX volume, music volume, screen shake, pump input mode, first-run hints, and a double-confirm wipe-save button.

Boss kills unlock the harder Obsidian Rift site, the Field Kit alternate start, and the Treasure Compass beacon mod. End-of-run results identify the cause, best tactical moment, run build, and next permanent unlock, with direct rerun and hub actions.

## Checks

Run `python3 tools/balance_check.py` to validate upgrade, research, and unlock table references.

Run `godot --headless --path . --script res://tests/run_regressions.gd` to check controls, encounter connectivity, movement and impact contracts, starter plans, useful healing, build-aware drafts, result summaries, and boulder-kill attribution.

## Release Build

The Web export preset writes to `dist/web/index.html`. The GitHub Actions workflow in `.github/workflows/web-export.yml` validates that the project loads, exports the Web build, uploads it as an artifact, and deploys it to GitHub Pages.

Local Web export requires Godot Web export templates matching your installed Godot version.
