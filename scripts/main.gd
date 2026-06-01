extends Node2D

const BOARD_W := 22
const BOARD_H := 17
const CELL := 28
const BOARD_PX_W := BOARD_W * CELL
const BOARD_PX_H := BOARD_H * CELL
const BOARD_ORIGIN := Vector2(24, 74)
const PANEL_X := 680
const MAX_FLOOR := 8
const DIG_SUBDIV := 4
const DIG_SUBCELL_COUNT := DIG_SUBDIV * DIG_SUBDIV
const DIG_PROMOTE_SUBCELLS := DIG_SUBCELL_COUNT
const PLAYER_DIG_FOOTPRINT := CELL * 0.92

const TILE_DIRT := 0
const TILE_TUNNEL := 1
const TILE_EXIT := 2

const ENEMY_GRUB_KIND := 0
const ENEMY_BURROWER_KIND := 1
const ENEMY_FYGAR_KIND := 2

const STATE_PLAYING := 0
const STATE_CHOOSING := 1
const STATE_GAME_OVER := 2
const STATE_WIN := 3

const RUN_GOAL_TIME := 8.0 * 60.0
const XP_BASE_TO_NEXT := 6
const XP_GROWTH := 4
const XP_PICKUP_RADIUS := 0.52
const XP_MAGNET_RADIUS := 2.35
const XP_MAGNET_SPEED := 6.5
const SPAWN_START_DELAY := 7.0
const SPAWN_INTERVAL_MIN := 0.90
const SPAWN_INTERVAL_MAX := 4.0
const SPAWN_CAP_BASE := 5
const SPAWN_CAP_GROWTH := 3
const SPAWN_BURST_MIN := 1
const SPAWN_BURST_MAX := 3
const REGROW_CHECK_INTERVAL := 1.15
const REGROW_CELL_AGE := 34.0
const REGROW_PLAYER_SAFE_RADIUS := 5
const REGROW_MAX_PER_TICK := 3
const ROCK_SPAWN_START_DELAY := 12.0
const ROCK_SPAWN_INTERVAL_MIN := 5.5
const ROCK_SPAWN_INTERVAL_MAX := 10.0
const ROCK_CAP_BASE := 12
const ROCK_CAP_GROWTH := 2
const ROCK_SPAWN_SAFE_RADIUS := 5

const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const ROCK_LOOSE_DELAY := 1.12
const ROCK_STEP_DELAY := 0.25
const PHASE_MIN_FLOOR := 1
const PHASE_COOLDOWN_MIN := 3.0
const PHASE_COOLDOWN_MAX := 6.0
const PHASE_THIN_WALL_TUNNEL_NEIGHBORS := 1
const ENEMY_STUCK_STEPS_TO_SQUEEZE := 4
const FYGAR_MIN_FLOOR := 2
const FYGAR_FIRE_WARN := 0.52
const FYGAR_FIRE_ACTIVE := 0.42
const FYGAR_FIRE_COOLDOWN_MIN := 2.2
const FYGAR_FIRE_COOLDOWN_MAX := 4.2
const FYGAR_FIRE_RANGE := 6
const ENEMY_GRUB_SPEED_RATIO := 1.0
const ENEMY_BURROWER_SPEED_RATIO := 1.0
const ENEMY_FYGAR_SPEED_RATIO := 1.0
const ENEMY_PHASE_SPEED_RATIO := 0.25
const ENEMY_ATTACK_WARN := 0.24
const ENEMY_ATTACK_LUNGE_CELLS := 0.34
const ROCK_VISUAL_SPEED := 4.0
const ENEMY_HIT_FLASH := 0.26
const DIG_FEEDBACK_TIME := 0.34
const PULSE_FEEDBACK_TIME := 0.42
const ATTACK_RECOVERY_DELAY := 0.32
const ATTACK_FLASH_TIME := 0.32
const LANCE_HIT_DELAY := 0.10
const LANCE_RETRACT_DELAY := 0.22
const LANCE_PUMP_INTERVAL := 0.50
const LANCE_HOLD_STUN := 0.10
const ENEMY_INFLATE_RECOVER_DELAY := 0.42
const BASE_MOVE_DELAY := 0.50
const BASE_DIG_DELAY_MULT := 1.0
const PLAYER_CENTER_EPS := 0.015
const PLAYER_TARGET_GATE := 0.10
const TUNNEL_HALF_WIDTH := (CELL - 1.0) * 0.5
const COMBO_WINDOW := 2.2
const SHOP_SKIP_KEY_TEXT := "0 / Enter skips"
const BG := Color("#101217")
const DIRT := Color("#7a4b30")
const DIRT_DARK := Color("#553322")
const TUNNEL := Color("#1b1b20")
const ROCK := Color("#87909b")
const ROCK_SHADOW := Color("#454b55")
const PLAYER := Color("#5ee1c5")
const PLAYER_DARK := Color("#177d73")
const ENEMY_GRUB := Color("#f26d86")
const ENEMY_BURROWER := Color("#f2b84b")
const ENEMY_FYGAR := Color("#93d84f")
const FIRE := Color("#ff774d")
const GEM := Color("#8bd3ff")
const PRESSURE := Color("#d9f8ff")
const RUPTURE := Color("#ffd166")
const EXIT_LOCKED := Color("#5e5566")
const EXIT_OPEN := Color("#b6f36b")
const UI := Color("#e8e2cf")
const MUTED := Color("#9aa0aa")
const WARN := Color("#ffcc66")

var rng := RandomNumberGenerator.new()
var font: Font

var grid := []
var soil_image: Image
var soil_texture: ImageTexture
var soil_dirty := false
var rocks := []
var gems := []
var xp_pickups := []
var enemies := []
var floor_relics := []
var upgrade_choices := []
var last_attack_cells := []
var dig_feedback := []
var dig_segments := []
var dig_masks := {}
var player_dug_cells := {}
var pulse_feedback := []

var state := STATE_PLAYING
var player_pos := Vector2i.ZERO
var facing := Vector2i.RIGHT
var hp := 3
var max_hp := 3
var floor_index := 1
var player_level := 1
var xp := 0
var xp_to_next := XP_BASE_TO_NEXT
var run_time := 0.0
var spawn_timer := 0.0
var regrow_timer := 0.0
var rock_spawn_timer := 0.0
var tunnel_age := {}
var score := 0
var gems_collected := 0
var gem_bank := 0
var exit_pos := Vector2i.ZERO
var exit_unlocked := false
var message := ""
var last_floor_summary := ""

var move_cooldown := 0.0
var attack_cooldown := 0.0
var attack_flash := 0.0
var lance_active := false
var lance_attached_enemy := -1
var lance_blocking_cell := Vector2i.ZERO
var lance_has_blocker := false
var lance_pump_timer := 0.0
var lance_pump_damage := 1
var lance_burst_ready := false
var lance_has_struck := false
var hurt_flash := 0.0
var anim_time := 0.0
var screen_shake := 0.0
var screen_shake_offset := Vector2.ZERO
var player_visual_pos := Vector2.ZERO
var player_visual_speed := 1.0 / BASE_MOVE_DELAY
var player_move_dir := Vector2i.ZERO
var player_step_from := Vector2i.ZERO
var player_target_cell := Vector2i.ZERO
var player_target_digging := false
var player_digging := false
var player_step_squash := 0.0

var move_delay := BASE_MOVE_DELAY
var dig_delay_mult := BASE_DIG_DELAY_MULT
var lance_range := 3
var lance_damage := 1
var stun_bonus := 0.0
var gem_bonus := 0
var rock_ward := false
var split_jet := 0
var crystal_charge := 0
var crystal_charge_cap := 0
var stone_circuit := 0
var resonant_hits := 0
var pressure_wave := 0
var shard_bloom := 0
var gem_pulse := 0
var tunnel_momentum := 0
var temp_lance_range := 0
var temp_lance_damage := 0
var temp_stun_bonus := 0.0
var temp_split_jet := 0
var temp_pressure_wave := 0
var temp_shard_bloom := 0
var temp_gem_pulse := 0
var temp_tunnel_momentum := 0
var temp_rock_ward := false
var family_points := {}
var combo_count := 0
var combo_timer := 0.0
var best_combo := 0
var floor_gems_available := 0
var floor_gems_collected := 0
var floor_kills := 0
var floor_boulder_kills := 0
var floor_relics_found := 0
var floor_damage_taken := 0

func _ready() -> void:
    font = ThemeDB.get_fallback_font()
    rng.randomize()
    _new_run()


func _new_run() -> void:
    floor_index = 1
    player_level = 1
    xp = 0
    xp_to_next = XP_BASE_TO_NEXT
    run_time = 0.0
    spawn_timer = SPAWN_START_DELAY
    regrow_timer = REGROW_CHECK_INTERVAL
    rock_spawn_timer = ROCK_SPAWN_START_DELAY
    score = 0
    gems_collected = 0
    gem_bank = 0
    max_hp = 2
    hp = max_hp
    move_delay = BASE_MOVE_DELAY
    dig_delay_mult = BASE_DIG_DELAY_MULT
    lance_range = 3
    lance_damage = 1
    stun_bonus = 0.0
    gem_bonus = 0
    rock_ward = false
    split_jet = 0
    crystal_charge = 0
    crystal_charge_cap = 0
    stone_circuit = 0
    resonant_hits = 0
    pressure_wave = 0
    shard_bloom = 0
    gem_pulse = 0
    tunnel_momentum = 0
    family_points = {}
    combo_count = 0
    combo_timer = 0.0
    best_combo = 0
    last_floor_summary = ""
    _start_floor()


func _start_floor() -> void:
    state = STATE_PLAYING
    player_pos = Vector2i(int(BOARD_W * 0.5), 1)
    player_visual_pos = _visual_from_pos(player_pos)
    player_visual_speed = 1.0 / BASE_MOVE_DELAY
    player_move_dir = Vector2i.ZERO
    player_step_from = player_pos
    player_target_cell = player_pos
    player_target_digging = false
    player_digging = false
    facing = Vector2i.RIGHT
    exit_unlocked = false
    move_cooldown = 0.0
    attack_cooldown = 0.0
    lance_active = false
    lance_attached_enemy = -1
    lance_blocking_cell = Vector2i.ZERO
    lance_has_blocker = false
    lance_pump_timer = 0.0
    lance_pump_damage = _effective_lance_damage()
    lance_burst_ready = false
    lance_has_struck = false
    temp_lance_range = 0
    temp_lance_damage = 0
    temp_stun_bonus = 0.0
    temp_split_jet = 0
    temp_pressure_wave = 0
    temp_shard_bloom = 0
    temp_gem_pulse = 0
    temp_tunnel_momentum = 0
    temp_rock_ward = false
    last_attack_cells.clear()
    dig_feedback.clear()
    dig_segments.clear()
    dig_masks.clear()
    player_dug_cells.clear()
    pulse_feedback.clear()
    xp_pickups.clear()
    tunnel_age.clear()
    combo_count = 0
    combo_timer = 0.0
    screen_shake = 0.0
    screen_shake_offset = Vector2.ZERO
    floor_gems_collected = 0
    floor_kills = 0
    floor_boulder_kills = 0
    floor_relics_found = 0
    floor_damage_taken = 0
    player_step_squash = 0.0
    message = "Survive the den. Dig space, time your lance, harvest pressure gems."
    _build_cavern()
    floor_gems_available = gems.size()
    queue_redraw()


func _resume_survival() -> void:
    state = STATE_PLAYING
    upgrade_choices.clear()
    message = "Level %d. Back into the dirt." % player_level
    queue_redraw()


func _build_cavern() -> void:
    grid.clear()
    rocks.clear()
    gems.clear()
    enemies.clear()
    floor_relics.clear()

    for x in range(BOARD_W):
        var column := []
        for y in range(BOARD_H):
            column.append(TILE_DIRT)
        grid.append(column)

    _carve_player_start()
    exit_pos = Vector2i(rng.randi_range(3, BOARD_W - 4), BOARD_H - 2)
    _set_tile(exit_pos, TILE_EXIT)

    var enemy_count := 2 + floor_index
    var patrol_cells := _carve_enemy_patrols(enemy_count)

    _place_rocks(8 + floor_index)
    _place_gems(7 + floor_index)
    var relic_count := 0 if floor_index == 1 else 1 + (1 if floor_index >= 7 else 0)
    _place_floor_relics(relic_count)
    _place_enemies(enemy_count, patrol_cells)
    _rebuild_soil_mask_from_grid()


func _carve_player_start() -> void:
    _carve_cell(player_pos)
    _carve_cell(player_pos + Vector2i.DOWN)


func _carve_enemy_patrols(count: int) -> Array:
    var patrol_cells := []
    var galleries := 0
    var attempts := 0
    while galleries < count and attempts < 240:
        attempts += 1
        var gallery := _make_patrol_gallery()
        if not _gallery_is_clear(gallery):
            continue
        for pos in gallery:
            _carve_cell(pos)
            patrol_cells.append(pos)
        galleries += 1
    return patrol_cells


func _make_patrol_gallery() -> Array:
    var gallery := []
    var horizontal := rng.randf() < 0.78
    var length := rng.randi_range(4, 7)
    if horizontal:
        var y := rng.randi_range(4, BOARD_H - 3)
        var start_x := rng.randi_range(2, BOARD_W - length - 2)
        for x in range(start_x, start_x + length):
            gallery.append(Vector2i(x, y))
        if rng.randf() < 0.35:
            var notch_x := start_x + rng.randi_range(1, length - 2)
            var notch_dir := Vector2i.DOWN if rng.randf() < 0.5 else Vector2i.UP
            gallery.append(Vector2i(notch_x, y) + notch_dir)
    else:
        var x := rng.randi_range(3, BOARD_W - 4)
        var start_y := rng.randi_range(4, BOARD_H - length - 2)
        for y in range(start_y, start_y + length):
            gallery.append(Vector2i(x, y))
    return gallery


func _gallery_is_clear(gallery: Array) -> bool:
    for pos in gallery:
        if not _in_bounds(pos):
            return false
        if pos == exit_pos or pos.distance_squared_to(player_pos) < 36:
            return false
        if _tile(pos) != TILE_DIRT:
            return false
        for dir in DIRS:
            var neighbor: Vector2i = pos + dir
            if _in_bounds(neighbor) and _tile(neighbor) != TILE_DIRT and not gallery.has(neighbor):
                return false
    return true


func _place_rocks(count: int) -> void:
    var attempts := 0
    while rocks.size() < count and attempts < 800:
        attempts += 1
        var pos := Vector2i(rng.randi_range(1, BOARD_W - 2), rng.randi_range(3, BOARD_H - 3))
        if _tile(pos) != TILE_DIRT:
            continue
        if _has_rock(pos) or pos.distance_squared_to(player_pos) < 25:
            continue
        if rng.randf() < 0.62 and _tile(pos + Vector2i.DOWN) == TILE_DIRT:
            continue
        _add_rock(pos)


func _add_rock(pos: Vector2i) -> void:
    rocks.append({
        "pos": pos,
        "visual_pos": _visual_from_pos(pos),
        "falling": false,
        "timer": ROCK_LOOSE_DELAY,
        "fall_distance": 0
    })


func _place_gems(count: int) -> void:
    var attempts := 0
    while gems.size() < count and attempts < 1000:
        attempts += 1
        var pos := Vector2i(rng.randi_range(1, BOARD_W - 2), rng.randi_range(2, BOARD_H - 2))
        if pos == player_pos or pos == exit_pos or _has_gem(pos):
            continue
        if _has_rock(pos):
            continue
        if rng.randf() < 0.65 and (_tile(pos) != TILE_DIRT or _adjacent_tunnel_count(pos) == 0):
            continue
        gems.append(pos)


func _place_floor_relics(count: int) -> void:
    var pool := _available_upgrade_pool()
    pool.shuffle()
    var attempts := 0
    while floor_relics.size() < count and attempts < 900:
        attempts += 1
        var pos := Vector2i(rng.randi_range(2, BOARD_W - 3), rng.randi_range(3, BOARD_H - 3))
        if pos == player_pos or pos == exit_pos or _has_rock(pos) or _has_gem(pos) or _has_relic(pos):
            continue
        if rng.randf() < 0.75 and _adjacent_tunnel_count(pos) == 0:
            continue
        var relic: Dictionary = pool[floor_relics.size() % pool.size()].duplicate()
        relic["pos"] = pos
        relic["buried"] = _tile(pos) == TILE_DIRT
        floor_relics.append(relic)


func _place_enemies(count: int, spawn_cells := []) -> void:
    var candidates := spawn_cells.duplicate()
    candidates.shuffle()
    for candidate in candidates:
        if enemies.size() >= count:
            return
        var spawn_pos: Vector2i = candidate
        if _tile(spawn_pos) != TILE_TUNNEL:
            continue
        if spawn_pos.distance_squared_to(player_pos) < 45 or spawn_pos == exit_pos or _enemy_index_at(spawn_pos) != -1:
            continue
        _add_enemy(spawn_pos)

    var attempts := 0
    while enemies.size() < count and attempts < 1000:
        attempts += 1
        var pos := Vector2i(rng.randi_range(2, BOARD_W - 3), rng.randi_range(3, BOARD_H - 3))
        if _tile(pos) != TILE_TUNNEL:
            continue
        if pos.distance_squared_to(player_pos) < 45 or pos == exit_pos or _enemy_index_at(pos) != -1:
            continue
        _add_enemy(pos)


func _add_enemy(pos: Vector2i) -> void:
    var kind := ENEMY_GRUB_KIND
    if floor_index >= FYGAR_MIN_FLOOR and rng.randf() < minf(0.16 + float(floor_index) * 0.025, 0.34):
        kind = ENEMY_FYGAR_KIND
    elif floor_index >= 3 and rng.randf() < 0.28:
        kind = ENEMY_BURROWER_KIND
    var enemy_hp := 2 + floori(float(floor_index) / 3.0)
    enemies.append({
        "pos": pos,
        "visual_pos": _visual_from_pos(pos),
        "kind": kind,
        "hp": enemy_hp,
        "max_hp": enemy_hp,
        "visual_speed": _enemy_move_speed_for_kind(kind),
        "inflated": false,
        "recover_timer": ENEMY_INFLATE_RECOVER_DELAY,
        "stun": 0.0,
        "hit_flash": 0.0,
        "timer": rng.randf_range(0.1, 0.6),
        "phasing": false,
        "phase_target": pos,
        "phase_cooldown": rng.randf_range(PHASE_COOLDOWN_MIN, PHASE_COOLDOWN_MAX),
        "phase_steps": 0,
        "stuck_steps": 0,
        "fire_cooldown": rng.randf_range(FYGAR_FIRE_COOLDOWN_MIN, FYGAR_FIRE_COOLDOWN_MAX),
        "fire_windup": 0.0,
        "fire_active": 0.0,
        "fire_dir": Vector2i.RIGHT,
        "attack_windup": 0.0,
        "attack_dir": Vector2i.ZERO
    })


func _process(delta: float) -> void:
    anim_time += delta
    hurt_flash = maxf(0.0, hurt_flash - delta)
    attack_flash = maxf(0.0, attack_flash - delta)
    player_step_squash = maxf(0.0, player_step_squash - delta)
    screen_shake = maxf(0.0, screen_shake - delta)
    screen_shake_offset = Vector2.ZERO
    if screen_shake > 0.0:
        screen_shake_offset = Vector2(rng.randf_range(-screen_shake, screen_shake), rng.randf_range(-screen_shake, screen_shake)) * 12.0
    if combo_timer > 0.0:
        combo_timer = maxf(0.0, combo_timer - delta)
        if combo_timer <= 0.0:
            combo_count = 0
    _update_feedback(delta)
    if attack_flash <= 0.0 and not lance_active:
        last_attack_cells.clear()

    if state != STATE_PLAYING:
        if lance_active:
            _release_lance(false)
        _update_visual_positions(delta)
        queue_redraw()
        return

    move_cooldown = maxf(0.0, move_cooldown - delta)
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    run_time += delta
    floor_index = 1 + floori(run_time / 60.0)

    if lance_active:
        _update_lance(delta)

    _update_player_motion(delta, _read_move_dir())

    _update_spawning(delta)
    _update_enemies(delta)
    _update_rock_spawning(delta)
    _update_rocks(delta)
    _update_xp_pickups(delta)
    _update_tunnel_regrowth(delta)

    if run_time >= RUN_GOAL_TIME and not exit_unlocked:
        exit_unlocked = true
        message = "The extraction gate hums open. Reach it and press E."

    _update_visual_positions(delta)
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    if not event.pressed or event.echo:
        return

    if event.keycode == KEY_R:
        _new_run()
        return

    if state == STATE_PLAYING:
        if event.keycode == KEY_SPACE:
            _start_lance()
        elif event.keycode == KEY_E or event.keycode == KEY_ENTER:
            _try_interact()
    elif state == STATE_CHOOSING:
        if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
            _choose_upgrade(0)
        elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
            _choose_upgrade(1)
        elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
            _choose_upgrade(2)
        elif event.keycode == KEY_0 or event.keycode == KEY_KP_0 or event.keycode == KEY_E or event.keycode == KEY_ENTER:
            _skip_upgrade_shop()
    elif state == STATE_GAME_OVER or state == STATE_WIN:
        if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
            _new_run()


func _read_move_dir() -> Vector2i:
    if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
        return Vector2i.LEFT
    if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
        return Vector2i.RIGHT
    if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
        return Vector2i.UP
    if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
        return Vector2i.DOWN
    return Vector2i.ZERO


func _update_player_motion(delta: float, input_dir: Vector2i) -> void:
    if attack_flash > 0.0 or lance_active:
        player_move_dir = Vector2i.ZERO
        player_target_digging = false
        player_digging = false
        return

    if input_dir == Vector2i.ZERO:
        player_move_dir = Vector2i.ZERO
        player_target_digging = false
        player_digging = false
        return

    facing = input_dir
    _sync_player_cell_from_visual()
    _choose_player_target(input_dir)
    if player_move_dir == Vector2i.ZERO:
        player_digging = false
        return

    player_digging = player_target_digging
    var from := player_visual_pos
    var target_visual := _visual_from_pos(player_target_cell)
    var next := from.move_toward(target_visual, _player_motion_speed() * delta)
    if not _visual_in_bounds(next):
        player_move_dir = Vector2i.ZERO
        player_target_digging = false
        player_digging = false
        return

    if _has_rock(player_target_cell):
        player_move_dir = Vector2i.ZERO
        player_target_digging = false
        player_digging = false
        return

    var enemy_i := _solid_enemy_index_at(player_target_cell)
    if enemy_i != -1 and player_target_cell != player_pos:
        _hurt_player(1)
        player_move_dir = Vector2i.ZERO
        player_target_digging = false
        player_digging = false
        return

    player_visual_pos = next
    player_digging = player_target_digging
    player_step_squash = 0.30 if player_digging else 0.12
    if player_digging:
        _dig_player_body_path(from, player_visual_pos)
    else:
        _add_dig_segment(from, player_visual_pos)

    var reached_target := player_visual_pos.distance_to(target_visual) <= PLAYER_CENTER_EPS
    _sync_player_cell_from_visual()
    if reached_target:
        player_visual_pos = target_visual
        player_pos = player_target_cell
        player_step_from = player_pos
        player_target_digging = false
        _collect_gem_at(player_pos)
        _collect_relic_at(player_pos)


func _choose_player_target(requested_dir: Vector2i) -> void:
    var target_visual := _visual_from_pos(player_target_cell)
    var distance_to_target := player_visual_pos.distance_to(target_visual)
    var target_dir := _direction_toward_visual_target()

    if target_dir != Vector2i.ZERO and requested_dir == -target_dir:
        var reverse_target := _cell_from_visual(player_visual_pos + Vector2(requested_dir) * 0.5)
        if _begin_player_target(reverse_target, requested_dir):
            return

    if target_dir != Vector2i.ZERO and distance_to_target > PLAYER_TARGET_GATE:
        player_move_dir = target_dir
        return

    var next_target := player_pos + requested_dir
    if _begin_player_target(next_target, requested_dir):
        return

    if target_dir != Vector2i.ZERO:
        player_move_dir = target_dir
    else:
        player_move_dir = Vector2i.ZERO
        player_target_digging = false


func _begin_player_target(target: Vector2i, dir: Vector2i) -> bool:
    if not _can_player_enter_cell(target):
        return false
    player_target_cell = target
    player_move_dir = dir
    facing = player_move_dir
    player_step_from = player_pos

    var was_dirt := _tile(target) == TILE_DIRT
    player_target_digging = was_dirt
    if was_dirt:
        player_dug_cells[target] = 0.0
    return true


func _direction_toward_visual_target() -> Vector2i:
    var delta := _visual_from_pos(player_target_cell) - player_visual_pos
    if delta.length() <= PLAYER_CENTER_EPS:
        return Vector2i.ZERO
    if absf(delta.x) >= absf(delta.y):
        return Vector2i(1 if delta.x > 0.0 else -1, 0)
    return Vector2i(0, 1 if delta.y > 0.0 else -1)


func _sync_player_cell_from_visual() -> void:
    var visual_cell := _cell_from_visual(player_visual_pos)
    if visual_cell == player_pos:
        return
    player_pos = visual_cell
    _collect_gem_at(player_pos)
    _collect_relic_at(player_pos)


func _can_player_enter_cell(cell: Vector2i) -> bool:
    if not _in_bounds(cell):
        return false
    if _has_rock(cell):
        return false
    var enemy_i := _solid_enemy_index_at(cell)
    return enemy_i == -1 or cell == player_pos


func _player_motion_speed() -> float:
    var delay := move_delay
    if player_digging:
        delay *= dig_delay_mult
        var momentum := _effective_tunnel_momentum()
        if momentum > 0:
            delay *= maxf(0.64, 1.0 - float(momentum) * 0.08)
    return 1.0 / maxf(delay, 0.001)


func _player_align_speed() -> float:
    return maxf(_player_motion_speed() * 1.65, 12.0)


func _try_interact() -> void:
    if player_pos == exit_pos and exit_unlocked:
        _award_floor_bonus()
        state = STATE_WIN
        message = "You escaped with a pack full of strange gems."
    else:
        message = "The gate opens after %s." % _format_time(RUN_GOAL_TIME)


func _award_floor_bonus() -> void:
    var bonus := 80 + floor_index * 30
    var parts := ["Clear +%d" % bonus]
    if floor_damage_taken == 0:
        var perfect := 70 + floor_index * 20
        bonus += perfect
        gem_bank += 1
        parts.append("Perfect +%d +1 gem" % perfect)
    if floor_gems_available > 0 and floor_gems_collected >= floor_gems_available:
        var sweep := 120 + floor_index * 25
        bonus += sweep
        gem_bank += 2
        parts.append("Gem sweep +%d +2 gems" % sweep)
    if floor_relics_found > 0:
        var relic_bonus := floor_relics_found * 90
        bonus += relic_bonus
        parts.append("Relics +%d" % relic_bonus)
    if floor_boulder_kills >= 2:
        var rock_bonus := floor_boulder_kills * 70
        bonus += rock_bonus
        gem_bank += 1
        parts.append("Rock plan +%d +1 gem" % rock_bonus)
    if best_combo >= 4:
        var combo_bonus := best_combo * 35
        bonus += combo_bonus
        parts.append("Best x%d +%d" % [best_combo, combo_bonus])
    score += bonus
    last_floor_summary = _join_strings(parts, " | ")


func _start_lance() -> void:
    if lance_active or attack_cooldown > 0.0:
        return
    lance_active = true
    lance_attached_enemy = -1
    lance_blocking_cell = Vector2i.ZERO
    lance_has_blocker = false
    lance_pump_timer = LANCE_HIT_DELAY
    attack_flash = ATTACK_FLASH_TIME
    last_attack_cells.clear()
    message = ""
    lance_burst_ready = false
    lance_has_struck = false
    lance_pump_damage = _effective_lance_damage()
    if crystal_charge > 0:
        lance_burst_ready = true
        lance_pump_damage += 1
        crystal_charge -= 1
        message = "Crystal pressure primed."

    for step in range(1, _effective_lance_range() + 1):
        var pos := player_pos + facing * step
        if not _in_bounds(pos):
            break
        if not _open_line_between_cells(player_pos, pos):
            _add_pressure_feedback(pos, 0.75)
            break
        last_attack_cells.append(pos)
        if _has_rock(pos):
            _add_pressure_feedback(pos, 1.0)
            break
        var enemy_i := _enemy_index_at(pos)
        if enemy_i != -1:
            lance_attached_enemy = enemy_i
            lance_blocking_cell = pos
            lance_has_blocker = true
            _pin_lance_target()
            _add_pressure_feedback(pos, 1.0)
            return
        if _tile(pos) == TILE_DIRT:
            _add_pressure_feedback(pos, 0.75)
            break


func _update_lance(delta: float) -> void:
    if not Input.is_key_pressed(KEY_SPACE):
        _release_lance()
        return

    lance_pump_timer -= delta
    if not lance_has_struck:
        if lance_attached_enemy != -1 and not _pin_lance_target():
            _release_lance()
            return
        if lance_pump_timer <= 0.0:
            lance_has_struck = true
            if lance_attached_enemy != -1:
                lance_pump_timer = LANCE_PUMP_INTERVAL
                _pump_lance_target()
            else:
                lance_pump_timer = LANCE_RETRACT_DELAY
                _shake(0.08)
        return

    if lance_attached_enemy == -1:
        if lance_pump_timer <= 0.0:
            _release_lance()
        return

    if not _pin_lance_target():
        _release_lance()
        return

    if lance_pump_timer <= 0.0:
        lance_pump_timer = LANCE_PUMP_INTERVAL
        _pump_lance_target()


func _update_spawning(delta: float) -> void:
    spawn_timer -= delta
    if spawn_timer > 0.0:
        return
    spawn_timer = _spawn_interval()
    var cap := _spawn_cap()
    if enemies.size() >= cap:
        return
    var burst := mini(rng.randi_range(SPAWN_BURST_MIN, SPAWN_BURST_MAX), cap - enemies.size())
    for i in range(burst):
        _spawn_survival_enemy()


func _spawn_interval() -> float:
    var pressure := clampf(run_time / RUN_GOAL_TIME, 0.0, 1.0)
    return lerpf(SPAWN_INTERVAL_MAX, SPAWN_INTERVAL_MIN, pressure)


func _spawn_cap() -> int:
    return SPAWN_CAP_BASE + floori(run_time / 45.0) * SPAWN_CAP_GROWTH


func _spawn_survival_enemy() -> void:
    var connected := _connected_tunnel_cells(player_pos)
    var best := Vector2i.ZERO
    var best_score := -999999.0

    for cell in connected:
        var pos: Vector2i = cell
        if not _can_spawn_enemy_at(pos):
            continue
        var distance_sq: int = pos.distance_squared_to(player_pos)
        if distance_sq < 25:
            continue
        var edge_bonus := maxf(absf(float(pos.x) - float(BOARD_W) * 0.5), absf(float(pos.y) - float(BOARD_H) * 0.5))
        var score_value := float(distance_sq) + edge_bonus * 3.0 + rng.randf_range(0.0, 25.0)
        if score_value > best_score:
            best_score = score_value
            best = pos

    if best_score < 0.0:
        for cell in connected:
            var pos: Vector2i = cell
            for dir in DIRS:
                var breach: Vector2i = pos + dir
                if not _can_spawn_enemy_breach_at(breach):
                    continue
                var distance_sq: int = breach.distance_squared_to(player_pos)
                if distance_sq < 36:
                    continue
                var score_value := float(distance_sq) + rng.randf_range(0.0, 18.0)
                if score_value > best_score:
                    best_score = score_value
                    best = breach

    if best_score < 0.0:
        return
    if _tile(best) == TILE_DIRT:
        _carve_cell(best)
        _add_dig_feedback(best)
    _add_enemy(best)


func _can_spawn_enemy_at(pos: Vector2i) -> bool:
    if not _in_bounds(pos):
        return false
    if pos == player_pos or pos == player_target_cell or pos == exit_pos:
        return false
    if _tile(pos) != TILE_TUNNEL and _tile(pos) != TILE_EXIT:
        return false
    if _has_rock(pos) or _enemy_index_at(pos) != -1:
        return false
    return true


func _can_spawn_enemy_breach_at(pos: Vector2i) -> bool:
    if not _in_bounds(pos):
        return false
    if pos == player_pos or pos == player_target_cell or pos == exit_pos:
        return false
    if _tile(pos) != TILE_DIRT:
        return false
    if _has_rock(pos) or _enemy_index_at(pos) != -1:
        return false
    return _adjacent_tunnel_count(pos) > 0


func _connected_tunnel_cells(start: Vector2i) -> Array:
    var cells: Array[Vector2i] = []
    if not _in_bounds(start):
        return cells
    if _tile(start) != TILE_TUNNEL and _tile(start) != TILE_EXIT:
        return cells

    var queue: Array[Vector2i] = [start]
    var visited := {start: true}
    var cursor := 0

    while cursor < queue.size():
        var pos: Vector2i = queue[cursor]
        cursor += 1
        cells.append(pos)
        for dir in DIRS:
            var next: Vector2i = pos + dir
            if visited.has(next) or not _in_bounds(next):
                continue
            if _has_rock(next):
                continue
            if _tile(next) != TILE_TUNNEL and _tile(next) != TILE_EXIT:
                continue
            visited[next] = true
            queue.append(next)

    return cells


func _update_rock_spawning(delta: float) -> void:
    rock_spawn_timer -= delta
    if rock_spawn_timer > 0.0:
        return
    rock_spawn_timer = _rock_spawn_interval()
    if rocks.size() >= _rock_cap():
        return
    _spawn_survival_rock()


func _rock_spawn_interval() -> float:
    var pressure := clampf(run_time / RUN_GOAL_TIME, 0.0, 1.0)
    return lerpf(ROCK_SPAWN_INTERVAL_MAX, ROCK_SPAWN_INTERVAL_MIN, pressure)


func _rock_cap() -> int:
    return ROCK_CAP_BASE + floori(run_time / 90.0) * ROCK_CAP_GROWTH


func _spawn_survival_rock() -> void:
    var best := Vector2i.ZERO
    var best_score := -999999.0
    for attempt in range(120):
        var pos := Vector2i(rng.randi_range(1, BOARD_W - 2), rng.randi_range(2, BOARD_H - 3))
        if not _can_spawn_rock_at(pos):
            continue
        var below := pos + Vector2i.DOWN
        var open_neighbors := _adjacent_tunnel_count(below)
        var distance := sqrt(float(pos.distance_squared_to(player_pos)))
        var score_value := float(open_neighbors) * 18.0 + distance * 2.0 + rng.randf_range(0.0, 18.0)
        if _tile(below) == TILE_TUNNEL:
            score_value += 28.0
        if score_value > best_score:
            best_score = score_value
            best = pos
    if best_score < 0.0:
        return
    _add_rock(best)
    _add_cell_pulse(best, ROCK, PULSE_FEEDBACK_TIME + 0.16, 1.0, true)
    if combo_count < 2 and rng.randf() < 0.35:
        message = "The cave is growing new boulders."


func _can_spawn_rock_at(pos: Vector2i) -> bool:
    if not _in_bounds(pos) or not _in_bounds(pos + Vector2i.DOWN):
        return false
    if _tile(pos) != TILE_DIRT:
        return false
    if _tile(pos + Vector2i.DOWN) == TILE_DIRT:
        return false
    if pos.distance_squared_to(player_pos) < ROCK_SPAWN_SAFE_RADIUS * ROCK_SPAWN_SAFE_RADIUS:
        return false
    if pos == exit_pos or pos + Vector2i.DOWN == exit_pos:
        return false
    if _has_rock(pos) or _has_rock(pos + Vector2i.DOWN):
        return false
    if _has_gem(pos) or _has_relic(pos) or _enemy_index_at(pos) != -1 or _enemy_index_at(pos + Vector2i.DOWN) != -1:
        return false
    return true


func _release_lance(start_recovery := true) -> void:
    lance_active = false
    lance_attached_enemy = -1
    lance_blocking_cell = Vector2i.ZERO
    lance_has_blocker = false
    lance_pump_timer = 0.0
    lance_burst_ready = false
    lance_has_struck = false
    attack_flash = 0.0
    last_attack_cells.clear()
    if start_recovery:
        attack_cooldown = ATTACK_RECOVERY_DELAY


func _pin_lance_target() -> bool:
    if lance_attached_enemy < 0 or lance_attached_enemy >= enemies.size():
        return false
    var enemy: Dictionary = enemies[lance_attached_enemy]
    if enemy["phasing"]:
        enemy["phasing"] = false
        enemy["phase_steps"] = 0
    enemy["attack_windup"] = 0.0
    enemy["attack_dir"] = Vector2i.ZERO
    enemy["inflated"] = true
    enemy["recover_timer"] = ENEMY_INFLATE_RECOVER_DELAY
    enemy["stun"] = maxf(float(enemy["stun"]), LANCE_HOLD_STUN)
    return true


func _pump_lance_target() -> void:
    if lance_attached_enemy < 0 or lance_attached_enemy >= enemies.size():
        _release_lance()
        return
    var enemy_pos: Vector2i = enemies[lance_attached_enemy]["pos"]
    var alive := _inflate_lance_target(lance_attached_enemy, lance_pump_damage)
    _add_pressure_feedback(enemy_pos, 1.0)
    if lance_burst_ready or _lance_overdrive():
        _trigger_lance_splash(enemy_pos, facing, lance_pump_damage)
        _trigger_pressure_wave(enemy_pos, lance_pump_damage)
        lance_burst_ready = false
    if not alive:
        _release_lance()


func _inflate_lance_target(enemy_i: int, amount: int) -> bool:
    if enemy_i < 0 or enemy_i >= enemies.size():
        return false
    var enemy: Dictionary = enemies[enemy_i]
    enemy["inflated"] = true
    enemy["recover_timer"] = ENEMY_INFLATE_RECOVER_DELAY
    enemy["phasing"] = false
    enemy["phase_steps"] = 0
    enemy["attack_windup"] = 0.0
    enemy["attack_dir"] = Vector2i.ZERO
    enemy["fire_windup"] = 0.0
    enemy["fire_active"] = 0.0
    enemy["hit_flash"] = ENEMY_HIT_FLASH
    enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), LANCE_HOLD_STUN)
    enemy["hp"] -= amount
    if enemy["hp"] <= 0:
        var dead_pos: Vector2i = enemy["pos"]
        var dead_kind := int(enemy.get("kind", ENEMY_GRUB_KIND))
        floor_kills += 1
        _award_score(80 + floor_index * 10, true, "Rupture")
        enemies.remove_at(enemy_i)
        _drop_xp(dead_pos, 1 + dead_kind)
        _add_rupture_feedback(dead_pos)
        _shake(0.16)
        message = "Pressure burst!"
        return false
    _shake(0.06)
    message = "Pumping."
    return true


func _update_enemies(delta: float) -> void:
    for enemy in enemies:
        enemy["hit_flash"] = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
        if _update_inflated_enemy(enemy, delta):
            continue
        if enemy["phasing"]:
            _update_enemy_phase_chase(enemy, delta)
            continue
        if enemy["stun"] > 0.0:
            enemy["stun"] = maxf(0.0, enemy["stun"] - delta)
            enemy["fire_windup"] = 0.0
            enemy["fire_active"] = 0.0
            enemy["attack_windup"] = 0.0
            enemy["attack_dir"] = Vector2i.ZERO
            continue
        if _update_enemy_melee(enemy, delta):
            continue
        if _update_enemy_fire(enemy, delta):
            continue
        if int(enemy.get("kind", 0)) == ENEMY_GRUB_KIND and floor_index >= PHASE_MIN_FLOOR:
            enemy["phase_cooldown"] = maxf(0.0, float(enemy.get("phase_cooldown", 0.0)) - delta)
        enemy["timer"] -= delta
        if enemy["timer"] > 0.0:
            continue
        enemy["timer"] = _enemy_step_delay(enemy)
        _step_enemy(enemy)


func _update_inflated_enemy(enemy: Dictionary, delta: float) -> bool:
    if not bool(enemy.get("inflated", false)):
        return false

    enemy["phasing"] = false
    enemy["phase_steps"] = 0
    enemy["fire_windup"] = 0.0
    enemy["fire_active"] = 0.0
    enemy["attack_windup"] = 0.0
    enemy["attack_dir"] = Vector2i.ZERO
    enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), LANCE_HOLD_STUN)

    if _is_enemy_lance_target(enemy):
        enemy["recover_timer"] = ENEMY_INFLATE_RECOVER_DELAY
        return true

    enemy["recover_timer"] = float(enemy.get("recover_timer", ENEMY_INFLATE_RECOVER_DELAY)) - delta
    if float(enemy["recover_timer"]) <= 0.0:
        enemy["recover_timer"] = ENEMY_INFLATE_RECOVER_DELAY
        enemy["hp"] = mini(int(enemy.get("max_hp", enemy["hp"])), int(enemy["hp"]) + 1)
        enemy["hit_flash"] = ENEMY_HIT_FLASH * 0.45
        if int(enemy["hp"]) >= int(enemy.get("max_hp", enemy["hp"])):
            enemy["inflated"] = false
            enemy["stun"] = 0.0
    return true


func _is_enemy_lance_target(enemy: Dictionary) -> bool:
    return lance_active and lance_attached_enemy >= 0 and lance_attached_enemy < enemies.size() and enemies[lance_attached_enemy] == enemy


func _should_enemy_phase(enemy: Dictionary) -> bool:
    if int(enemy.get("kind", 0)) != ENEMY_GRUB_KIND:
        return false
    var pos: Vector2i = enemy["pos"]
    if _tile(pos) == TILE_DIRT:
        return false
    var player_distance_sq := pos.distance_squared_to(player_pos)
    if player_distance_sq <= 1:
        return false
    return _enemy_phase_target(enemy) != pos


func _begin_enemy_phase(enemy: Dictionary) -> void:
    var target := _enemy_phase_target(enemy)
    if target == enemy["pos"]:
        enemy["phase_cooldown"] = rng.randf_range(PHASE_COOLDOWN_MIN, PHASE_COOLDOWN_MAX)
        return
    enemy["phasing"] = true
    enemy["phase_target"] = target
    enemy["phase_steps"] = 1
    enemy["timer"] = 0.0
    enemy["visual_speed"] = _enemy_move_speed(enemy)
    enemy["phase_cooldown"] = rng.randf_range(PHASE_COOLDOWN_MIN, PHASE_COOLDOWN_MAX)


func _enemy_phase_target(enemy: Dictionary) -> Vector2i:
    var pos: Vector2i = enemy["pos"]
    var dirs := DIRS.duplicate()
    dirs.shuffle()
    dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return (pos + a).distance_squared_to(player_pos) < (pos + b).distance_squared_to(player_pos)
    )

    for dir in dirs:
        var target: Vector2i = pos + dir
        if not _can_enemy_squeeze_to(target):
            continue
        if target.distance_squared_to(player_pos) >= pos.distance_squared_to(player_pos):
            continue
        return target
    return pos


func _can_enemy_squeeze_to(target: Vector2i) -> bool:
    if not _in_bounds(target) or _has_rock(target):
        return false
    if _tile(target) != TILE_DIRT:
        return false
    if _solid_enemy_index_at(target) != -1 or target == player_pos or target == player_target_cell:
        return false
    return _adjacent_tunnel_count(target) >= PHASE_THIN_WALL_TUNNEL_NEIGHBORS


func _update_enemy_phase_chase(enemy: Dictionary, delta: float) -> void:
    var target: Vector2i = enemy.get("phase_target", enemy["pos"])
    if not _can_enemy_squeeze_to(target):
        _end_enemy_phase(enemy)
        return
    var target_visual := _visual_from_pos(target)
    enemy["visual_pos"] = _dict_visual(enemy).move_toward(target_visual, _enemy_move_speed(enemy) * delta)
    enemy["attack_windup"] = 0.0
    enemy["attack_dir"] = Vector2i.ZERO
    enemy["fire_windup"] = 0.0
    enemy["fire_active"] = 0.0

    if _dict_visual(enemy).distance_to(target_visual) <= PLAYER_CENTER_EPS:
        enemy["visual_pos"] = target_visual
        _carve_cell(target)
        _add_dig_feedback(target)
        _eat_gem_at(target)
        enemy["pos"] = target
        _end_enemy_phase(enemy)


func _update_enemy_fire(enemy: Dictionary, delta: float) -> bool:
    if int(enemy.get("kind", 0)) != ENEMY_FYGAR_KIND:
        return false
    enemy["fire_cooldown"] = maxf(0.0, float(enemy.get("fire_cooldown", 0.0)) - delta)
    if float(enemy.get("fire_windup", 0.0)) > 0.0:
        enemy["fire_windup"] = maxf(0.0, float(enemy["fire_windup"]) - delta)
        if float(enemy["fire_windup"]) <= 0.0:
            enemy["fire_active"] = FYGAR_FIRE_ACTIVE
            _shake(0.14)
        return true
    if float(enemy.get("fire_active", 0.0)) > 0.0:
        enemy["fire_active"] = maxf(0.0, float(enemy["fire_active"]) - delta)
        if _player_in_fire_lane(enemy):
            _hurt_player(1)
        if float(enemy["fire_active"]) <= 0.0:
            enemy["fire_cooldown"] = rng.randf_range(FYGAR_FIRE_COOLDOWN_MIN, FYGAR_FIRE_COOLDOWN_MAX)
        return true
    return false


func _update_enemy_melee(enemy: Dictionary, delta: float) -> bool:
    var windup := float(enemy.get("attack_windup", 0.0))
    if windup <= 0.0:
        return false

    windup = maxf(0.0, windup - delta)
    enemy["attack_windup"] = windup
    if windup > 0.0:
        return true

    var pos: Vector2i = enemy["pos"]
    var dir: Vector2i = enemy.get("attack_dir", Vector2i.ZERO)
    if dir != Vector2i.ZERO and player_pos == pos + dir and _open_line_between_cells(pos, player_pos):
        _hurt_player(1)
    enemy["attack_dir"] = Vector2i.ZERO
    return true


func _begin_enemy_melee(enemy: Dictionary, dir: Vector2i) -> void:
    if dir == Vector2i.ZERO or float(enemy.get("attack_windup", 0.0)) > 0.0:
        return
    var pos: Vector2i = enemy["pos"]
    if not _open_line_between_cells(pos, pos + dir):
        return
    enemy["attack_dir"] = dir
    enemy["attack_windup"] = ENEMY_ATTACK_WARN
    enemy["fire_windup"] = 0.0
    enemy["fire_active"] = 0.0
    message = "Enemy lunge!"


func _try_begin_fire(enemy: Dictionary) -> bool:
    if float(enemy.get("fire_cooldown", 0.0)) > 0.0:
        return false
    var pos: Vector2i = enemy["pos"]
    if player_pos.y != pos.y:
        return false
    var dx := player_pos.x - pos.x
    if dx == 0 or abs(dx) > FYGAR_FIRE_RANGE:
        return false
    var dir := Vector2i(signi(dx), 0)
    if not _line_clear_for_fire(pos, dir, abs(dx)):
        return false
    enemy["fire_dir"] = dir
    enemy["fire_windup"] = FYGAR_FIRE_WARN
    enemy["timer"] = FYGAR_FIRE_WARN + FYGAR_FIRE_ACTIVE
    message = "Fire lane!"
    return true


func _line_clear_for_fire(start: Vector2i, dir: Vector2i, distance: int) -> bool:
    var previous := start
    for step in range(1, distance + 1):
        var pos := start + dir * step
        if not _in_bounds(pos) or _tile(pos) == TILE_DIRT or _has_rock(pos):
            return false
        if not _open_line_between_cells(previous, pos):
            return false
        previous = pos
    return true


func _player_in_fire_lane(enemy: Dictionary) -> bool:
    var pos: Vector2i = enemy["pos"]
    var dir: Vector2i = enemy.get("fire_dir", Vector2i.RIGHT)
    if player_pos.y != pos.y:
        return false
    var dx := player_pos.x - pos.x
    if dx == 0 or signi(dx) != dir.x or abs(dx) > FYGAR_FIRE_RANGE:
        return false
    return _line_clear_for_fire(pos, dir, abs(dx))


func _enemy_fire_cells(enemy: Dictionary) -> Array:
    var cells := []
    if int(enemy.get("kind", 0)) != ENEMY_FYGAR_KIND:
        return cells
    if float(enemy.get("fire_windup", 0.0)) <= 0.0 and float(enemy.get("fire_active", 0.0)) <= 0.0:
        return cells
    var pos: Vector2i = enemy["pos"]
    var dir: Vector2i = enemy.get("fire_dir", Vector2i.RIGHT)
    for step in range(1, FYGAR_FIRE_RANGE + 1):
        var cell := pos + dir * step
        if not _in_bounds(cell) or _tile(cell) == TILE_DIRT or _has_rock(cell):
            break
        cells.append(cell)
    return cells


func _enemy_path_dir(start: Vector2i, goal: Vector2i) -> Vector2i:
    if start == goal:
        return Vector2i.ZERO
    if not _can_enemy_path_cell(goal, start, goal):
        return Vector2i.ZERO

    var queue: Array[Vector2i] = [start]
    var visited := {start: true}
    var first_dirs := {}
    var cursor := 0

    while cursor < queue.size():
        var pos: Vector2i = queue[cursor]
        cursor += 1

        var dirs := DIRS.duplicate()
        dirs.shuffle()
        dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
            return (pos + a).distance_squared_to(goal) < (pos + b).distance_squared_to(goal)
        )

        for dir in dirs:
            var next: Vector2i = pos + dir
            if visited.has(next) or not _can_enemy_path_cell(next, start, goal):
                continue
            var first_dir: Vector2i = dir if pos == start else first_dirs[pos]
            if next == goal:
                return first_dir
            visited[next] = true
            first_dirs[next] = first_dir
            queue.append(next)

    return Vector2i.ZERO


func _can_enemy_path_cell(pos: Vector2i, start: Vector2i, goal: Vector2i) -> bool:
    if not _in_bounds(pos) or _has_rock(pos):
        return false
    if _tile(pos) != TILE_TUNNEL and _tile(pos) != TILE_EXIT:
        return false
    if pos != start and pos != goal and _solid_enemy_index_at(pos) != -1:
        return false
    return true


func _enemy_fallback_tunnel_dir(pos: Vector2i) -> Vector2i:
    var dirs := DIRS.duplicate()
    dirs.shuffle()
    dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return (pos + a).distance_squared_to(player_pos) < (pos + b).distance_squared_to(player_pos)
    )
    for dir in dirs:
        var target: Vector2i = pos + dir
        if _can_enemy_path_cell(target, pos, player_pos):
            return dir
    return Vector2i.ZERO


func _step_enemy(enemy: Dictionary) -> void:
    if int(enemy.get("kind", 0)) == ENEMY_BURROWER_KIND:
        _step_burrower(enemy)
        return
    if int(enemy.get("kind", 0)) == ENEMY_FYGAR_KIND and _try_begin_fire(enemy):
        return

    var pos: Vector2i = enemy["pos"]
    if pos.distance_squared_to(player_pos) == 1:
        _begin_enemy_melee(enemy, player_pos - pos)
        return

    var path_dir := _enemy_path_dir(pos, player_pos)
    if path_dir != Vector2i.ZERO:
        enemy["stuck_steps"] = 0
        _move_enemy_to(enemy, pos + path_dir)
        return

    enemy["stuck_steps"] = int(enemy.get("stuck_steps", 0)) + 1
    var fallback_dir := _enemy_fallback_tunnel_dir(pos)
    if fallback_dir != Vector2i.ZERO:
        _move_enemy_to(enemy, pos + fallback_dir)

    if int(enemy.get("kind", 0)) == ENEMY_GRUB_KIND and floor_index >= PHASE_MIN_FLOOR and int(enemy.get("stuck_steps", 0)) >= ENEMY_STUCK_STEPS_TO_SQUEEZE and float(enemy.get("phase_cooldown", 0.0)) <= 0.0:
        _begin_enemy_phase(enemy)


func _step_burrower(enemy: Dictionary) -> void:
    var pos: Vector2i = enemy["pos"]
    if pos.distance_squared_to(player_pos) == 1:
        _begin_enemy_melee(enemy, player_pos - pos)
        return

    var dirs := DIRS.duplicate()
    dirs.shuffle()
    dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        return (pos + a).distance_squared_to(player_pos) < (pos + b).distance_squared_to(player_pos)
    )

    for dir in dirs:
        var target: Vector2i = pos + dir
        if not _in_bounds(target) or _has_rock(target):
            continue
        if target == player_pos:
            _begin_enemy_melee(enemy, dir)
            return
        if _tile(target) == TILE_DIRT:
            _carve_cell(target)
            _add_dig_feedback(target)
            _eat_gem_at(target)
            _move_enemy_to(enemy, target, true)
            return
        if _tile(target) == TILE_TUNNEL or _tile(target) == TILE_EXIT:
            _eat_gem_at(target)
            _move_enemy_to(enemy, target)
            return

func _end_enemy_phase(enemy: Dictionary) -> void:
    enemy["phasing"] = false
    enemy["timer"] = _enemy_step_delay(enemy)
    enemy["phase_steps"] = 0
    if _enemy_path_dir(enemy["pos"], player_pos) == Vector2i.ZERO:
        enemy["stuck_steps"] = ENEMY_STUCK_STEPS_TO_SQUEEZE
        enemy["phase_cooldown"] = 0.0
    else:
        enemy["stuck_steps"] = 0


func _move_enemy_to(enemy: Dictionary, target: Vector2i, digs := false) -> void:
    var from_pos: Vector2i = enemy["pos"]
    var from_visual := _dict_visual(enemy)
    var target_visual := _visual_from_pos(target)
    enemy["pos"] = target
    enemy["visual_speed"] = _enemy_move_speed(enemy)
    if digs:
        _clear_soil_capsule_px(_cell_center_px(from_pos), _cell_center_px(target), TUNNEL_HALF_WIDTH)


func _enemy_step_delay(enemy: Dictionary) -> float:
    return 1.0 / maxf(_enemy_move_speed(enemy), 0.001)


func _enemy_move_speed(enemy: Dictionary) -> float:
    if enemy.get("phasing", false):
        return _player_dig_speed() * ENEMY_PHASE_SPEED_RATIO
    return _enemy_move_speed_for_kind(int(enemy.get("kind", ENEMY_GRUB_KIND)))


func _enemy_move_speed_for_kind(kind: int) -> float:
    var ratio := ENEMY_GRUB_SPEED_RATIO
    if kind == ENEMY_BURROWER_KIND:
        ratio = ENEMY_BURROWER_SPEED_RATIO
    elif kind == ENEMY_FYGAR_KIND:
        ratio = ENEMY_FYGAR_SPEED_RATIO
    var floor_bonus := 0.0
    return _player_dig_speed() * (ratio + floor_bonus)


func _player_tunnel_speed() -> float:
    return 1.0 / maxf(move_delay, 0.001)


func _player_dig_speed() -> float:
    return 1.0 / maxf(move_delay * dig_delay_mult, 0.001)


func _update_rocks(delta: float) -> void:
    for rock in rocks:
        var pos: Vector2i = rock["pos"]
        var below := pos + Vector2i.DOWN
        var can_fall := _can_rock_fall_to(below)
        if not can_fall:
            rock["falling"] = false
            rock["timer"] = ROCK_LOOSE_DELAY
            rock["fall_distance"] = 0
            continue

        rock["falling"] = true
        rock["timer"] -= delta
        if rock["timer"] > 0.0:
            continue

        rock["timer"] = ROCK_STEP_DELAY
        rock["pos"] = below
        rock["fall_distance"] += 1
        _crush_at(below, rock["fall_distance"])


func _can_rock_fall_to(pos: Vector2i) -> bool:
    if not _in_bounds(pos):
        return false
    if _has_rock(pos):
        return false
    return _tile(pos) != TILE_DIRT


func _crush_at(pos: Vector2i, fall_distance: int) -> void:
    if fall_distance <= 0:
        return

    if pos == player_pos:
        if _has_rock_ward():
            _consume_rock_ward()
            _hurt_player(1)
            _move_player_to_nearest_safe()
            message = "Your stone ward cracked."
        else:
            hp = 0
            _game_over("Flattened by a loose boulder.")

    for i in range(enemies.size() - 1, -1, -1):
        if _enemy_crushed_by_rock(enemies[i], pos):
            var dead_kind := int(enemies[i].get("kind", ENEMY_GRUB_KIND))
            _add_rupture_feedback(pos)
            enemies.remove_at(i)
            floor_kills += 1
            floor_boulder_kills += 1
            _drop_xp(pos, 1 + dead_kind)
            _award_score(170 + floor_index * 12, true, "Boulder crush")
            _shake(0.22)
            message = "Boulder crush!"
            if stone_circuit > 0:
                rock_ward = true
                _add_cell_pulse(pos, RUPTURE, PULSE_FEEDBACK_TIME + 0.08, 1.0 + float(stone_circuit) * 0.35, true)
                _stun_enemies_near(pos, 2 + stone_circuit, 0.45 + _effective_stun_bonus())


func _enemy_crushed_by_rock(enemy: Dictionary, rock_pos: Vector2i) -> bool:
    if enemy["phasing"]:
        return false
    var enemy_pos: Vector2i = enemy["pos"]
    if enemy_pos == rock_pos or enemy_pos == rock_pos + Vector2i.DOWN:
        return true
    var enemy_visual := _dict_visual(enemy)
    var rock_visual := _visual_from_pos(rock_pos)
    return absf(enemy_visual.x - rock_visual.x) <= 0.42 and absf(enemy_visual.y - rock_visual.y) <= 1.08


func _hurt_player(amount: int) -> void:
    if hurt_flash > 0.0 or state != STATE_PLAYING:
        return
    hp -= amount
    floor_damage_taken += amount
    hurt_flash = 0.75
    combo_count = 0
    combo_timer = 0.0
    _shake(0.38)
    _add_cell_pulse(player_pos, WARN, PULSE_FEEDBACK_TIME + 0.18, 1.35, true)
    message = "Ouch."
    if hp <= 0:
        _game_over("The den got you.")


func _game_over(reason: String) -> void:
    state = STATE_GAME_OVER
    message = reason


func _move_player_to_nearest_safe() -> void:
    for radius in range(1, 5):
        for x in range(-radius, radius + 1):
            for y in range(-radius, radius + 1):
                var pos := player_pos + Vector2i(x, y)
                if _in_bounds(pos) and _tile(pos) != TILE_DIRT and not _has_rock(pos) and _enemy_index_at(pos) == -1:
                    player_pos = pos
                    player_visual_pos = _visual_from_pos(player_pos)
                    player_move_dir = Vector2i.ZERO
                    player_step_from = player_pos
                    player_target_cell = player_pos
                    player_target_digging = false
                    player_digging = false
                    return


func _award_score(amount: int, combo: bool, label: String) -> int:
    var award := amount
    if combo:
        combo_count += 1
        combo_timer = COMBO_WINDOW
        best_combo = maxi(best_combo, combo_count)
        var multiplier := 1.0 + float(mini(combo_count - 1, 8)) * 0.25
        award = roundi(float(amount) * multiplier)
        if combo_count >= 2:
            message = "%s chain x%d +%d." % [label, combo_count, award]
    score += award
    return award


func _shake(amount: float) -> void:
    screen_shake = maxf(screen_shake, amount)


func _drop_xp(pos: Vector2i, amount: int) -> void:
    for i in range(maxi(1, amount)):
        var jitter := Vector2(rng.randf_range(-0.18, 0.18), rng.randf_range(-0.18, 0.18))
        xp_pickups.append({
            "pos": pos,
            "visual_pos": _visual_from_pos(pos) + jitter,
            "value": 1
        })


func _update_xp_pickups(delta: float) -> void:
    for i in range(xp_pickups.size() - 1, -1, -1):
        var pickup: Dictionary = xp_pickups[i]
        var visual: Vector2 = pickup.get("visual_pos", _visual_from_pos(pickup["pos"]))
        var to_player := player_visual_pos - visual
        if to_player.length() <= XP_PICKUP_RADIUS:
            _gain_xp(int(pickup.get("value", 1)))
            xp_pickups.remove_at(i)
            if state != STATE_PLAYING:
                return
            continue
        if to_player.length() <= XP_MAGNET_RADIUS:
            visual = visual.move_toward(player_visual_pos, XP_MAGNET_SPEED * delta)
            pickup["visual_pos"] = visual
            xp_pickups[i] = pickup


func _gain_xp(amount: int) -> void:
    if amount <= 0 or state != STATE_PLAYING:
        return
    xp += amount
    while xp >= xp_to_next:
        xp -= xp_to_next
        player_level += 1
        xp_to_next = XP_BASE_TO_NEXT + (player_level - 1) * XP_GROWTH
        hp = mini(max_hp, hp + 1)
        _offer_upgrades()
        return
    if combo_count < 2:
        message = "Pressure gem."


func _collect_gem_at(pos: Vector2i) -> void:
    for i in range(gems.size() - 1, -1, -1):
        if gems[i] == pos:
            gems.remove_at(i)
            gems_collected += 1
            gem_bank += 1
            floor_gems_collected += 1
            _award_score(20 + gem_bonus, true, "Gem")
            var pulse := _effective_gem_pulse()
            if pulse > 0:
                _add_cell_pulse(pos, GEM, PULSE_FEEDBACK_TIME + 0.08, 1.0 + float(pulse) * 0.32)
                _stun_enemies_near(pos, 1 + mini(pulse, 2), 0.28 + float(pulse) * 0.08 + _effective_stun_bonus() * 0.25)
                if pulse >= 2 and (crystal_charge > 0 or _lance_overdrive()):
                    crystal_charge = maxi(0, crystal_charge - 1)
                    _burst_nearby_enemies(pos, 1, mini(pulse, 2), "Gem echo!")
            if crystal_charge_cap > 0 and crystal_charge < crystal_charge_cap:
                crystal_charge += 1
                if combo_count < 2:
                    message = "Gem pocket. Lance charged."
            else:
                if combo_count < 2:
                    message = "Gem pocket."
            return


func _collect_relic_at(pos: Vector2i) -> void:
    for i in range(floor_relics.size() - 1, -1, -1):
        if floor_relics[i]["pos"] == pos:
            var relic: Dictionary = floor_relics[i]
            floor_relics.remove_at(i)
            floor_relics_found += 1
            _apply_upgrade(relic, "floor")
            _award_score(60 + floor_index * 10, true, "Relic")
            _add_cell_pulse(pos, RUPTURE, PULSE_FEEDBACK_TIME + 0.12, 1.15, true)
            _shake(0.12)
            return


func _eat_gem_at(pos: Vector2i) -> void:
    for i in range(gems.size() - 1, -1, -1):
        if gems[i] == pos:
            gems.remove_at(i)
            message = "A burrower ate a gem."
            _add_cell_pulse(pos, ENEMY_BURROWER, PULSE_FEEDBACK_TIME, 0.85)
            return


func _upgrade_pool() -> Array:
    var pool := [
        {"id": "range", "name": "Longer Lance", "desc": "+1 pressure range."},
        {"id": "damage", "name": "Dense Air", "desc": "+1 lance damage."},
        {"id": "speed", "name": "Quick Boots", "desc": "Move and tunnel faster."},
        {"id": "heart", "name": "Extra Heart", "desc": "+1 max heart and heal."},
        {"id": "stun", "name": "Echo Valve", "desc": "Enemies stay stunned longer."},
        {"id": "gems", "name": "Gem Sense", "desc": "Gems are worth more score."},
        {"id": "ward", "name": "Stone Ward", "desc": "Survive one boulder hit."},
        {"id": "split", "name": "Split Jet", "desc": "Lance splashes sideways on impact."},
        {"id": "crystal", "name": "Crystal Battery", "desc": "Gems charge bonus lance damage."},
        {"id": "circuit", "name": "Stone Circuit", "desc": "Boulder kills restore ward and stun."},
        {"id": "resonance", "name": "Resonant Spike", "desc": "Hit stunned enemies harder."},
        {"id": "wave", "name": "Rupture Wave", "desc": "Lance impacts pulse through nearby cells."},
        {"id": "shards", "name": "Shard Bloom", "desc": "Enemy ruptures damage nearby enemies."},
        {"id": "gem_pulse", "name": "Gem Echo", "desc": "Gems release a stunning pressure pulse."},
        {"id": "momentum", "name": "Tunnel Momentum", "desc": "Fresh digs carry you into the next step."}
    ]
    return pool


func _offer_upgrades() -> void:
    state = STATE_CHOOSING
    upgrade_choices.clear()
    var pool := _available_upgrade_pool()
    pool.shuffle()
    for i in range(mini(3, pool.size())):
        var choice: Dictionary = pool[i].duplicate()
        upgrade_choices.append(choice)
    message = "Choose a relic. %s." % SHOP_SKIP_KEY_TEXT


func _choose_upgrade(index: int) -> void:
    if index < 0 or index >= upgrade_choices.size():
        return
    var choice: Dictionary = upgrade_choices[index]
    _apply_upgrade(choice, "shop")
    _resume_survival()


func _skip_upgrade_shop() -> void:
    if state != STATE_CHOOSING:
        return
    _resume_survival()


func _upgrade_cost(id: String) -> int:
    var base := 7 + floor_index
    match id:
        "heart", "damage", "split", "wave", "crystal", "shards":
            return base + 3
        "ward", "gems", "stun":
            return base - 1
        _:
            return base


func _available_upgrade_pool() -> Array:
    var available := []
    for upgrade in _upgrade_pool():
        var id: String = upgrade["id"]
        if _upgrade_is_available(id):
            available.append(upgrade)
    return available


func _upgrade_is_available(id: String) -> bool:
    match id:
        "split", "wave", "shards":
            return floor_index >= 4 or crystal_charge_cap > 0 or int(family_points.get("lance", 0)) >= 3
        "gem_pulse":
            return floor_index >= 3 or crystal_charge_cap > 0
        "circuit":
            return floor_index >= 3
        _:
            return true


func _apply_upgrade(choice: Dictionary, source: String) -> void:
    if source == "floor":
        _apply_temp_upgrade(choice)
        return
    match choice["id"]:
        "range":
            lance_range = mini(lance_range + 1, 5)
        "damage":
            lance_damage += 1
        "speed":
            move_delay = maxf(0.13, move_delay - 0.008)
            dig_delay_mult = maxf(1.24, dig_delay_mult - 0.04)
        "heart":
            max_hp += 1
            hp = max_hp
        "stun":
            stun_bonus += 0.22
        "gems":
            gem_bonus += 6
        "ward":
            rock_ward = true
        "split":
            split_jet += 1
        "crystal":
            crystal_charge_cap += 1
            crystal_charge = crystal_charge_cap
        "circuit":
            stone_circuit += 1
            rock_ward = true
        "resonance":
            resonant_hits += 1
        "wave":
            pressure_wave += 1
        "shards":
            shard_bloom += 1
        "gem_pulse":
            gem_pulse += 1
        "momentum":
            tunnel_momentum += 1
    _register_family_upgrade(choice["id"], source)


func _apply_temp_upgrade(choice: Dictionary) -> void:
    match choice["id"]:
        "range":
            temp_lance_range += 1
        "damage":
            temp_lance_damage += 1
        "speed":
            temp_tunnel_momentum += 1
        "heart":
            hp = mini(max_hp, hp + 1)
        "stun":
            temp_stun_bonus += 0.25
        "gems":
            gem_bank += 2
        "ward":
            temp_rock_ward = true
        "split":
            temp_split_jet += 1
        "crystal":
            crystal_charge += 1
        "circuit":
            temp_rock_ward = true
        "resonance":
            temp_lance_damage += 1
        "wave":
            temp_pressure_wave += 1
        "shards":
            temp_shard_bloom += 1
        "gem_pulse":
            temp_gem_pulse += 1
        "momentum":
            temp_tunnel_momentum += 1
    message = "Found %s for this run." % _upgrade_name(choice["id"])


func _register_family_upgrade(id: String, source: String) -> void:
    var family := _upgrade_family(id)
    var count := int(family_points.get(family, 0)) + 1
    family_points[family] = count
    var bonus_text := ""
    if count == 3:
        match family:
            "lance":
                stun_bonus += 0.18
                bonus_text = "Lance set: steadier pump."
            "gem":
                crystal_charge_cap = maxi(crystal_charge_cap, 1)
                crystal_charge = crystal_charge_cap
                bonus_text = "Gem set: one pressure cell."
            "stone":
                rock_ward = true
                bonus_text = "Stone set: ward restored."
            "motion":
                dig_delay_mult = maxf(1.24, dig_delay_mult - 0.04)
                bonus_text = "Motion set: cleaner digging."
    elif count == 5:
        match family:
            "lance":
                lance_damage += 1
                bonus_text = "Lance mastery: heavier pump."
            "gem":
                crystal_charge_cap += 1
                crystal_charge = crystal_charge_cap
                bonus_text = "Gem mastery: deeper battery."
            "stone":
                stone_circuit += 1
                rock_ward = true
                bonus_text = "Stone mastery: live circuit."
            "motion":
                tunnel_momentum += 1
                bonus_text = "Motion mastery: extra momentum."
    elif count == 7:
        match family:
            "lance":
                pressure_wave += 1
                bonus_text = "Endgame lance: rupture wave unlocked."
            "gem":
                gem_pulse += 1
                bonus_text = "Endgame gems: charged echoes."
            "stone":
                stone_circuit += 1
                bonus_text = "Endgame stone: double circuit."
            "motion":
                move_delay = maxf(0.11, move_delay - 0.012)
                bonus_text = "Endgame motion: quick feet."
    if bonus_text != "":
        message = bonus_text
    elif source == "floor":
        message = "Found %s." % _upgrade_name(id)
    else:
        message = "Bought %s." % _upgrade_name(id)


func _upgrade_family(id: String) -> String:
    match id:
        "range", "damage", "stun", "split", "resonance", "wave", "shards":
            return "lance"
        "gems", "crystal", "gem_pulse":
            return "gem"
        "ward", "circuit":
            return "stone"
        "speed", "heart", "momentum":
            return "motion"
        _:
            return "lance"


func _upgrade_name(id: String) -> String:
    for upgrade in _upgrade_pool():
        if upgrade["id"] == id:
            return upgrade["name"]
    return "relic"


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), BG)
    _draw_board()
    _draw_actors()
    _draw_damage_feedback()
    _draw_ui()


func _update_visual_positions(delta: float) -> void:
    for enemy in enemies:
        if enemy["phasing"]:
            continue
        var target := _visual_from_pos(enemy["pos"])
        var speed := float(enemy.get("visual_speed", _enemy_move_speed(enemy)))
        enemy["visual_pos"] = _dict_visual(enemy).move_toward(target, speed * delta)

    for rock in rocks:
        var target := _visual_from_pos(rock["pos"])
        rock["visual_pos"] = _dict_visual(rock).move_toward(target, ROCK_VISUAL_SPEED * delta)


func _update_feedback(delta: float) -> void:
    for i in range(dig_feedback.size() - 1, -1, -1):
        dig_feedback[i]["time"] = float(dig_feedback[i]["time"]) - delta
        if dig_feedback[i]["time"] <= 0.0:
            dig_feedback.remove_at(i)

    for i in range(pulse_feedback.size() - 1, -1, -1):
        pulse_feedback[i]["time"] = float(pulse_feedback[i]["time"]) - delta
        if pulse_feedback[i]["time"] <= 0.0:
            pulse_feedback.remove_at(i)


func _update_tunnel_regrowth(delta: float) -> void:
    for pos in tunnel_age.keys():
        tunnel_age[pos] = float(tunnel_age[pos]) + delta

    regrow_timer -= delta
    if regrow_timer > 0.0:
        return
    regrow_timer = REGROW_CHECK_INTERVAL

    var candidates := []
    for pos in tunnel_age.keys():
        if not _can_regrow_cell(pos):
            continue
        var age := float(tunnel_age[pos])
        var open_neighbors := _adjacent_tunnel_count(pos)
        if age < REGROW_CELL_AGE or (open_neighbors <= 1 and age < REGROW_CELL_AGE * 1.75):
            continue
        candidates.append({
            "pos": pos,
            "score": age + float(open_neighbors) * 8.0 + sqrt(float(pos.distance_squared_to(player_pos))) * 0.25
        })

    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["score"]) > float(b["score"])
    )

    var regrown := 0
    for candidate in candidates:
        if regrown >= REGROW_MAX_PER_TICK:
            break
        var pos: Vector2i = candidate["pos"]
        if not _can_regrow_cell(pos):
            continue
        _set_tile(pos, TILE_DIRT)
        _add_cell_pulse(pos, DIRT, PULSE_FEEDBACK_TIME, 0.82)
        regrown += 1

    if regrown > 0:
        _rebuild_soil_mask_from_grid()
        if combo_count < 2 and rng.randf() < 0.35:
            message = "Old tunnels are closing."


func _can_regrow_cell(pos: Vector2i) -> bool:
    if not _in_bounds(pos) or _tile(pos) != TILE_TUNNEL:
        return false
    if pos == player_pos or pos == player_target_cell or pos == player_step_from or pos == exit_pos:
        return false
    if pos.distance_squared_to(player_pos) < REGROW_PLAYER_SAFE_RADIUS * REGROW_PLAYER_SAFE_RADIUS:
        return false
    if _has_rock(pos) or _enemy_index_at(pos) != -1 or _has_gem(pos) or _has_relic(pos) or _has_xp_pickup(pos):
        return false
    return true


func _has_xp_pickup(pos: Vector2i) -> bool:
    for pickup in xp_pickups:
        if pickup["pos"] == pos:
            return true
    return false


func _draw_board() -> void:
    var board_rect := Rect2(_board_origin() - Vector2(4, 4), Vector2(BOARD_W * CELL + 8, BOARD_H * CELL + 8))
    draw_rect(board_rect, Color("#0a0b0f"))
    draw_rect(Rect2(_board_origin(), Vector2(BOARD_PX_W, BOARD_PX_H)), TUNNEL)
    _flush_soil_texture()
    if soil_texture != null:
        draw_texture(soil_texture, _board_origin())

    _draw_dig_feedback()

    var exit_rect := Rect2(_cell_to_px(exit_pos) + Vector2(3, 3), Vector2(CELL - 6, CELL - 6))
    draw_rect(exit_rect, EXIT_OPEN if exit_unlocked else EXIT_LOCKED)
    draw_rect(exit_rect.grow(-5), Color("#111318"))

    for gem_pos in gems:
        if _tile(gem_pos) == TILE_DIRT:
            if _adjacent_tunnel_count(gem_pos) > 0:
                var hint_center := _cell_center(gem_pos)
                var hint := GEM
                hint.a = 0.34 + sin(anim_time * 5.0 + gem_pos.x) * 0.12
                draw_circle(hint_center, 2.2, hint)
            continue
        var center := _cell_center(gem_pos)
        draw_polygon([
            center + Vector2(0, -7),
            center + Vector2(7, 0),
            center + Vector2(0, 7),
            center + Vector2(-7, 0)
        ], [GEM])

    for relic in floor_relics:
        var relic_pos: Vector2i = relic["pos"]
        if _tile(relic_pos) == TILE_DIRT and _adjacent_tunnel_count(relic_pos) == 0:
            continue
        var relic_center := _cell_center(relic_pos)
        var relic_color := RUPTURE
        relic_color.a = 0.42 if _tile(relic_pos) == TILE_DIRT else 0.95
        draw_circle(relic_center, 7.0, relic_color)
        draw_rect(Rect2(relic_center - Vector2(3, 3), Vector2(6, 6)), Color("#fff2bf"))

    for pickup in xp_pickups:
        var pickup_visual: Vector2 = pickup.get("visual_pos", _visual_from_pos(pickup["pos"]))
        var center := _visual_to_center(pickup_visual)
        var pulse := 1.0 + sin(anim_time * 8.0 + center.x * 0.05) * 0.16
        draw_circle(center, 4.0 * pulse, PRESSURE)
        draw_circle(center, 1.7 * pulse, Color("#ffffffcc"))


func _draw_actors() -> void:
    for enemy in enemies:
        for cell in _enemy_fire_cells(enemy):
            var fire_color := FIRE
            var active := float(enemy.get("fire_active", 0.0)) > 0.0
            fire_color.a = 0.78 if active else 0.28 + sin(anim_time * 12.0) * 0.08
            draw_rect(Rect2(_cell_to_px(cell) + Vector2(2, 9), Vector2(CELL - 4, CELL - 18)), fire_color)

    if lance_active and not last_attack_cells.is_empty():
        var progress := 1.0 - attack_flash / ATTACK_FLASH_TIME
        var visible_cells := clampi(ceili(float(last_attack_cells.size()) * progress), 1, last_attack_cells.size())
        for i in range(visible_cells):
            var pos: Vector2i = last_attack_cells[i]
            draw_rect(Rect2(_cell_to_px(pos) + Vector2(8, 8), Vector2(CELL - 16, CELL - 16)), Color("#d9f8ff88"))

    _draw_pulse_feedback()

    for rock in rocks:
        var center := _visual_to_center(_dict_visual(rock))
        if rock["falling"] and rock["fall_distance"] == 0:
            center += Vector2(sin(anim_time * 32.0) * 2.0, 0.0)
        draw_circle(center + Vector2(2, 3), 11.0, ROCK_SHADOW)
        draw_circle(center, 11.0, ROCK)
        draw_arc(center, 7.0, 3.5, 5.7, 8, Color("#c7ccd3"), 1.4)

    for enemy in enemies:
        var center := _visual_to_center(_dict_visual(enemy))
        center += _enemy_melee_visual_offset(enemy)
        var color := ENEMY_GRUB
        if enemy["kind"] == ENEMY_BURROWER_KIND:
            color = ENEMY_BURROWER
        elif enemy["kind"] == ENEMY_FYGAR_KIND:
            color = ENEMY_FYGAR
        var max_enemy_hp := maxi(1, int(enemy.get("max_hp", enemy["hp"])))
        var missing_hp := clampi(max_enemy_hp - int(enemy["hp"]), 0, max_enemy_hp)
        var pressure_ratio := float(missing_hp) / float(max_enemy_hp)
        var inflated := bool(enemy.get("inflated", false))
        var hit_flash := float(enemy.get("hit_flash", 0.0))
        var hit_phase := 0.0
        if hit_flash > 0.0:
            hit_phase = sin((1.0 - hit_flash / ENEMY_HIT_FLASH) * PI)
        if enemy["stun"] > 0.0:
            color = color.lerp(Color.WHITE, 0.45)
        if inflated:
            color = color.lerp(PRESSURE, 0.45)
        if enemy["phasing"]:
            center += Vector2(0.0, sin(anim_time * 7.5) * 1.5)
            color = color.lerp(DIRT, 0.32)
            var dust := DIRT
            dust.a = 0.48
            draw_circle(center + Vector2(-8, 5), 3.2 + sin(anim_time * 9.0) * 0.8, dust)
            draw_circle(center + Vector2(8, 4), 2.8 + cos(anim_time * 8.0) * 0.6, dust)
            draw_arc(center, 13.0, PI * 0.1, PI * 0.9, 10, DIRT_DARK, 1.6)
        var body_radius := 10.5 + pressure_ratio * 5.0 + hit_phase * 2.8
        if pressure_ratio > 0.0 or inflated:
            var glow := PRESSURE
            glow.a = 0.14 + pressure_ratio * 0.24
            draw_circle(center, body_radius + 4.5, glow)
        draw_circle(center, body_radius, color)
        for ring in range(mini(3, missing_hp)):
            var ring_color := PRESSURE.lerp(RUPTURE, float(ring) / 3.0)
            ring_color.a = 0.65
            draw_arc(center, body_radius + 3.0 + ring * 2.6, anim_time * 2.0 + ring, anim_time * 2.0 + ring + PI * 1.3, 12, ring_color, 1.3)
        if pressure_ratio >= 0.34:
            _draw_enemy_cracks(center, body_radius, pressure_ratio)
        var eye_color := Color("#16171c")
        draw_circle(center + Vector2(-4, -2), 2.0, eye_color)
        draw_circle(center + Vector2(4, -2), 2.0, eye_color)
        if enemy["kind"] == ENEMY_BURROWER_KIND:
            var stripe := Color("#5b3518")
            draw_rect(Rect2(center + Vector2(-8, 6), Vector2(16, 3)), stripe)
        elif enemy["kind"] == ENEMY_FYGAR_KIND:
            var flame := FIRE
            flame.a = 0.85 if float(enemy.get("fire_active", 0.0)) > 0.0 else 0.45
            draw_circle(center + Vector2(0, 6), 3.5, flame)

    var pc := _visual_to_center(player_visual_pos)
    _draw_player(pc)


func _draw_player(pc: Vector2) -> void:
    var forward := Vector2(facing)
    if forward == Vector2.ZERO:
        forward = Vector2.RIGHT
    forward = forward.normalized()
    var side := Vector2(-forward.y, forward.x)
    var moving := player_move_dir != Vector2i.ZERO
    var stride := sin(anim_time * 16.0) * (1.0 if moving else 0.0)
    var bob := absf(stride) * 1.2
    var color := PLAYER.lerp(Color.WHITE, 0.55) if hurt_flash > 0.0 else PLAYER
    var boot := Color("#113f3b")
    var suit := PLAYER_DARK
    var core := pc + Vector2(0.0, -bob)
    var hip := core - forward * 3.0 + Vector2(0.0, 5.0)
    var chest := core + forward * 2.0 + Vector2(0.0, -3.0)
    var head := chest + forward * 5.0 + Vector2(0.0, -6.0)

    draw_line(hip + side * 3.0, hip + side * 5.0 + forward * (4.0 * stride) + Vector2(0.0, 7.0), boot, 3.0)
    draw_line(hip - side * 3.0, hip - side * 5.0 - forward * (4.0 * stride) + Vector2(0.0, 7.0), boot, 3.0)
    draw_line(chest + side * 5.0, chest + side * 8.0 - forward * (3.0 * stride), suit, 2.4)
    draw_line(chest - side * 5.0, chest - side * 8.0 + forward * (3.0 * stride), suit, 2.4)
    _draw_ellipse(core + Vector2(0.0, 1.0), Vector2(7.0, 8.5), suit)
    _draw_ellipse(core + forward * 2.0 + Vector2(0.0, -1.0), Vector2(6.0, 7.0), color)
    draw_circle(head, 4.6, Color("#ffd7a6").lerp(Color.WHITE, 0.35 if hurt_flash > 0.0 else 0.0))
    draw_circle(head + forward * 1.7 + Vector2(0.0, -0.8), 1.0, Color("#111318"))
    draw_line(core + forward * 4.0, core + forward * 14.0, Color("#0c3a37"), 2.8)


func _draw_damage_feedback() -> void:
    if hurt_flash <= 0.0:
        return
    var progress := 1.0 - hurt_flash / 0.75
    var overlay := Color("#ff3355")
    overlay.a = 0.16 * (1.0 - progress)
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), overlay)
    var center := _visual_to_center(player_visual_pos)
    var ring := WARN
    ring.a = 0.85 * (1.0 - progress)
    draw_arc(center, 13.0 + progress * 18.0, 0.0, TAU, 24, ring, 2.6)
    for i in range(6):
        var angle := float(i) * TAU / 6.0 + progress * 0.4
        var dir := Vector2(cos(angle), sin(angle))
        draw_line(center + dir * 9.0, center + dir * (14.0 + progress * 14.0), ring, 1.8)


func _draw_ui() -> void:
    _text(Vector2(24, 34), "DIGGY: CAVERNS OF CHANCE", 24, UI)
    _text(Vector2(PANEL_X, 78), "Time %s / %s" % [_format_time(run_time), _format_time(RUN_GOAL_TIME)], 20, UI)
    _text(Vector2(PANEL_X, 108), "Level %d  XP %d / %d" % [player_level, xp, xp_to_next], 18, PRESSURE)
    var xp_bar_w := 196.0
    var xp_ratio := clampf(float(xp) / float(maxi(1, xp_to_next)), 0.0, 1.0)
    draw_rect(Rect2(Vector2(PANEL_X, 132), Vector2(xp_bar_w, 8)), Color("#29313a"))
    draw_rect(Rect2(Vector2(PANEL_X, 132), Vector2(xp_bar_w * xp_ratio, 8)), PRESSURE)
    _text(Vector2(PANEL_X, 160), "Score %06d" % score, 18, UI)
    _text(Vector2(PANEL_X, 186), "Gems %d / %d total" % [gem_bank, gems_collected], 18, GEM)
    _text(Vector2(PANEL_X, 214), "Kills %d  Enemies %d / %d" % [floor_kills, enemies.size(), _spawn_cap()], 15, MUTED)
    _text(Vector2(PANEL_X, 240), "Rocks %d / %d" % [rocks.size(), _rock_cap()], 15, ROCK)
    _text(Vector2(PANEL_X, 264), "Relics found %d / %d" % [floor_relics_found, floor_relics_found + floor_relics.size()], 15, MUTED)
    _text(Vector2(PANEL_X, 294), "Hearts %s" % _heart_string(), 18, Color("#ff8fa3"))
    _text(Vector2(PANEL_X, 326), "Lance R%d D%d" % [_effective_lance_range(), _effective_lance_damage()], 16, MUTED)
    _text(Vector2(PANEL_X, 350), "Ward ready" if _has_rock_ward() else "Ward empty", 16, WARN if _has_rock_ward() else MUTED)
    if crystal_charge_cap > 0 or crystal_charge > 0:
        var charge_label := "Charge %d" % crystal_charge if crystal_charge_cap <= 0 else "Charge %d / %d" % [crystal_charge, crystal_charge_cap]
        _text(Vector2(PANEL_X, 374), charge_label, 16, GEM)
    if _effective_split_jet() > 0 or resonant_hits > 0 or stone_circuit > 0 or _effective_pressure_wave() > 0 or _effective_shard_bloom() > 0 or _effective_gem_pulse() > 0 or _effective_tunnel_momentum() > 0:
        _text(Vector2(PANEL_X, 398), _synergy_string(), 15, Color("#f7df86"))
    if combo_count >= 2 and combo_timer > 0.0:
        _text(Vector2(PANEL_X, 424), "Combo x%d" % combo_count, 18, RUPTURE)
    if not family_points.is_empty():
        _text(Vector2(PANEL_X, 448), _family_string(), 14, MUTED)

    _text(Vector2(PANEL_X, 464), "WASD / arrows move", 15, MUTED)
    _text(Vector2(PANEL_X, 486), "Hold Space lance", 15, MUTED)
    _text(Vector2(PANEL_X, 508), "E extraction gate", 15, MUTED)
    _text(Vector2(PANEL_X, 530), "R restart", 15, MUTED)

    if message != "":
        _text(Vector2(24, 594), message, 18, WARN)

    if state == STATE_CHOOSING:
        draw_rect(Rect2(Vector2(128, 116), Vector2(704, 350)), Color("#111820ee"))
        draw_rect(Rect2(Vector2(128, 116), Vector2(704, 350)), Color("#d8c27a"), false, 2.0)
        _text(Vector2(170, 156), "Level %d relic", 30, UI)
        _text(Vector2(172, 190), "Pressure gathered: %d / %d    %s" % [xp, xp_to_next, SHOP_SKIP_KEY_TEXT], 16, MUTED)
        if last_floor_summary != "":
            _text(Vector2(172, 216), last_floor_summary, 14, Color("#f7df86"))
        for i in range(upgrade_choices.size()):
            var choice: Dictionary = upgrade_choices[i]
            var y := 254 + i * 62
            _text(Vector2(180, y), "%d  %s" % [i + 1, choice["name"]], 21, Color("#f7df86"))
            _text(Vector2(222, y + 28), choice["desc"], 17, MUTED)
    elif state == STATE_GAME_OVER:
        _draw_center_modal("Run ended", message, "Press Space or Enter to restart.")
    elif state == STATE_WIN:
        _draw_center_modal("You escaped", "Score %d with %d gems." % [score, gems_collected], "Press Space or Enter for a fresh run.")


func _draw_center_modal(title: String, line: String, prompt: String) -> void:
    draw_rect(Rect2(Vector2(186, 168), Vector2(588, 250)), Color("#111820ee"))
    draw_rect(Rect2(Vector2(186, 168), Vector2(588, 250)), Color("#d8c27a"), false, 2.0)
    _text(Vector2(236, 232), title, 34, UI)
    _text(Vector2(238, 282), line, 20, WARN)
    _text(Vector2(238, 330), prompt, 17, MUTED)


func _draw_dig_feedback() -> void:
    for effect in dig_feedback:
        var pos: Vector2i = effect["pos"]
        var duration := float(effect["duration"])
        var progress := 1.0 - float(effect["time"]) / duration
        var center: Vector2 = effect.get("center", _cell_center(pos))
        var glow := PRESSURE
        glow.a = 0.22 * (1.0 - progress)
        draw_arc(center, 7.0 + progress * 7.0, 0.0, TAU, 14, glow, 1.5)
        var dust := DIRT.lerp(RUPTURE, 0.35)
        dust.a = 0.7 * (1.0 - progress)
        for i in range(4):
            var angle := float(i) * TAU / 4.0 + float(pos.x * 19 + pos.y * 7) * 0.03
            var offset := Vector2(cos(angle), sin(angle)) * (4.0 + progress * 8.0)
            draw_circle(center + offset, 1.7, dust)


func _draw_pulse_feedback() -> void:
    for effect in pulse_feedback:
        var pos: Vector2i = effect["pos"]
        var duration := float(effect["duration"])
        var progress := 1.0 - float(effect["time"]) / duration
        var center := _cell_center(pos)
        var color: Color = effect["color"]
        color.a = float(effect["alpha"]) * (1.0 - progress)
        var radius := CELL * (0.18 + float(effect["radius"]) * progress)
        draw_arc(center, radius, 0.0, TAU, 28, color, 2.0)
        if effect.get("burst", false):
            var shard_color := RUPTURE
            shard_color.a = 0.75 * (1.0 - progress)
            for i in range(9):
                var angle := float(i) * TAU / 9.0 + float(pos.x - pos.y) * 0.11
                var dir := Vector2(cos(angle), sin(angle))
                draw_line(center + dir * 5.0, center + dir * (8.0 + progress * 18.0), shard_color, 1.5)


func _draw_enemy_cracks(center: Vector2, radius: float, pressure_ratio: float) -> void:
    var crack_color := Color("#fff0c2")
    crack_color.a = 0.4 + pressure_ratio * 0.35
    for i in range(3):
        var angle := anim_time * 0.4 + float(i) * TAU / 3.0
        var start := center + Vector2(cos(angle), sin(angle)) * (radius * 0.2)
        var mid := center + Vector2(cos(angle + 0.35), sin(angle + 0.35)) * (radius * 0.55)
        var end := center + Vector2(cos(angle + 0.1), sin(angle + 0.1)) * (radius * 0.9)
        draw_line(start, mid, crack_color, 1.2)
        draw_line(mid, end, crack_color, 1.2)


func _enemy_melee_visual_offset(enemy: Dictionary) -> Vector2:
    var windup := float(enemy.get("attack_windup", 0.0))
    if windup <= 0.0:
        return Vector2.ZERO
    var dir: Vector2i = enemy.get("attack_dir", Vector2i.ZERO)
    if dir == Vector2i.ZERO:
        return Vector2.ZERO
    var progress := 1.0 - windup / maxf(ENEMY_ATTACK_WARN, 0.001)
    var lunge := progress * progress
    return Vector2(float(dir.x), float(dir.y)) * lunge * ENEMY_ATTACK_LUNGE_CELLS * CELL


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := []
    for i in range(20):
        var angle := float(i) * TAU / 20.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_polygon(points, [color])


func _text(pos: Vector2, value: String, size: int, color: Color) -> void:
    draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _heart_string() -> String:
    var text := ""
    for i in range(max_hp):
        text += "x" if i < hp else "-"
    return text


func _format_time(value: float) -> String:
    var total := maxi(0, floori(value))
    return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]


func _effective_lance_range() -> int:
    return lance_range + temp_lance_range


func _effective_lance_damage() -> int:
    return lance_damage + temp_lance_damage


func _effective_stun_bonus() -> float:
    return stun_bonus + temp_stun_bonus


func _effective_split_jet() -> int:
    return split_jet + temp_split_jet


func _effective_pressure_wave() -> int:
    return pressure_wave + temp_pressure_wave


func _effective_shard_bloom() -> int:
    return shard_bloom + temp_shard_bloom


func _effective_gem_pulse() -> int:
    return gem_pulse + temp_gem_pulse


func _effective_tunnel_momentum() -> int:
    return tunnel_momentum + temp_tunnel_momentum


func _has_rock_ward() -> bool:
    return rock_ward or temp_rock_ward


func _consume_rock_ward() -> void:
    if temp_rock_ward:
        temp_rock_ward = false
    else:
        rock_ward = false


func _lance_overdrive() -> bool:
    return floor_index >= 7 and int(family_points.get("lance", 0)) >= 5


func _synergy_string() -> String:
    var parts := []
    if _effective_split_jet() > 0:
        parts.append("Split %d" % _effective_split_jet())
    if resonant_hits > 0:
        parts.append("Resonate %d" % resonant_hits)
    if stone_circuit > 0:
        parts.append("Circuit %d" % stone_circuit)
    if _effective_pressure_wave() > 0:
        parts.append("Wave %d" % _effective_pressure_wave())
    if _effective_shard_bloom() > 0:
        parts.append("Shards %d" % _effective_shard_bloom())
    if _effective_gem_pulse() > 0:
        parts.append("Echo %d" % _effective_gem_pulse())
    if _effective_tunnel_momentum() > 0:
        parts.append("Momentum %d" % _effective_tunnel_momentum())
    var text := ""
    for i in range(parts.size()):
        if i > 0:
            text += " | "
        text += parts[i]
    return text


func _family_string() -> String:
    var parts := []
    for family in ["lance", "gem", "stone", "motion"]:
        var count := int(family_points.get(family, 0))
        if count > 0:
            parts.append("%s %d" % [_family_label(family), count])
    return _join_strings(parts, " | ")


func _family_label(family: String) -> String:
    match family:
        "lance":
            return "Lance"
        "gem":
            return "Gem"
        "stone":
            return "Stone"
        "motion":
            return "Motion"
        _:
            return family


func _damage_enemy(enemy_i: int, amount: int, kill_text: String, hit_text: String) -> bool:
    if enemy_i < 0 or enemy_i >= enemies.size():
        return false
    var enemy: Dictionary = enemies[enemy_i]
    var resonance_bonus := 0
    if resonant_hits > 0 and enemy["stun"] > 0.0:
        resonance_bonus = resonant_hits
    enemy["phasing"] = false
    enemy["phase_steps"] = 0
    enemy["attack_windup"] = 0.0
    enemy["attack_dir"] = Vector2i.ZERO
    enemy["hit_flash"] = ENEMY_HIT_FLASH
    enemy["hp"] -= amount + resonance_bonus
    enemy["stun"] = 0.72 + _effective_stun_bonus()
    if enemy["hp"] <= 0:
        var dead_pos: Vector2i = enemy["pos"]
        var dead_kind := int(enemy.get("kind", ENEMY_GRUB_KIND))
        floor_kills += 1
        _award_score(80 + floor_index * 10, true, "Rupture")
        enemies.remove_at(enemy_i)
        _drop_xp(dead_pos, 1 + dead_kind)
        _add_rupture_feedback(dead_pos)
        _shake(0.16)
        message = kill_text
        var bloom := _effective_shard_bloom()
        if bloom > 0 and (lance_burst_ready or _lance_overdrive()):
            lance_burst_ready = false
            _burst_nearby_enemies(dead_pos, bloom, 1 + mini(bloom, 2), "Shard bloom!")
        return false
    else:
        _add_pressure_feedback(enemy["pos"], 0.8)
        _shake(0.06)
        message = hit_text if resonance_bonus == 0 else "Resonance hit."
        return true


func _trigger_lance_splash(center: Vector2i, dir: Vector2i, shot_damage: int) -> void:
    var split := _effective_split_jet()
    if split <= 0:
        return
    var side_a := Vector2i(-dir.y, dir.x)
    var side_b := Vector2i(dir.y, -dir.x)
    var sides: Array[Vector2i] = [side_a, side_b]
    var splash_damage := maxi(1, shot_damage - 1 + floori(float(split) / 3.0))
    for side in sides:
        for reach in range(1, mini(split, 2) + 1):
            var pos: Vector2i = center + side * reach
            if not _in_bounds(pos) or _has_rock(pos):
                break
            if not last_attack_cells.has(pos):
                last_attack_cells.append(pos)
            var enemy_i := _enemy_index_at(pos)
            if enemy_i != -1:
                _damage_enemy(enemy_i, splash_damage, "Split burst!", "Split stun.")
                _add_pressure_feedback(pos, 0.75)
                break
            if _tile(pos) == TILE_DIRT:
                break


func _trigger_pressure_wave(center: Vector2i, shot_damage: int) -> void:
    var wave := _effective_pressure_wave()
    if wave <= 0:
        return
    var radius := 1 + mini(wave, 2)
    var damage := maxi(1, floori(float(shot_damage + wave) * 0.34))
    _add_cell_pulse(center, PRESSURE, PULSE_FEEDBACK_TIME + 0.08, 1.0 + float(radius) * 0.35)
    for i in range(enemies.size() - 1, -1, -1):
        if i >= enemies.size():
            continue
        var enemy_pos: Vector2i = enemies[i]["pos"]
        if enemy_pos == center:
            continue
        if _is_behind_lance_target(center, enemy_pos):
            continue
        if enemy_pos.distance_squared_to(center) <= radius * radius:
            _damage_enemy(i, damage, "Pressure chain!", "Wave stun.")


func _burst_nearby_enemies(center: Vector2i, damage: int, radius: int, text: String) -> void:
    _add_cell_pulse(center, RUPTURE, PULSE_FEEDBACK_TIME + 0.1, 0.9 + float(radius) * 0.32, true)
    for i in range(enemies.size() - 1, -1, -1):
        var enemy_pos: Vector2i = enemies[i]["pos"]
        if enemy_pos == center or enemy_pos.distance_squared_to(center) > radius * radius:
            continue
        if _is_behind_lance_target(center, enemy_pos):
            continue
        enemies[i]["hit_flash"] = ENEMY_HIT_FLASH
        enemies[i]["stun"] = maxf(float(enemies[i]["stun"]), 0.35 + _effective_stun_bonus())
        enemies[i]["hp"] -= damage
        if enemies[i]["hp"] <= 0:
            var dead_pos: Vector2i = enemies[i]["pos"]
            var dead_kind := int(enemies[i].get("kind", ENEMY_GRUB_KIND))
            enemies.remove_at(i)
            floor_kills += 1
            _drop_xp(dead_pos, 1 + dead_kind)
            _award_score(70 + floor_index * 8, true, "Burst")
            _add_rupture_feedback(dead_pos)
            _shake(0.14)
            message = text
        else:
            _add_pressure_feedback(enemy_pos, 0.65)


func _is_behind_lance_target(center: Vector2i, pos: Vector2i) -> bool:
    if not lance_has_blocker:
        return false
    if facing == Vector2i.ZERO:
        return false
    var origin := lance_blocking_cell
    var delta := pos - origin
    if facing.x != 0:
        return delta.y == 0 and signi(delta.x) == facing.x
    return delta.x == 0 and signi(delta.y) == facing.y


func _add_dig_feedback(pos: Vector2i) -> void:
    dig_feedback.append({
        "pos": pos,
        "center": _visual_to_center(player_visual_pos) if pos == player_pos else _cell_center(pos),
        "time": DIG_FEEDBACK_TIME,
        "duration": DIG_FEEDBACK_TIME
    })


func _add_pressure_feedback(pos: Vector2i, radius: float) -> void:
    _add_cell_pulse(pos, PRESSURE, PULSE_FEEDBACK_TIME, radius)


func _add_rupture_feedback(pos: Vector2i) -> void:
    _add_cell_pulse(pos, RUPTURE, PULSE_FEEDBACK_TIME + 0.16, 1.25, true)


func _add_cell_pulse(pos: Vector2i, color: Color, duration: float, radius: float, burst := false) -> void:
    pulse_feedback.append({
        "pos": pos,
        "time": duration,
        "duration": duration,
        "radius": radius,
        "color": color,
        "alpha": 0.75,
        "burst": burst
    })


func _stun_enemies_near(center: Vector2i, radius: int, duration: float) -> void:
    var radius_sq := radius * radius
    for enemy in enemies:
        if enemy["phasing"]:
            continue
        var pos: Vector2i = enemy["pos"]
        if pos.distance_squared_to(center) <= radius_sq:
            enemy["attack_windup"] = 0.0
            enemy["attack_dir"] = Vector2i.ZERO
            enemy["stun"] = maxf(enemy["stun"], duration)


func _adjacent_tunnel_count(pos: Vector2i) -> int:
    var count := 0
    for dir in DIRS:
        var next: Vector2i = pos + dir
        if _in_bounds(next) and (_tile(next) == TILE_TUNNEL or _tile(next) == TILE_EXIT):
            count += 1
    return count


func _carve_cell(pos: Vector2i) -> void:
    if _in_bounds(pos):
        _set_tile(pos, TILE_TUNNEL)
        dig_masks[pos] = (1 << DIG_SUBCELL_COUNT) - 1
        tunnel_age[pos] = 0.0
        _clear_soil_rect_px(_cell_center_px(pos), Vector2(CELL, CELL))


func _dig_player_body_path(from: Vector2, to: Vector2) -> void:
    if from.distance_squared_to(to) <= 0.0001:
        _dig_player_body_at(to)
        return
    dig_segments.append({"from": from, "to": to})
    if dig_segments.size() > 1200:
        dig_segments.remove_at(0)
    var samples := maxi(1, ceili(from.distance_to(to) * float(DIG_SUBDIV) * 1.5))
    for i in range(samples + 1):
        var t := float(i) / float(samples)
        _dig_player_body_at(from.lerp(to, t))


func _dig_player_body_at(visual_pos: Vector2) -> void:
    var center_px := _visual_to_board_px(visual_pos)
    var half := PLAYER_DIG_FOOTPRINT * 0.5
    var rect := Rect2(center_px - Vector2(half, half), Vector2(PLAYER_DIG_FOOTPRINT, PLAYER_DIG_FOOTPRINT))
    _clear_soil_rect_px(rect.get_center(), rect.size)

    var min_cell_x := clampi(floori(rect.position.x / CELL), 0, BOARD_W - 1)
    var max_cell_x := clampi(floori((rect.position.x + rect.size.x - 0.001) / CELL), 0, BOARD_W - 1)
    var min_cell_y := clampi(floori(rect.position.y / CELL), 0, BOARD_H - 1)
    var max_cell_y := clampi(floori((rect.position.y + rect.size.y - 0.001) / CELL), 0, BOARD_H - 1)

    for cell_x in range(min_cell_x, max_cell_x + 1):
        for cell_y in range(min_cell_y, max_cell_y + 1):
            var cell := Vector2i(cell_x, cell_y)
            if _tile(cell) != TILE_DIRT:
                continue
            _mark_dug_subcells_in_rect(cell, rect)


func _mark_dug_subcells_in_rect(cell: Vector2i, rect: Rect2) -> void:
    var cell_origin := Vector2(cell.x * CELL, cell.y * CELL)
    var sub_size := float(CELL) / float(DIG_SUBDIV)
    var mask := int(dig_masks.get(cell, 0))
    var previous_count := _bit_count(mask)
    for sy in range(DIG_SUBDIV):
        for sx in range(DIG_SUBDIV):
            var sub_center := cell_origin + Vector2((float(sx) + 0.5) * sub_size, (float(sy) + 0.5) * sub_size)
            if rect.has_point(sub_center):
                mask |= 1 << (sy * DIG_SUBDIV + sx)
    dig_masks[cell] = mask
    var dug_count := _bit_count(mask)
    if dug_count > previous_count and not player_dug_cells.has(cell):
        player_dug_cells[cell] = 0.0
    if _tile(cell) == TILE_DIRT and dug_count >= DIG_PROMOTE_SUBCELLS:
        _promote_dug_cell(cell)


func _promote_dug_cell(cell: Vector2i) -> void:
    _set_tile(cell, TILE_TUNNEL)
    tunnel_age[cell] = 0.0
    _add_dig_feedback(cell)
    _award_score(2, false, "Dig")


func _bit_count(value: int) -> int:
    var count := 0
    var bits := value
    while bits != 0:
        count += bits & 1
        bits = bits >> 1
    return count


func _rebuild_soil_mask_from_grid() -> void:
    soil_image = Image.create_empty(BOARD_PX_W, BOARD_PX_H, false, Image.FORMAT_RGBA8)
    for y in range(BOARD_PX_H):
        for x in range(BOARD_PX_W):
            soil_image.set_pixel(x, y, _soil_color_at(x, y))

    for x in range(BOARD_W):
        for y in range(BOARD_H):
            var pos := Vector2i(x, y)
            if _tile(pos) == TILE_DIRT:
                _clear_dug_subcells_px(pos)
                continue
            _clear_soil_rect_px(_cell_center_px(pos), Vector2(CELL, CELL))
            var right := pos + Vector2i.RIGHT
            var down := pos + Vector2i.DOWN
            if _in_bounds(right) and _tile(right) != TILE_DIRT:
                _clear_soil_rect_between_cells(pos, right)
            if _in_bounds(down) and _tile(down) != TILE_DIRT:
                _clear_soil_rect_between_cells(pos, down)

    soil_texture = ImageTexture.create_from_image(soil_image)
    soil_dirty = false


func _soil_color_at(x: int, y: int) -> Color:
    var depth := float(y) / float(maxi(1, BOARD_PX_H - 1))
    var grain := float((x * 17 + y * 31 + floor_index * 43) % 19) / 18.0
    return DIRT.lerp(DIRT_DARK, depth * 0.46 + grain * 0.045)


func _clear_soil_circle_px(center: Vector2, radius: float) -> void:
    if soil_image == null:
        return
    var min_x := clampi(floori(center.x - radius), 0, BOARD_PX_W - 1)
    var max_x := clampi(ceili(center.x + radius), 0, BOARD_PX_W - 1)
    var min_y := clampi(floori(center.y - radius), 0, BOARD_PX_H - 1)
    var max_y := clampi(ceili(center.y + radius), 0, BOARD_PX_H - 1)
    var radius_sq := radius * radius
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            var delta := Vector2(float(x) + 0.5, float(y) + 0.5) - center
            if delta.length_squared() <= radius_sq:
                soil_image.set_pixel(x, y, Color.TRANSPARENT)
    soil_dirty = true


func _clear_soil_rect_px(center: Vector2, size: Vector2) -> void:
    if soil_image == null:
        return
    var half := size * 0.5
    var min_x := clampi(floori(center.x - half.x), 0, BOARD_PX_W - 1)
    var max_x := clampi(ceili(center.x + half.x), 0, BOARD_PX_W - 1)
    var min_y := clampi(floori(center.y - half.y), 0, BOARD_PX_H - 1)
    var max_y := clampi(ceili(center.y + half.y), 0, BOARD_PX_H - 1)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            soil_image.set_pixel(x, y, Color.TRANSPARENT)
    soil_dirty = true


func _clear_soil_rect_between_cells(a: Vector2i, b: Vector2i) -> void:
    var from := _cell_center_px(a)
    var to := _cell_center_px(b)
    var center := from.lerp(to, 0.5)
    var size := Vector2(CELL, CELL)
    if a.x != b.x:
        size.x = absf(to.x - from.x) + CELL
    if a.y != b.y:
        size.y = absf(to.y - from.y) + CELL
    _clear_soil_rect_px(center, size)


func _clear_dug_subcells_px(cell: Vector2i) -> void:
    var mask := int(dig_masks.get(cell, 0))
    if mask == 0:
        return
    var sub_size := float(CELL) / float(DIG_SUBDIV)
    for sy in range(DIG_SUBDIV):
        for sx in range(DIG_SUBDIV):
            var bit := 1 << (sy * DIG_SUBDIV + sx)
            if (mask & bit) == 0:
                continue
            var center := Vector2(cell.x * CELL + (float(sx) + 0.5) * sub_size, cell.y * CELL + (float(sy) + 0.5) * sub_size)
            _clear_soil_rect_px(center, Vector2(sub_size + 0.5, sub_size + 0.5))


func _clear_soil_capsule_px(from: Vector2, to: Vector2, radius: float) -> void:
    if soil_image == null:
        return
    var min_x := clampi(floori(minf(from.x, to.x) - radius), 0, BOARD_PX_W - 1)
    var max_x := clampi(ceili(maxf(from.x, to.x) + radius), 0, BOARD_PX_W - 1)
    var min_y := clampi(floori(minf(from.y, to.y) - radius), 0, BOARD_PX_H - 1)
    var max_y := clampi(ceili(maxf(from.y, to.y) + radius), 0, BOARD_PX_H - 1)
    var segment := to - from
    var length_sq := segment.length_squared()
    var radius_sq := radius * radius
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            var point := Vector2(float(x) + 0.5, float(y) + 0.5)
            var t := 0.0
            if length_sq > 0.0:
                t = clampf((point - from).dot(segment) / length_sq, 0.0, 1.0)
            var closest := from + segment * t
            if point.distance_squared_to(closest) <= radius_sq:
                soil_image.set_pixel(x, y, Color.TRANSPARENT)
    soil_dirty = true


func _clear_soil_capsule_visual(from: Vector2, to: Vector2, radius: float) -> void:
    _clear_soil_capsule_px(_visual_to_board_px(from), _visual_to_board_px(to), radius)


func _flush_soil_texture() -> void:
    if soil_image == null:
        return
    if soil_texture == null:
        soil_texture = ImageTexture.create_from_image(soil_image)
        soil_dirty = false
    elif soil_dirty:
        soil_texture.update(soil_image)
        soil_dirty = false


func _add_dig_segment(from: Vector2, to: Vector2) -> void:
    if from.distance_squared_to(to) <= 0.0001:
        return
    dig_segments.append({"from": from, "to": to})
    if dig_segments.size() > 1200:
        dig_segments.remove_at(0)
    _clear_soil_capsule_visual(from, to, TUNNEL_HALF_WIDTH)


func _add_room(rooms: Array, center: Vector2i, radius_x: int, radius_y: int) -> void:
    center.x = clampi(center.x, 1, BOARD_W - 2)
    center.y = clampi(center.y, 1, BOARD_H - 2)
    _carve_room(center, radius_x, radius_y)
    rooms.append({
        "center": center,
        "rx": radius_x,
        "ry": radius_y
    })


func _carve_room(center: Vector2i, radius_x: int, radius_y: int) -> void:
    for x in range(center.x - radius_x, center.x + radius_x + 1):
        for y in range(center.y - radius_y, center.y + radius_y + 1):
            _carve_cell(Vector2i(x, y))


func _carve_winding_corridor(start: Vector2i, target: Vector2i, widen_chance: float) -> void:
    var cursor := start
    _carve_cell(cursor)
    var guard := 0
    while cursor != target and guard < 180:
        guard += 1
        var dir := _corridor_step(cursor, target)
        if rng.randf() < 0.14:
            dir = DIRS[rng.randi_range(0, DIRS.size() - 1)]
        cursor += dir
        cursor.x = clampi(cursor.x, 1, BOARD_W - 2)
        cursor.y = clampi(cursor.y, 1, BOARD_H - 2)
        _carve_cell(cursor)
        if rng.randf() < widen_chance:
            var side := Vector2i(-dir.y, dir.x)
            if rng.randf() < 0.5:
                side = -side
            _carve_cell(cursor + side)

    while cursor.x != target.x:
        cursor.x += signi(target.x - cursor.x)
        _carve_cell(cursor)
    while cursor.y != target.y:
        cursor.y += signi(target.y - cursor.y)
        _carve_cell(cursor)


func _corridor_step(cursor: Vector2i, target: Vector2i) -> Vector2i:
    var dx := target.x - cursor.x
    var dy := target.y - cursor.y
    if dx == 0 and dy == 0:
        return Vector2i.ZERO
    if dx == 0:
        return Vector2i(0, signi(dy))
    if dy == 0:
        return Vector2i(signi(dx), 0)
    if rng.randf() < 0.56:
        return Vector2i(signi(dx), 0) if abs(dx) >= abs(dy) else Vector2i(0, signi(dy))
    return Vector2i(0, signi(dy)) if abs(dx) >= abs(dy) else Vector2i(signi(dx), 0)


func _tile(pos: Vector2i) -> int:
    return grid[pos.x][pos.y]


func _set_tile(pos: Vector2i, tile: int) -> void:
    grid[pos.x][pos.y] = tile
    if tile == TILE_DIRT:
        tunnel_age.erase(pos)
        dig_masks.erase(pos)


func _in_bounds(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < BOARD_W and pos.y < BOARD_H


func _has_rock(pos: Vector2i) -> bool:
    for rock in rocks:
        if rock["pos"] == pos:
            return true
    return false


func _has_gem(pos: Vector2i) -> bool:
    for gem_pos in gems:
        if gem_pos == pos:
            return true
    return false


func _has_relic(pos: Vector2i) -> bool:
    for relic in floor_relics:
        if relic["pos"] == pos:
            return true
    return false


func _enemy_index_at(pos: Vector2i) -> int:
    for i in range(enemies.size()):
        if enemies[i]["pos"] == pos:
            return i
    return -1


func _solid_enemy_index_at(pos: Vector2i) -> int:
    for i in range(enemies.size()):
        if enemies[i]["pos"] == pos and not enemies[i]["phasing"] and not bool(enemies[i].get("inflated", false)):
            return i
    return -1


func _cell_to_px(pos: Vector2i) -> Vector2:
    return _board_origin() + Vector2(pos.x * CELL, pos.y * CELL)


func _cell_center_px(pos: Vector2i) -> Vector2:
    return Vector2(pos.x * CELL + CELL * 0.5, pos.y * CELL + CELL * 0.5)


func _open_line_between_cells(from: Vector2i, to: Vector2i) -> bool:
    if not _in_bounds(from) or not _in_bounds(to):
        return false
    if from == to:
        return true
    var from_px := _cell_center_px(from)
    var to_px := _cell_center_px(to)
    var distance := from_px.distance_to(to_px)
    var samples := maxi(2, ceili(distance / 3.0))
    for i in range(samples + 1):
        var t := float(i) / float(samples)
        var point := from_px.lerp(to_px, t)
        if _soil_blocks_point(point):
            return false
    return true


func _soil_blocks_point(point: Vector2) -> bool:
    if soil_image == null:
        return false
    var x := clampi(roundi(point.x), 0, BOARD_PX_W - 1)
    var y := clampi(roundi(point.y), 0, BOARD_PX_H - 1)
    return soil_image.get_pixel(x, y).a > 0.2


func _cell_center(pos: Vector2i) -> Vector2:
    return _cell_to_px(pos) + Vector2(CELL * 0.5, CELL * 0.5)


func _visual_from_pos(pos: Vector2i) -> Vector2:
    return Vector2(float(pos.x), float(pos.y))


func _cell_from_visual(pos: Vector2) -> Vector2i:
    return Vector2i(clampi(floori(pos.x + 0.5), 0, BOARD_W - 1), clampi(floori(pos.y + 0.5), 0, BOARD_H - 1))


func _visual_in_bounds(pos: Vector2) -> bool:
    return pos.x >= 0.0 and pos.y >= 0.0 and pos.x <= float(BOARD_W - 1) and pos.y <= float(BOARD_H - 1)


func _visual_to_board_px(pos: Vector2) -> Vector2:
    return Vector2(pos.x * CELL + CELL * 0.5, pos.y * CELL + CELL * 0.5)


func _visual_to_center(pos: Vector2) -> Vector2:
    return _board_origin() + Vector2(pos.x * CELL + CELL * 0.5, pos.y * CELL + CELL * 0.5)


func _dict_visual(data: Dictionary) -> Vector2:
    if data.has("visual_pos"):
        return data["visual_pos"]
    return _visual_from_pos(data["pos"])


func _board_origin() -> Vector2:
    if screen_shake <= 0.0:
        return BOARD_ORIGIN
    return BOARD_ORIGIN + screen_shake_offset


func _join_strings(parts: Array, separator: String) -> String:
    var text := ""
    for i in range(parts.size()):
        if i > 0:
            text += separator
        text += str(parts[i])
    return text
