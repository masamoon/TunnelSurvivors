# Adversarial mechanics review: earn the next run

Reviewed baseline: `e2e75d7c1de2c055c86277d6aaca68c53f3f14b7` (merged PRs #1–#5).

## Verdict

Diggy has a compelling premise: prepare terrain, commit to a dangerous pump, turn pursuit into a rock kill, and decide whether another reward is worth delaying extraction. The combined baseline does not reliably deliver those decisions yet. Several systems pay the player for the wrong behavior or fail to pay for the advertised behavior.

Repair those contracts before expanding the run structure. Keep the single-cavern baseline for comparison. These findings combine source inspection and deterministic Godot probes; they are not evidence of human enjoyment, retention, or a measured dominant strategy across complete runs.

## Findings and proposed changes

| Priority | Adversarial question / evidence | Consequence | Action |
| --- | --- | --- | --- |
| P1 | Why reposition if the threat can be held indefinitely? `_pin_lance_target` pins the Reaper despite its zero-damage immunity. Frontal Shieldbugs also accept harmless locks. Only boss variant 0 breaks its lance, and its recovery permits immediate re-hooking before the counterattack. | The correct-looking survival tactic disables the enemies intended to challenge it. Flanking, escape routes, and rock preparations lose value. | **Combat PR:** reject invalid locks before mutating enemy control state; let every boss retaliate after a bounded pump commitment and briefly resist reattachment. Keep rocks and ordinary enemies useful. |
| P1 | Why seek a field relic if it silently loses set credit? `_apply_temp_upgrade` does not call `_register_family_upgrade`, while availability prevents the same relic from appearing again. | Exploration can permanently prevent a six-piece elemental set in the current run. A reward can make the advertised build goal unreachable. | **Reward PR:** count unique relics from every source once; resolve stale duplicate pickups instead of double-applying them. |
| P1 | Why choose Field Kit or Prospector? Found Field Dressing only heals a full-health start; Prospector's extra-super-gem stat is consumed by initial map generation, before the in-run choice. | A permanent unlock or level-up spends a choice without delivering its promised benefit. This damages trust in experimenting with different builds. | **Reward PR:** give Field Dressing its advertised maximum-heart increase and make Prospector create a collectible opportunity in this cavern. Do not grant the gem's XP or charge without collecting it. |
| P1 | Will a planned encounter still exist when I arrive? `_update_tunnel_regrowth` starts closing old cells after 34 seconds and ignores encounter reservations. A distant-player probe on seed 1201 disconnected all three authored approach/reward/escape routes by 45 seconds. | The room grammar can become debris before the player reads it. Initial-generation connectivity tests cannot establish playable encounters. | **Encounter PR:** protect unvisited authored open cells from regrowth, activate permanently on approach, reset their age once, then restore ordinary regrowth. No dormant enemies or permanent safe rooms. |
| P2 | Does Boulder Lance establish an early play style? It immediately reduces range from 3 to 2, but rank I generates a rock on only 20% of otherwise eligible kills. | Even before placement failures, five independent rolls have a 32.8% probability of producing no rock. The starter can feel like a penalty rather than an intentional terrain tool. | Next experiment: deterministic rock readiness, with an early guaranteed demonstration and a visible subsequent kill counter. Compare against the current chance before adjusting damage or adding another button. |
| P2 | Why hold the pump if rapidly releasing and re-hooking deals damage faster? First-hit delay is 0.10s and ordinary recovery is 0.24s, versus a 0.62s held pump interval. | Ignoring frame quantization and hit-stop, three base hits take 0.78s with perfect re-hooks versus 1.34s held. Input churn is rewarded over the advertised commitment mechanic. | Test a shared earliest-next-pump time across releases while keeping movement disengagement immediate. Check hold and toggle modes; do not make escaping feel delayed. |
| P2 | Am I making new route decisions on run five? `_place_cave_encounters` always uses rock ambush → flank loop → guarded vein in fixed depth bands. `_new_run` builds at tier 1, so the guarded vein's higher-tier enemy selection is not exercised in ordinary starts. | Position jitter and mirroring change coordinates more than the problem being solved. This is a replay hypothesis, not a measured boredom result. | After the preserved rooms work, add one meaningful alternate deep-room topology or guard behavior. Keep the first teaching encounter stable. Test route changes before adding more maps. |
| P2 | Can I finish the build the cards promise? The gem family has four unique relics, while `_register_family_upgrade` advertises bonuses at 3, 5, and 6. | Its 5/6 thresholds are unreachable through legitimate unique picks. Similar generic set copy can mislead smaller families. | Audit family-specific attainable thresholds and preview the next real bonus. Prefer reachable milestones to filler relics invented to fill a quota. |
| P2 | Is dying quickly a better progression strategy? Eligible defeats start at one research plus every Field Notes rank; one scored dig qualifies. The research formula has no minimum duration, unlike runes. | Short intentional losses can optimize research per minute. This is an incentive in the formula; actual suicide-cycle efficiency still needs a route test. | Compare research per minute for short losses and competent extracts. Consider tying Field Notes' multiplier/bonus to earned objectives rather than a flat payout on every eligible death. Preserve useful progress for honest early losses. |
| P2 | What do I risk after the beacon arms? Defeat preserves earned research and runes; extraction adds only fixed bonuses (+3 research, +2 runes), while several earnings categories cap. | The emotional cost of greed can be weak, and further rewards can stop changing the result. The formulas establish the stakes; player risk preference remains unmeasured. | Test explicit banking of exploration rune rewards on extraction while preserving research on defeat. Show the exact carried/secured difference before changing penalties. Do not add another currency. |

Baseline function names above are stable review anchors; line numbers move with the fixes.

The encounter probe used four seeded caves (1200–1203), a stationary surface player, and isolated regrowth. At 30 seconds all 12 approach-to-escape paths survived; at 45 seconds none did; at 90 seconds only 44 of 256 authored open cells remained. A separate enemies-and-rocks probe found that ambient cave-ins can also remove guardians. These controlled probes establish lifecycle failures, not the frequency with which a human reaches each room too late.

## Interactions that still need attention

- Restoring field set credit makes exploration stronger. Reassess extraction timing and three-piece bonus timing before increasing XP or spawn pressure. The fix should not be followed immediately by a speculative compensating nerf.
- Making bosses retaliate can expose the weakness of a short-range Boulder start. Validate that its escape route and terrain burst remain practical; greater danger by itself does not mean a better fight.
- Protecting unvisited rooms from regrowth alone does not preserve them against cave-ins. Initial ambient rock placement must also respect the reservation beneath a rock, as runtime rock spawning already does. The encounter proposal covers that initial-placement case; player actions and active cave physics can still change a room, so do not claim an absolute encounter guarantee.
- Enemy staging filters ordinary spawns to whichever special families remain alive. Leaving one special enemy alive can suppress the introduction of others. Test whether this is useful readable pacing or a repeatable way to avoid more threatening families before relaxing the rule.
- All ordinary kills, including environmental cave-ins, can feed beacon charge through `_drop_xp`. A repaired room and improved set rewards should make deliberate play visibly better than incidental cave activity; measure charge sources before changing values.
- Elemental damage and area kills remove enemies from an index-based array used by the attached lance. Review target identity under secondary kills separately; a disappearing lower index must not silently change the attached target.
- Rock crush reach extends ahead of the sprite and can damage a surviving boss on successive fall steps. Keep this distinct from the already-tested impact-cell timing; decide whether it is an intentional shockwave or needs one-hit-per-rock tracking and a clearer telegraph.

## Small playtest before more systems

Use a fresh profile first, then repeat promising runs with a progressed profile. Record the exact revision and selected map/loadout/starter. For seeded harness comparisons seed both the game's RNG and global RNG: `Array.shuffle()` is also used, so setting only `game.rng.seed` is insufficient.

Run three attempts with each of the four starters on Old Mine. Counterbalance their order if more than one player is available. This is a small diagnostic sample, not a retention study. Record:

| Observation | What it tests |
| --- | --- |
| Time to first deliberate rock setup, successful flank, and three-piece bonus | Whether the defining mechanics arrive early enough to shape the run |
| Room approach time and whether reward/escape routes remain readable | Whether encounter preservation changes actual decisions |
| Pump releases caused by an incoming threat; boss counters dodged versus tanked | Whether movement and commitment are meaningful |
| Beacon arming time and charge sources: pickup, deliberate kill, incidental cave-in | Whether the objective rewards engagement |
| Choice and outcome of the first optional detour after beacon arming | Whether extraction versus greed exists as an understandable choice |
| Why the player starts another run, and what they intend to do differently | Whether replay motivation comes from a new plan rather than only a progress bar |

Save short clips of successful and failed setups. The useful question after a loss is “what would you do differently?” If the answer is merely “more permanent hearts,” improve readable counterplay before adding progression.

## When to try extract-or-descend

Proceed only when ordinary runs demonstrate intentional terrain kills, readable boss escapes, working build payoffs, and a real optional-detour decision. These are qualitative gates to verify, not claims already established by regression tests.

Then test a **two-cavern** branch against the repaired single-cavern game:

1. Offer extract or descend at the armed beacon and show the concrete next-cavern reward and threat.
2. Carry the build forward so descending lets the player use what they assembled. State the health carryover rule explicitly and hold it constant during the comparison.
3. Change the next cavern's tactical problem, not just enemy health. Do not introduce another research layer or currency.
4. Compare at similar total session length. More minutes played because the run became longer is not evidence of better replay value.

Reject the experiment if descending becomes an automatic choice, if extracting feels like declining the real game, or if players stop making deliberate terrain decisions. A second cavern is justified when it gives an established build a new problem worth risking it on.
