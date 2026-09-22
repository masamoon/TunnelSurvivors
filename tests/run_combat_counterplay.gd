extends SceneTree

const TestGame := preload("res://tests/test_game.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_reaper_rejects_lance()
	_test_shield_requires_flank_or_riposte()
	for variant in range(3):
		_test_boss_counterattack(variant)
		_test_manual_release_cannot_reset_boss_pressure(variant)
	_test_counterattack_can_be_evaded()
	_test_boss_resistance_expires_without_invulnerability()
	_test_rocks_still_damage_resistant_bosses()
	_test_ordinary_pumping_still_works()
	if failures.is_empty():
		print("OK: Reaper pursuit, Shieldbug counterplay, boss retaliation, and boulder openings")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _game() -> Node:
	var game := TestGame.new()
	game.meta = game._default_meta()
	game.state = game.STATE_PLAYING
	game.current_map_def = {}
	for x in range(game.BOARD_W):
		var column := []
		for _y in range(game.BOARD_H):
			column.append(game.TILE_TUNNEL)
		game.grid.append(column)
	game.player_pos = Vector2i(5, 5)
	game.player_visual_pos = Vector2(5, 5)
	game.player_target_cell = game.player_pos
	game.facing = Vector2i.RIGHT
	return game


func _three_pumps(game: Node) -> void:
	game._press_lance()
	game._update_lance(game.LANCE_HIT_DELAY + 0.01)
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)


func _combat_tick(game: Node, delta: float, retry_lance: bool) -> void:
	game.attack_cooldown = maxf(0.0, game.attack_cooldown - delta)
	if retry_lance and not game.lance_active and game.attack_cooldown <= 0.0:
		game._press_lance()
	if game.lance_active:
		game._update_lance(delta)
	game._update_enemies(delta)


func _test_reaper_rejects_lance() -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_REAPER_KIND)
	game.enemies[0]["timer"] = 0.0
	game._press_lance()
	_expect(not game.lance_active and game.lance_attached_enemy == -1, "Reaper accepted a lance lock")
	_expect(not game.enemies[0]["inflated"] and game.enemies[0]["stun"] == 0.0, "Reaper rejection still immobilized it")
	_expect("Reaper" in game.message, "Reaper rejection lacked an explanatory cue")
	game._update_enemies(0.01)
	_expect(game.state == game.STATE_GAME_OVER, "Lance stopped adjacent Reaper pursuit")
	game.free()

	var escape := _game()
	escape._add_enemy(Vector2i(7, 5), escape.ENEMY_REAPER_KIND)
	escape._press_lance()
	escape._update_player_motion(0.1, Vector2i.DOWN)
	_expect(escape.player_visual_pos.y > 5.0, "Rejected lance locked the player's escape movement")
	escape.free()


func _test_shield_requires_flank_or_riposte() -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_SHIELDBUG_KIND)
	game._press_lance()
	_expect(not game.lance_active, "Frontal Shieldbug accepted an endless zero-damage lock")
	_expect(not game.enemies[0]["inflated"] and game.enemies[0]["stun"] == 0.0, "Deflected lance cancelled Shieldbug pressure")
	game.free()

	for riposte in [false, true]:
		var allowed := _game()
		allowed._add_enemy(Vector2i(6, 5), allowed.ENEMY_SHIELDBUG_KIND)
		allowed.enemies[0]["face_dir"] = Vector2i.LEFT if riposte else Vector2i.UP
		allowed.enemies[0]["attack_windup"] = allowed.ENEMY_ATTACK_WARN if riposte else 0.0
		var before: int = allowed.enemies[0]["hp"]
		allowed._press_lance()
		allowed._update_lance(allowed.LANCE_HIT_DELAY + 0.01)
		_expect(allowed.enemies[0]["hp"] == before - (2 if riposte else 1), "Shieldbug flank/riposte damage was lost")
		allowed.free()


func _test_boss_counterattack(variant: int) -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_BOSS_KIND, variant)
	_three_pumps(game)
	_expect(not game.lance_active, "Boss %d did not break after three pumps" % variant)
	var before: int = game.hp
	for _frame in range(70):
		_combat_tick(game, 0.01, true)
	_expect(game.hp < before, "Boss %d could not retaliate against stationary re-hook spam" % variant)
	game.free()


func _test_manual_release_cannot_reset_boss_pressure(variant: int) -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_BOSS_KIND, variant)
	for beat in range(3):
		game._press_lance()
		game._update_lance(game.LANCE_HIT_DELAY + 0.01)
		if beat < 2:
			game._release_lance()
			game.attack_cooldown = 0.0
	_expect(not game.lance_active, "Boss %d pressure budget reset on manual disengagement" % variant)
	game.free()


func _test_counterattack_can_be_evaded() -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_BOSS_KIND, 2)
	_three_pumps(game)
	var before: int = game.hp
	for _frame in range(20):
		game._update_player_motion(0.02, Vector2i.DOWN)
		_combat_tick(game, 0.02, false)
	for _frame in range(25):
		_combat_tick(game, 0.02, false)
	_expect(game.player_pos.y > 5, "Boss break did not restore escape movement")
	_expect(game.hp == before, "Dodged boss counterattack still damaged the player")
	game.free()


func _test_rocks_still_damage_resistant_bosses() -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_BOSS_KIND)
	_three_pumps(game)
	var before: int = game.enemies[0]["hp"]
	game._crush_at(Vector2i(6, 5), 1, true)
	_expect(game.enemies[0]["hp"] == before - game._boss_boulder_damage(1), "Boss latch resistance blocked boulder damage")
	game.free()


func _test_boss_resistance_expires_without_invulnerability() -> void:
	var game := _game()
	game._add_enemy(Vector2i(6, 5), game.ENEMY_BOSS_KIND)
	_three_pumps(game)
	game.enemies[0]["attack_windup"] = game.ENEMY_ATTACK_WARN
	game.enemies[0]["attack_dir"] = Vector2i.LEFT
	game.attack_cooldown = 0.0
	game._press_lance()
	_expect(not game.lance_active and game.enemies[0]["attack_windup"] == game.ENEMY_ATTACK_WARN, "Rejected re-hook cancelled the boss's telegraphed attack")
	var before: int = game.enemies[0]["hp"]
	game._damage_enemy(0, 1, "", "")
	_expect(game.enemies[0]["hp"] == before - 1, "Latch resistance became damage invulnerability")
	game._update_enemies(game.BOSS_LANCE_RESIST_DURATION + 0.01)
	game.attack_cooldown = 0.0
	game._press_lance()
	_expect(game.lance_active and game.lance_attached_enemy == 0, "Boss remained unhookable after its response window")
	game.free()


func _test_ordinary_pumping_still_works() -> void:
	var game := _game()
	game._add_enemy(Vector2i(7, 5), game.ENEMY_GRUB_KIND)
	_three_pumps(game)
	_expect(game.enemies.is_empty() and game.run_kills == 1, "Ordinary three-beat pumping no longer kills a grub")
	game.free()
