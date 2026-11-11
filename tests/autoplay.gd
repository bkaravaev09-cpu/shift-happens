## Headless smoke test: plays every level with a simple scripted bot.
## Run: godot --path . res://tests/autoplay.tscn   (add --headless to skip rendering)
extends Node

var main: Node
var t := 0.0
var lvl_t := 0.0
var last_level := -1
var flags := {}
var shots := OS.get_cmdline_user_args().has("--shots")


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _hold(a: String, on: bool) -> void:
	if on: Input.action_press(a)
	else: Input.action_release(a)


func _tap(a: String) -> void:
	Input.action_press(a)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(a)


func _once(k: String) -> bool:
	if flags.has(k): return false
	flags[k] = true
	return true


func _physics_process(delta: float) -> void:
	t += delta
	lvl_t += delta
	var p: Player = main.player
	if p == null or not is_instance_valid(p):
		return
	if main.level_index != last_level:
		print("LEVEL %d start at %.1fs" % [main.level_index + 1, t])
		last_level = main.level_index
		lvl_t = 0.0
		flags.clear()
		for a in ["move_left", "move_right", "jump"]: _hold(a, false)
	if shots and _once("shot") :
		get_tree().create_timer(0.8).timeout.connect(func(): _shot("level_%d" % (main.level_index + 1)))
	var x := p.position.x
	match main.level_index:
		0:
			_hold("move_right", true)
			# Jump when there is no floor a few voxels ahead, or when blocked.
			var ahead := p.global_transform.translated(Vector3(4, 0.5, 0))
			var pit := p.is_on_floor() and not p.test_move(ahead, Vector3(0, -9, 0)) and x < 560
			_hold("jump", pit or (p.is_on_wall() and absf(p.velocity.x) < 1.0 and fmod(lvl_t, 0.4) < 0.33))
		1:
			_hold("move_right", x < 62)
			if x >= 62 and p.is_on_floor() and _once("s"): _tap("shift_case")
		2:
			if not flags.has("s1"):
				_hold("move_right", x < 30)
				if x >= 30 and p.is_on_floor() and _once("s1"): _tap("shift_case")
			else:
				_hold("move_right", true)
				if x > 34 and p.is_upper and p.position.y < -38 and _once("s2"): _tap("shift_case")
		3:
			if _once("caps"): _tap("caps_world")
			_hold("move_right", true)
			_hold("jump", p.is_on_wall() and fmod(lvl_t, 0.5) < 0.4)
		4:
			if _once("c1"): _tap("caps_world")   # Caps ON - climb the capital ledge
			_hold("move_right", true)
			_hold("jump", p.is_on_wall() and fmod(lvl_t, 0.5) < 0.4)
			if x > 48 and _once("c2"): _tap("caps_world")   # Caps OFF - fit the tunnel
			if x > 72 and p.is_on_floor() and _once("gj"): _tap("jump")   # jump into the goal
	if lvl_t > 60.0:
		print("FAIL: stuck on level %d at %s upper=%s" % [main.level_index + 1, p.position, p.is_upper])
		get_tree().quit(1)
	if main.letter_lines.size() == main.LEVELS.size():
		print("ALL LEVELS DONE in %.1fs" % t)
		print("\n".join(main.letter_lines))
		if shots: await _shot("final")
		get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shot_%s.png" % name)
	print("shot ", name)
