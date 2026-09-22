extends SceneTree

const TestGame := preload("res://tests/test_game.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_ordered_cardinal_input()
	_test_hold_and_toggle_pumping()
	_test_attack_does_not_become_interact()
	_test_pump_timing_and_release()
	_test_miss_and_cosmetic_flash_recovery()
	_test_two_pointer_touch_input()
	_test_gameplay_timers_freeze_in_menus()
	_test_reward_eligibility()
	_test_presentation_contracts()
	_test_cave_encounter_grammar()
	_test_boulder_kill_attribution()
	_test_movement_and_impact_contracts()
	_test_run_identity_and_progression()
	_test_exploration_reward_payoffs()
	if failures.is_empty():
		print("OK: control, encounter, movement, impact, run identity, and progression regressions")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _game() -> Node:
	var game := TestGame.new()
	game.meta = game._default_meta()
	game.state = game.STATE_PLAYING
	return game


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_ordered_cardinal_input() -> void:
	var inputs := [
		[KEY_LEFT, Vector2i.LEFT],
		[KEY_RIGHT, Vector2i.RIGHT],
		[KEY_UP, Vector2i.UP],
		[KEY_DOWN, Vector2i.DOWN],
	]
	for first in inputs:
		for second in inputs:
			if first[0] == second[0]:
				continue
			var game := _game()
			game._handle_keyboard_move_event(_key_event(first[0], true), first[1])
			game._handle_keyboard_move_event(_key_event(second[0], true), second[1])
			_expect(game._read_move_dir() == second[1], "latest cardinal press did not win: %s then %s" % [first[1], second[1]])
			game._handle_keyboard_move_event(_key_event(second[0], false), second[1])
			_expect(game._read_move_dir() == first[1], "releasing latest cardinal did not restore prior held direction")
			game.free()

	var alias_game := _game()
	alias_game._handle_keyboard_move_event(_key_event(KEY_LEFT, true), Vector2i.LEFT)
	alias_game._handle_keyboard_move_event(_key_event(KEY_A, true), Vector2i.LEFT)
	alias_game._handle_keyboard_move_event(_key_event(KEY_A, false), Vector2i.LEFT)
	_expect(alias_game._read_move_dir() == Vector2i.LEFT, "releasing an alias released another held key")
	alias_game.free()


func _test_hold_and_toggle_pumping() -> void:
	var hold_game := _game()
	hold_game.lance_active = true
	hold_game._set_lance_input(false)
	_expect(not hold_game.lance_active, "hold mode did not disengage on release")
	hold_game.free()

	var toggle_game := _game()
	var settings: Dictionary = toggle_game.meta["settings"]
	settings["hold_to_pump"] = false
	toggle_game.meta["settings"] = settings
	toggle_game.lance_active = true
	toggle_game._set_lance_input(false)
	_expect(toggle_game.lance_active, "toggle mode disengaged on release")
	toggle_game._set_lance_input(true)
	_expect(not toggle_game.lance_active, "second toggle press did not disengage")
	toggle_game.free()


func _prepare_open_board(game: Node) -> void:
	game.grid.clear()
	for x in range(game.BOARD_W):
		var column := []
		for _y in range(game.BOARD_H):
			column.append(game.TILE_TUNNEL)
		game.grid.append(column)
	game.player_pos = Vector2i(5, 5)
	game.player_visual_pos = Vector2(5, 5)
	game.player_target_cell = game.player_pos
	game.facing = Vector2i.RIGHT
	game.current_map_def = {}


func _test_attack_does_not_become_interact() -> void:
	var game := _game()
	_prepare_open_board(game)
	game.grid[6][5] = game.TILE_VAULT_GATE
	game._press_lance()
	_expect(game.lance_active, "attack was intercepted beside a locked vault gate")
	_expect(game.vaults_opened == 0, "attack opened a vault")
	game._release_lance(false)
	game.grid[6][5] = game.TILE_BEACON
	game.beacon_pos = Vector2i(6, 5)
	game.beacon_armed = true
	game._press_lance()
	_expect(game.lance_active and game.state == game.STATE_PLAYING, "attack was intercepted beside an armed beacon")
	game.free()


func _test_pump_timing_and_release() -> void:
	var game := _game()
	_prepare_open_board(game)
	var lance_target := Rect2(Vector2(0, 18), game.MOBILE_LANCE_RECT.size)
	var interact_target := Rect2(Vector2(0, -110), game.MOBILE_INTERACT_RECT.size)
	_expect(not lance_target.intersects(interact_target), "touch combat and interaction targets overlap")
	game._add_enemy(Vector2i(7, 5), game.ENEMY_GRUB_KIND)
	game._set_lance_input(true)
	_expect(game.lance_active and game.lance_attached_enemy == 0, "lance did not attach in the pump fixture")
	game._update_lance(game.LANCE_HIT_DELAY + 0.01)
	_expect(game.enemies[0]["hp"] == 2, "first pressure beat did not deal one damage")
	_expect(game.combat_trace.size() == 1 and String(game.combat_trace[0].get("cause", "")) == "lance_pump", "first pressure beat was not traced as lance damage")
	_expect(int(game.combat_trace[0].get("amount", 0)) == 1, "pump trace did not record its damage amount")
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)
	_expect(game.enemies[0]["hp"] == 1, "held pump did not apply a subsequent pressure beat")
	game._set_lance_input(false)
	_expect(not game.lance_active, "release did not end an attached pump")
	_expect(game.attack_cooldown > 0.0, "release did not start explicit attack recovery")
	game.free()


func _test_miss_and_cosmetic_flash_recovery() -> void:
	var game := _game()
	_prepare_open_board(game)
	game.keyboard_move_dir = Vector2i.DOWN
	game.facing = Vector2i.RIGHT
	game._press_lance()
	_expect(game.facing == Vector2i.DOWN, "attack did not resolve the latest movement intent first")
	game._update_lance(game.LANCE_HIT_DELAY + 0.01)
	game._update_lance(game.LANCE_RETRACT_DELAY + 0.01)
	_expect(not game.lance_active and game.attack_cooldown > 0.0, "miss did not retract into explicit recovery")
	var before: Vector2 = game.player_visual_pos
	game.attack_flash = 1.0
	game._update_player_motion(0.1, Vector2i.RIGHT)
	_expect(game.player_visual_pos.x > before.x, "cosmetic attack flash still controls movement lockout")
	game.free()


func _test_two_pointer_touch_input() -> void:
	var game := _game()
	_prepare_open_board(game)
	game.show_touch_controls = true
	game.mobile_touch_dirs[10] = Vector2i.RIGHT
	game.mobile_touch_order.append(10)
	game._refresh_mobile_move_dir()
	game.mobile_lance_pointers[11] = true
	game._set_lance_input(true)
	_expect(game.mobile_move_dir == Vector2i.RIGHT, "second touch replaced movement input")
	_expect(game.lance_active, "second touch did not start combat while moving")
	game._release_mobile_pointer(11)
	_expect(not game.lance_active, "releasing combat touch did not disengage hold pump")
	_expect(game.mobile_move_dir == Vector2i.RIGHT, "releasing combat touch also released movement")
	game._release_mobile_pointer(10)
	game.free()


func _test_gameplay_timers_freeze_in_menus() -> void:
	for mode in ["paused", "guide", "inventory", "draft"]:
		var game := _game()
		game.player_hit_recovery = 0.9
		game.combo_timer = 1.2
		game.combo_count = 3
		match mode:
			"paused":
				game.paused = true
			"guide":
				game.show_guide = true
			"inventory":
				game.show_upgrade_inventory = true
			"draft":
				game.state = game.STATE_CHOOSING
		game._process(0.5)
		_expect(is_equal_approx(game.player_hit_recovery, 0.9), "%s consumed hit recovery" % mode)
		_expect(is_equal_approx(game.combo_timer, 1.2) and game.combo_count == 3, "%s consumed combo time" % mode)
		game.free()


func _test_reward_eligibility() -> void:
	var abandoned := _game()
	abandoned.run_time = 90.0
	abandoned.run_kills = 4
	abandoned._record_run_meta_progress(abandoned.RUN_OUTCOME_ABANDONED)
	var abandoned_lifetime: Dictionary = abandoned.meta["lifetime"]
	_expect(abandoned_lifetime["relic_research"] == 0 and abandoned_lifetime["runes"] == 0, "abandoned run earned progression")
	_expect(abandoned_lifetime["runs_completed"] == 0, "abandoned run counted as completed")
	abandoned._record_run_meta_progress(abandoned.RUN_OUTCOME_ABANDONED)
	_expect(abandoned_lifetime["relic_research"] == 0, "repeated abandonment double-awarded progression")
	abandoned.free()

	var idle_defeat := _game()
	var idle_upgrades: Dictionary = idle_defeat.meta["meta_upgrades"]
	idle_upgrades["field_notes"] = 4
	idle_defeat.meta["meta_upgrades"] = idle_upgrades
	idle_defeat.run_kills = 1
	idle_defeat._record_run_meta_progress(idle_defeat.RUN_OUTCOME_DEFEAT)
	_expect(idle_defeat.meta["lifetime"]["relic_research"] == 0, "idle defeat or incidental kill earned research")
	idle_defeat.free()

	var active_defeat := _game()
	active_defeat.run_time = 4.0
	active_defeat.run_lance_hits = 1
	active_defeat._record_run_meta_progress(active_defeat.RUN_OUTCOME_DEFEAT)
	_expect(active_defeat.meta["lifetime"]["relic_research"] > 0, "genuine short defeat did not earn research")
	active_defeat.free()


func _test_presentation_contracts() -> void:
	var game := _game()
	_expect(game._portrait_board_rows_for_height(960.0) == 16, "compact portrait layout no longer reserves control space")
	_expect(game._portrait_board_rows_for_height(1385.0) == 31, "tall portrait layout did not spend extra height on cave rows")
	_expect(float(game.MOBILE_DPAD_BUTTON) * 390.0 / float(game.MOBILE_LAYOUT_W) >= 48.0, "direction controls are under 48 display pixels at 390px wide")
	_expect(game.MOBILE_INTERACT_RECT.size.y * 390.0 / float(game.MOBILE_LAYOUT_W) >= 48.0, "interact target is under 48 display pixels at 390px wide")

	_prepare_open_board(game)
	game._add_enemy(Vector2i(7, 5), game.ENEMY_GRUB_KIND)
	var enemy: Dictionary = game.enemies[0]
	_expect(game._enemy_pressure_pose(enemy) == "neutral", "healthy enemy pose is not neutral")
	enemy["inflated"] = true
	game.lance_active = true
	game.lance_attached_enemy = 0
	_expect(game._enemy_pressure_pose(enemy) == "pumping", "attached enemy pose is not pumping")
	enemy["hp"] = 1
	_expect(game._enemy_pressure_pose(enemy) == "critical", "almost-bursting enemy pose is not critical")
	enemy["hp"] = 2
	game.lance_active = false
	game.lance_attached_enemy = -1
	_expect(game._enemy_pressure_pose(enemy) == "recovering", "released inflated enemy pose is not recovering")

	game.font = ThemeDB.get_fallback_font()
	game.show_touch_controls = true
	game.run_time = 10.0
	var hint: String = game._tutorial_hint_text()
	var lines: Array = game._wrap_text(hint, 14, 500.0, 2)
	_expect(lines.size() <= 2 and "disengage" in " ".join(lines), "touch pumping instruction is truncated")
	game.free()


func _test_cave_encounter_grammar() -> void:
	for seed_value in range(16):
		var game := _game()
		game.player_pos = Vector2i(int(game.BOARD_W * 0.5), 1)
		game.player_target_cell = game.player_pos
		game.current_map_def = {}
		game.depth_tier = 3
		game.rng.seed = 1200 + seed_value
		game._build_cavern()
		var errors: Array[String] = game._encounter_validation_errors()
		_expect(errors.is_empty(), "seed %d produced invalid encounter geometry: %s" % [seed_value, "; ".join(errors)])
		_expect(game.cave_encounters.size() == 3, "seed %d did not place the three encounter patterns" % seed_value)
		var ids := {}
		for encounter in game.cave_encounters:
			ids[String(encounter["id"])] = true
			_expect(game._connected_tunnel_cells(encounter["approach"]).has(encounter["escape"]), "seed %d encounter has no usable escape" % seed_value)
		_expect(ids.has(game.ENCOUNTER_ROCK_AMBUSH), "seed %d is missing the rock ambush" % seed_value)
		_expect(ids.has(game.ENCOUNTER_FLANK_LOOP), "seed %d is missing the flank loop" % seed_value)
		_expect(ids.has(game.ENCOUNTER_GUARDED_VEIN), "seed %d is missing the guarded vein" % seed_value)
		_expect(game._active_special_enemy_kinds().size() <= 1, "seed %d introduced multiple unfamiliar enemy types together" % seed_value)
		game.free()


func _test_boulder_kill_attribution() -> void:
	var cave_in := _game()
	_prepare_open_board(cave_in)
	cave_in._add_rock(Vector2i(8, 4))
	cave_in._add_enemy(Vector2i(8, 5), cave_in.ENEMY_GRUB_KIND)
	cave_in._update_rocks(cave_in.ROCK_LOOSE_DELAY + 0.01)
	_expect(cave_in.enemies.size() == 1 and bool(cave_in.rocks[0]["impact_pending"]), "cave-in damage landed before the rock sprite")
	cave_in._update_visual_positions(1.0)
	cave_in._update_rocks(0.0)
	_expect(cave_in.run_kills == 1, "environmental cave-in did not resolve its enemy kill")
	_expect(cave_in.combat_trace.size() == 1 and String(cave_in.combat_trace[0].get("cause", "")) == "cave_in", "environmental rock damage was not traced as a cave-in")
	_expect(cave_in.run_boulder_kills == 0, "untriggered cave-in counted as a player boulder kill")
	_expect(int(cave_in.meta["lifetime"].get("boulder_kills", 0)) == 0, "untriggered cave-in advanced lifetime boulder progress")
	_expect(not bool(cave_in.meta["achievements"].get("first_boulder_kill", false)), "untriggered cave-in unlocked Rock Plan")
	cave_in.free()

	var player_drop := _game()
	_prepare_open_board(player_drop)
	player_drop._add_rock(Vector2i(8, 4))
	player_drop.player_dug_cells[Vector2i(8, 5)] = 0.0
	player_drop._add_enemy(Vector2i(8, 5), player_drop.ENEMY_GRUB_KIND)
	player_drop._update_rocks(player_drop.ROCK_LOOSE_DELAY + 0.01)
	player_drop._update_visual_positions(1.0)
	player_drop._update_rocks(0.0)
	_expect(player_drop.run_boulder_kills == 1, "player-dug support did not attribute the boulder kill")
	_expect(player_drop.combat_trace.size() == 1 and String(player_drop.combat_trace[0].get("cause", "")) == "boulder_player", "player rock damage was not traced to the player")
	_expect(int(player_drop.meta["lifetime"].get("boulder_kills", 0)) == 1, "player boulder kill did not advance lifetime progress")
	_expect(bool(player_drop.meta["achievements"].get("first_boulder_kill", false)), "player boulder kill did not unlock Rock Plan")
	player_drop.free()


func _test_movement_and_impact_contracts() -> void:
	var game := _game()
	_prepare_open_board(game)
	_expect(is_equal_approx(game._player_tunnel_speed(), 3.2), "prepared tunnel speed is not 3.2 cells/s")
	_expect(is_equal_approx(game._player_dig_speed(), 2.5), "fresh-soil speed is not 2.5 cells/s")
	game._add_enemy(Vector2i(9, 5), game.ENEMY_GRUB_KIND)
	_expect(is_equal_approx(game._enemy_move_speed(game.enemies[0]), 2.0), "basic pursuit no longer has an independent 2.0 cells/s baseline")
	game.move_delay *= 0.5
	_expect(game._player_tunnel_speed() > 6.0, "player speed modifier did not affect tunnel movement")
	_expect(is_equal_approx(game._enemy_move_speed(game.enemies[0]), 2.0), "player speed modifier also accelerated enemies")

	game._hit_stop(1.0)
	_expect(is_equal_approx(game.hit_stop_timer, game.HIT_STOP_MAX), "hit-stop did not respect its multi-impact cap")
	var settings: Dictionary = game.meta["settings"]
	settings["hit_stop"] = false
	game.meta["settings"] = settings
	game.hit_stop_timer = 0.0
	game._hit_stop(game.HIT_STOP_BOULDER_IMPACT)
	_expect(is_zero_approx(game.hit_stop_timer), "disabled hit-stop still froze gameplay")

	_expect(game._boss_max_hp_for_variant(2) == game.BOSS_MAX_HP + 20, "boss health still scales primarily through repeated pump cycles")
	_expect(game._boss_boulder_damage(3) * 2 >= game._boss_max_hp_for_variant(0), "terrain damage is not a practical boss answer")
	game.free()

func _test_run_identity_and_progression() -> void:
	var fresh := _game()
	fresh._offer_starting_build_choice()
	_expect(fresh.state == fresh.STATE_CHOOSING and fresh.upgrade_choice_context == "starter", "fresh run did not open with a starter-plan draft")
	_expect(fresh.upgrade_choices.size() == 4, "fresh starter draft did not expose four mechanic-changing plans")
	var starter_ids := {}
	var ice_index := -1
	for i in range(fresh.upgrade_choices.size()):
		var choice: Dictionary = fresh.upgrade_choices[i]
		var id := String(choice.get("id", ""))
		starter_ids[id] = true
		_expect("->" in String(choice.get("effect", "")), "starter choice %s lacks a numerical before/after preview" % id)
		if id == "ice_tip":
			ice_index = i
	for expected_id in fresh.STARTER_UPGRADE_IDS:
		_expect(starter_ids.has(String(expected_id)), "starter draft is missing %s" % String(expected_id))
	_expect(ice_index >= 0, "starter draft has no Ice plan")
	fresh._choose_upgrade(ice_index)
	_expect(fresh.state == fresh.STATE_PLAYING and fresh._active_lance_element() == fresh.LANCE_ELEMENT_ICE, "starter choice did not define the current run")
	_expect(not fresh._element_is_researched(fresh.LANCE_ELEMENT_ICE), "starter choice incorrectly became a permanent research unlock")
	_expect(fresh._relic_is_discovered("ice_wall") and fresh._upgrade_is_available("ice_wall"), "starter element did not enable same-run follow-ups")
	fresh.free()

	var boulder := _game()
	boulder._apply_upgrade(boulder._upgrade_by_id("boulder_lance"), "starter")
	_expect(boulder._relic_is_discovered("boulder_lance_2") and boulder._upgrade_is_available("boulder_lance_2"), "Boulder starter did not enable its same-run progression branch")
	boulder.free()

	var healing := _game()
	healing.hp = healing.max_hp
	_expect(not healing._upgrade_is_available(healing.HEAL_UPGRADE_ID), "Full Heart is still offered at full health")
	healing.hp -= 1
	_expect(healing._upgrade_is_available(healing.HEAL_UPGRADE_ID), "Full Heart disappeared when recovery is useful")
	var heal_preview: Dictionary = healing._decorate_upgrade_choice(healing._upgrade_by_id(healing.HEAL_UPGRADE_ID))
	_expect("2 -> 3" in String(heal_preview.get("effect", "")), "Full Heart does not show the recovery before/after")
	healing.free()

	var build := _game()
	build.temp_lance_element = build.LANCE_ELEMENT_ICE
	build.temp_upgrades["ice_tip"] = true
	build.family_points["ice"] = 1
	var candidates := [
		build._upgrade_by_id("range"),
		build._upgrade_by_id("magnet"),
		build._upgrade_by_id("ice_wall"),
		build._upgrade_by_id("stun")
	]
	var drafted: Array = build._draft_upgrade_choices(candidates, 3)
	_expect(not drafted.is_empty() and build._upgrade_family(String(drafted[0]["id"])) == "ice", "draft did not guarantee a meaningful current-build choice")
	build.run_defeat_reason = "A spitter caught the escape lane."
	build.run_boulder_kills = 2
	build.owned_upgrades["boulder_lance"] = true
	var result_rows: Array = build._run_result_rows(false)
	_expect(result_rows.size() == 4, "run summary does not expose cause, best moment, build, and next unlock")
	_expect(String(result_rows[0]["label"]) == "CAUSE" and "spitter" in String(result_rows[0]["value"]).to_lower(), "run summary lost the cause of defeat")
	_expect(String(result_rows[1]["label"]) == "BEST" and "rock" in String(result_rows[1]["value"]).to_lower(), "run summary did not surface the best tactical moment")
	_expect(String(result_rows[2]["label"]) == "BUILD" and "Boulder Lance" in String(result_rows[2]["value"]), "run summary did not identify the build")
	_expect(String(result_rows[3]["label"]) == "NEXT" and "Permanent" in String(result_rows[3]["value"]), "run summary does not distinguish the next permanent unlock")
	build.free()


func _test_exploration_reward_payoffs() -> void:
	var mixed := _game()
	_prepare_open_board(mixed)
	mixed._apply_upgrade(mixed._upgrade_by_id("ice_tip"), "starter")
	var field_relic: Dictionary = mixed._upgrade_by_id("ice_wall").duplicate()
	field_relic["pos"] = mixed.player_pos
	mixed.run_relics.append(field_relic)
	mixed._collect_relic_at(mixed.player_pos)
	mixed.treasure_chests.append({"pos": mixed.player_pos, "reward": {"kind": mixed.TREASURE_KIND_UPGRADE, "upgrade": mixed._upgrade_by_id("ice_front")}})
	mixed._collect_treasure_chest_at(mixed.player_pos)
	_expect(int(mixed.family_points.get("ice", 0)) == 3, "starter, field, and chest relics did not share Ice set progress")
	_expect(is_equal_approx(mixed._effective_freeze_duration_bonus(), 1.70), "mixed-source Ice set did not award its three-piece bonus")
	for id in ["ice_shatter", "ice_brittle", "ice_lock"]:
		mixed._apply_upgrade(mixed._upgrade_by_id(id), "level")
	_expect(int(mixed.family_points.get("ice", 0)) == 6 and mixed._effective_frost_front() == 2, "exploration pickups prevented the six-piece Ice capstone")
	var freeze_before: float = mixed._effective_freeze_duration_bonus()
	mixed._apply_temp_upgrade(mixed._upgrade_by_id("ice_wall"))
	mixed._apply_upgrade(mixed._upgrade_by_id("ice_front"), "level")
	_expect(int(mixed.family_points.get("ice", 0)) == 6 and is_equal_approx(mixed._effective_freeze_duration_bonus(), freeze_before), "duplicate relics farmed family points or stats")
	mixed.free()

	var stale := _game()
	_prepare_open_board(stale)
	stale.meta["unlocked_relics"] = {"range": true, "magnet": true}
	stale._apply_upgrade(stale._upgrade_by_id("range"), "level")
	var stale_relic: Dictionary = stale._upgrade_by_id("range").duplicate()
	stale_relic["pos"] = stale.player_pos
	stale.run_relics.append(stale_relic)
	stale._collect_relic_at(stale.player_pos)
	_expect(stale._effective_lance_range() == 4 and stale._effective_xp_magnet_bonus() == 1, "preplaced relic already drafted was duplicated instead of replaced")
	_expect(String(stale.upgrade_pickup_toast.get("id", "")) == "magnet", "replacement field relic displayed the stale reward")
	stale.run_relics.append(stale_relic)
	stale._collect_relic_at(stale.player_pos)
	_expect(stale.gems_collected > 0 and int(stale.family_points.get("lance", 0)) == 1, "exhausted field relic pool did not pay gems without duplicate build credit")
	stale.free()

	var kit := _game()
	kit.meta["unlocked_loadouts"]["field_kit"] = true
	kit.meta["selected_loadout"] = "field_kit"
	kit.rng.seed = 2718
	kit._new_run()
	_expect(kit.max_hp == 4 and kit.hp == 4, "Field Kit did not deliver its advertised starting heart")
	_expect(int(kit.family_points.get("cave", 0)) == 1, "starting loadout did not contribute to its build")
	kit._new_run()
	_expect(kit.max_hp == 4 and int(kit.family_points.get("cave", 0)) == 1, "rerun carried over Field Kit hearts or family points")
	kit.free()

	var healing := _game()
	_prepare_open_board(healing)
	healing.hp = 2
	healing.treasure_chests.append({"pos": healing.player_pos, "reward": {"kind": healing.TREASURE_KIND_UPGRADE, "upgrade": healing._upgrade_by_id("field_dressing")}})
	healing._collect_treasure_chest_at(healing.player_pos)
	_expect(healing.max_hp == 4 and healing.hp == 4, "chest Field Dressing healed without adding its advertised heart")
	healing.free()

	for source in ["level", "field"]:
		var prospect := _game()
		_prepare_open_board(prospect)
		prospect.depth_tier = 2
		for x in range(prospect.BOARD_W):
			for y in range(prospect.BOARD_H):
				prospect.encounter_reserved_cells[Vector2i(x, y)] = true
		_expect(not prospect._upgrade_is_available("prospector"), "Prospector offered an unavailable gem reward")
		var reward_pos := Vector2i(7, 5)
		prospect.encounter_reserved_cells.erase(reward_pos)
		prospect.key_pickups.append(reward_pos)
		_expect(not prospect._upgrade_is_available("prospector"), "Prospector could overwrite another pickup")
		prospect.key_pickups.clear()
		_expect(prospect._upgrade_is_available("prospector"), "Prospector failed to find a reachable gem opportunity")
		prospect._apply_upgrade(prospect._upgrade_by_id("prospector"), source)
		_expect(prospect.super_gems.size() == 1 and prospect.super_gems.has(reward_pos) and prospect.run_super_gems_available == 1, "%s Prospector did not add a super gem in this cavern" % source)
		_expect(prospect.xp == 0 and prospect.beacon_charge == 0, "Prospector awarded collection value without visiting its gem")
		prospect._apply_temp_upgrade(prospect._upgrade_by_id("prospector"))
		_expect(prospect.super_gems.size() == 1 and int(prospect.family_points.get("gem", 0)) == 1, "duplicate Prospector farmed gems or family credit")
		prospect.free()
