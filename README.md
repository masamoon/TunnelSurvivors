# Diggy: Caverns of Chance

Diggy is a compact arcade mining survival game built in Godot 4. Dig through the cavern, collect gems and relics, survive pressure surges, then reach the extraction beacon before the den catches you.

## Controls

- Move: `WASD` or arrow keys
- Lance / pump: `Space`
- Interact with armed beacon: `E` or `Enter`
- Upgrade inventory: `I`
- Guide / codex: `H`
- Pause / settings: `Esc` or `P`
- Hub / rerun after a run: `Enter` for hub, `R` to rerun

On touch devices, use the on-screen directional pad, `LANCE` button, and pause button. Hub panels can be tapped to cycle unlocked setup options.

## Progression

Completed runs earn relic research and runes from survival time, gems, kills, relic finds, and extraction. Research milestones add more relics to future upgrade rotations, while runes buy permanent hub upgrades that improve starts, research gain, and chest relic odds. Achievements can still unlock maps, loadouts, elements, and special relics early.

The boulder upgrade branch includes Boulder Lance, a shorter weaker lance that can create boulders where lance-killed enemies fall. Later ranks improve its boulder chance, and those ranks can appear in chests once unlocked. Your first boulder crush also unlocks the Stonecaller starting build, which begins runs with Boulder Lance.

The base lance branch uses standalone upgrades such as Anchor Chain, Snap Reel, Piston Head, Rupture Wave, and Beacon Coupler. These do not require elemental status setups to pay off.

The pause settings include master audio, music, SFX volume, music volume, screen shake, first-run hints, and a double-confirm wipe-save button.

Boss kills unlock the harder Obsidian Rift site, the Field Kit loadout, and the Treasure Compass beacon mod.

## Checks

Run `python3 tools/balance_check.py` to validate upgrade, research, and unlock table references.

## Release Build

The Web export preset writes to `dist/web/index.html`. The GitHub Actions workflow in `.github/workflows/web-export.yml` validates that the project loads, exports the Web build, uploads it as an artifact, and deploys it to GitHub Pages.

Local Web export requires Godot Web export templates matching your installed Godot version.
