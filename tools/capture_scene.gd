extends SceneTree

# Renders a staged gameplay frame to PNG for art review.
# xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/capture_scene.gd -- out_dir

const Game := preload("res://tests/test_game.gd")

var game: Node
var out_dir := "user://captures"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 640)
	game = Game.new()
	root.add_child(game)
	await process_frame
	game.rng.seed = 1201
	seed(1201)
	game._new_run()
	if game.state == game.STATE_CHOOSING:
		game._choose_upgrade(0)
	# Walk the player down and across to carve a visible tunnel.
	var path: Array[Vector2i] = []
	for y in range(1, 9):
		path.append(Vector2i(11, y))
	for x in range(11, 18):
		path.append(Vector2i(x, 8))
	for cell in path:
		game._carve_cell(cell)
		game._dig_player_body_at(game._visual_from_pos(cell))
	game.player_pos = Vector2i(12, 8)
	game.player_visual_pos = game._visual_from_pos(game.player_pos)
	game.player_target_cell = game.player_pos
	game.facing = Vector2i.RIGHT
	game.enemies.clear()
	game._add_enemy(Vector2i(14, 8), game.ENEMY_GRUB_KIND)
	game._add_enemy(Vector2i(17, 8), game.ENEMY_KILN_KIND)
	game._add_enemy(Vector2i(11, 5), game.ENEMY_SHIELDBUG_KIND)
	for e in game.enemies:
		e["timer"] = 99.0
	game.spawn_timer = 999.0
	game._snap_camera_to_player()
	await _frames(4)
	await _shot("01_idle")
	game._press_lance()
	game._update_lance(game.LANCE_HIT_DELAY + 0.01)
	await _frames(3)
	await _shot("02_tap_beat1")
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)
	await _frames(3)
	await _shot("03_tap_beat2")
	game.enemies[0]["hp"] = 9
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)
	await _frames(3)
	await _shot("04_tap_beat3")
	game.enemies[0]["hp"] = 1
	game._update_lance(game.LANCE_PUMP_INTERVAL + 0.01)
	game._update_feedback(0.12)
	await _frames(1)
	await _shot("05_shatter")
	game.state = game.STATE_META
	await _frames(3)
	await _shot("06_hub")
	quit(0)


func _frames(n: int) -> void:
	for i in range(n):
		game.hit_stop_timer = 0.0
		for e in game.enemies:
			e["timer"] = 99.0
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	if game.state != game.STATE_META:
		var focus: Vector2 = game._visual_to_center(game.player_visual_pos)
		var region := Rect2i(Vector2i(focus) - Vector2i(90, 45), Vector2i(240, 110))
		var crop := img.get_region(region)
		crop.resize(960, 440, Image.INTERPOLATE_NEAREST)
		crop.save_png(out_dir.path_join(name + "_zoom.png"))
	print("saved ", name)
