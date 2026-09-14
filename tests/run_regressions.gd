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
	if failures.is_empty():
		print("OK: control, presentation, encounter, and attribution regressions")
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
	_expect(cave_in.run_kills == 1, "environmental cave-in did not resolve its enemy kill")
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
	_expect(player_drop.run_boulder_kills == 1, "player-dug support did not attribute the boulder kill")
	_expect(int(player_drop.meta["lifetime"].get("boulder_kills", 0)) == 1, "player boulder kill did not advance lifetime progress")
	_expect(bool(player_drop.meta["achievements"].get("first_boulder_kill", false)), "player boulder kill did not unlock Rock Plan")
	player_drop.free()
