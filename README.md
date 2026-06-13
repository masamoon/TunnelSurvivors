# Diggy: Caverns of Chance

Diggy is a compact arcade mining survival game built in Godot 4. Dig through the cavern, collect gems and relics, survive pressure surges, then reach the extraction beacon before the den catches you.

## Controls

- Move: `WASD` or arrow keys
- Lance / pump: `Space`
- Interact with armed beacon: `E` or `Enter`
- Upgrade inventory: `I`
- Pause / settings: `Esc` or `P`
- Hub / rerun after a run: `Enter` for hub, `R` to rerun

On touch devices, use the on-screen directional pad, `LANCE` button, and pause button. Hub panels can be tapped to cycle unlocked setup options.

## Progression

Completed runs earn relic research from survival time, gems, kills, relic finds, and extraction. Research milestones add more relics to future upgrade rotations, while achievements can still unlock maps, loadouts, elements, and special relics early.

## Release Build

The Web export preset writes to `dist/web/index.html`. The GitHub Actions workflow in `.github/workflows/web-export.yml` validates that the project loads, exports the Web build, uploads it as an artifact, and deploys it to GitHub Pages.

Local Web export requires Godot Web export templates matching your installed Godot version.
