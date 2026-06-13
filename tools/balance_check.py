#!/usr/bin/env python3
"""Static balance/progression checks for Diggy's single-script data tables."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "scripts" / "main.gd"


def block_between(text: str, start: str, end: str) -> str:
    start_i = text.index(start)
    end_i = text.index(end, start_i)
    return text[start_i:end_i]


def ids_in_block(block: str) -> set[str]:
    return set(re.findall(r'"id"\s*:\s*"([^"]+)"', block))


def costs_in_block(block: str) -> list[int]:
    return [int(value) for value in re.findall(r'"cost"\s*:\s*(\d+)', block)]


def meta_upgrade_defs(block: str) -> list[tuple[str, int, list[int]]]:
    defs: list[tuple[str, int, list[int]]] = []
    for item in re.finditer(
        r'"id"\s*:\s*"([^"]+)".*?"max"\s*:\s*(\d+).*?"costs"\s*:\s*\[([^\]]*)\]',
        block,
        re.S,
    ):
        costs = [int(value) for value in re.findall(r"\d+", item.group(3))]
        defs.append((item.group(1), int(item.group(2)), costs))
    return defs


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    text = MAIN.read_text()

    upgrade_block = block_between(text, "func _upgrade_pool()", "func _offer_upgrades()")
    upgrade_ids = ids_in_block(upgrade_block)

    baseline_block = block_between(text, "func _baseline_relic_unlocks()", "func _load_meta()")
    baseline_ids = set(re.findall(r'"([^"]+)"\s*:\s*true', baseline_block))
    baseline_ids.discard("complete")

    milestone_block = block_between(text, "func _relic_research_milestones()", "func _relic_is_discovered")
    milestone_ids = ids_in_block(milestone_block)
    milestone_costs = costs_in_block(milestone_block)

    meta_upgrade_block = block_between(text, "func _meta_upgrade_defs()", "func _achievement_defs()")
    meta_upgrades = meta_upgrade_defs(meta_upgrade_block)
    meta_upgrade_ids = [upgrade_id for upgrade_id, _, _ in meta_upgrades]

    achievement_block = block_between(text, "func _achievement_defs()", "func _relic_research_milestones()")
    reward_relic_ids = set()
    for ids_text in re.findall(r'"ids"\s*:\s*\[([^\]]+)\]', achievement_block):
        reward_relic_ids.update(re.findall(r'"([^"]+)"', ids_text))

    missing = sorted((baseline_ids | milestone_ids | reward_relic_ids) - upgrade_ids - {"full_heal"})
    if missing:
        fail(f"Unknown upgrade ids referenced: {', '.join(missing)}")

    if milestone_costs != sorted(milestone_costs):
        fail("Relic research milestone costs must be nondecreasing")

    if len(milestone_ids) != len(re.findall(r'"id"\s*:\s*"([^"]+)"', milestone_block)):
        fail("Duplicate relic research milestone id")

    if len(meta_upgrade_ids) != len(set(meta_upgrade_ids)):
        fail("Duplicate meta upgrade id")

    for upgrade_id, max_level, costs in meta_upgrades:
        if max_level < 1:
            fail(f"{upgrade_id} max level must be positive")
        if len(costs) != max_level:
            fail(f"{upgrade_id} must define one cost per level")
        if any(cost <= 0 for cost in costs):
            fail(f"{upgrade_id} costs must be positive")
        if costs != sorted(costs):
            fail(f"{upgrade_id} costs must be nondecreasing")

    map_consts = set(re.findall(r"const (MAP_[A-Z0-9_]+) :=", text))
    referenced_maps = set(re.findall(r'"kind"\s*:\s*"map",\s*"id"\s*:\s*(MAP_[A-Z0-9_]+)', achievement_block))
    if not referenced_maps <= map_consts:
        fail(f"Unknown map constants: {', '.join(sorted(referenced_maps - map_consts))}")

    mod_consts = set(re.findall(r"const (BEACON_MOD_[A-Z0-9_]+) :=", text))
    referenced_mods = set(re.findall(r'"kind"\s*:\s*"beacon_mod",\s*"id"\s*:\s*(BEACON_MOD_[A-Z0-9_]+)', achievement_block))
    if not referenced_mods <= mod_consts:
        fail(f"Unknown beacon mod constants: {', '.join(sorted(referenced_mods - mod_consts))}")

    if "func _available_chest_upgrade_pool()" not in text:
        fail("Chest upgrade pool helper is missing")

    print(
        "OK: "
        f"{len(upgrade_ids)} upgrades, "
        f"{len(milestone_ids)} research milestones, "
        f"{len(reward_relic_ids)} achievement relic rewards, "
        f"{len(meta_upgrades)} meta upgrades"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
