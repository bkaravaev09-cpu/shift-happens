## Headless bot test: plays levels with a simple scripted policy.
## Run all:  godot --headless --path . res://tests/autoplay.tscn
## One:      godot --headless --path . res://tests/autoplay.tscn -- --level=5
## Negative: add --skip=shift (or caps) to check a level FAILS without that mechanic.
##
## Bot = hold right, jump at pits/walls, fire scripted EVENTS once x >= threshold.
## Event keys: x (threshold), act ("shift"|"caps"|"jump"|"hop" = short jump), floor (wait until grounded),
##             sync (jump only right after a Cheshire grin of that phase appears),
##             tray ([index, x_min, x_max] wait until that tea tray is in range),
##             upper (only if hero case matches), below (only if hero y < value),
##             hold (seconds to stand still after firing).
## Start mid-game: --from=N (plays N..last).
extends Node

const EVENTS := {
	1: {"no_jump_after": 560.0, "ev": []},
	2: {"ev": [{"x": 62, "act": "shift", "floor": true, "hold": 1.5}]},
	3: {"ev": [{"x": 30, "act": "shift", "floor": true, "hold": 1.0},
			{"x": 34, "act": "shift", "upper": true, "below": -38.0}]},
	4: {"ev": [{"x": 0, "act": "caps"}]},
	5: {"ev": []},
	7: {"ev": [{"x": 104, "act": "jump", "floor": true, "sync": 1},
			{"x": 124, "act": "jump", "floor": true, "sync": 0},
			{"x": 142, "act": "jump", "floor": true, "sync": 1},
			{"x": 160, "act": "jump", "floor": true, "sync": 0},
			{"x": 178, "act": "jump", "floor": true}]},
	8: {"ev": [{"x": 96, "act": "jump", "floor": true, "tray": [0, 113, 115]},
			{"x": 110, "act": "hop", "floor": true, "tray": [1, 167, 169]},
			{"x": 165, "act": "jump", "floor": true, "tray": [1, 209, 211]}]},
	9: {"ev": []},
	10: {"ev": [{"x": 0, "act": "caps"},
			{"x": 128, "act": "caps"},
			{"x": 238, "act": "shift", "floor": true, "hold": 1.5}]},
	6: {"ev": [{"x": 88, "act": "shift", "upper": false},
			{"x": 154, "act": "shift", "upper": true}]},
}

var main: Node
var t := 0.0
var lvl_t := 0.0
var last_level := -1
var fired := {}
var hold_until := 0.0
var manual_jump_until := 0.0
var only := -1
var from := -1
var skip := ""
var shots := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="): only = int(a.substr(8))
		if a.begins_with("--skip="): skip = a.substr(7)
		if a.begins_with("--from="): from = int(a.substr(7))
		if a == "--shots": shots = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if only > 0:
		main._load_level(only - 1)
	elif from > 0:
		main._load_level(from - 1)


func _press(a: String, on: bool) -> void:
	if on: Input.action_press(a)
	else: Input.action_release(a)


func _tap(a: String) -> void:
	Input.action_press(a)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(a)


func _physics_process(delta: float) -> void:
	t += delta
	lvl_t += delta
	var p: Player = main.player
	if p == null or not is_instance_valid(p):
		return
	var n: int = main.level_index + 1
	if only > 0 and main.letter_lines.size() > 0:
		_finish("LEVEL %d DONE in %.1fs" % [only, t])
		return
	if main.level.get_instance_id() != last_level:  # new level or respawn
		print("LEVEL %d start at %.1fs" % [n, t])
		last_level = main.level.get_instance_id()
		lvl_t = 0.0
		fired.clear()
		hold_until = 0.0
		manual_jump_until = 0.0
		for a in ["move_left", "move_right", "jump"]: _press(a, false)
		if shots:
			get_tree().create_timer(0.8).timeout.connect(func() -> void: _shot("level_%d" % n))
	var cfg: Dictionary = EVENTS.get(n, {"ev": []})
	var x := p.position.x
	var waiting := false
	var evs: Array = cfg.ev
	for i in evs.size():
		var e: Dictionary = evs[i]
		if fired.has(i) or x < float(e.x):
			continue
		if e.has("upper") and p.is_upper != bool(e.upper): continue
		if e.has("below") and p.position.y > float(e.below): continue
		if e.get("floor", false) and not p.is_on_floor():
			waiting = true
			break
		if e.has("tray") and not _tray_in(e.tray):
			waiting = true
			break
		if e.has("sync") and not _grin_fresh(int(e.sync)):
			waiting = true
			break
		fired[i] = true
		hold_until = lvl_t + float(e.get("hold", 0.0))
		var act: String = e.act
		if act == skip: continue
		if act == "shift": _tap("shift_case")
		elif act == "caps": main.level.toggle_caps()  # direct: synthetic just_pressed can be missed on a load frame
		elif act == "jump": manual_jump_until = lvl_t + 0.3
		elif act == "hop": manual_jump_until = lvl_t + 0.06
		break
	var moving := not waiting and lvl_t >= hold_until
	_press("move_right", moving)
	var ahead := p.global_transform.translated(Vector3(4, 0.5, 0))
	var pit := moving and p.is_on_floor() and not p.test_move(ahead, Vector3(0, -9, 0)) \
			and x < float(cfg.get("no_jump_after", 1e9))
	var wall := moving and p.is_on_wall() and absf(p.velocity.x) < 1.0 and fmod(lvl_t, 0.4) < 0.33
	_press("jump", pit or wall or lvl_t < manual_jump_until)
	if lvl_t > 60.0:
		_finish("FAIL: stuck on level %d at %s upper=%s" % [n, p.position.snapped(Vector3.ONE * 0.1), p.is_upper], 1)
	elif main.letter_lines.size() == main.LEVELS.size():
		print("\n".join(main.letter_lines))
		_finish("ALL LEVELS DONE in %.1fs" % t)


func _grin_fresh(phase: int) -> bool:
	for g in main.level.get_children():
		if g is Props.Grin and g.phase == phase:
			var on: float = g.time_on()
			return on > 0.02 and on < 0.25
	return false


## tray = [index, x_min, x_max]: wait until that tray's x is inside the range.
func _tray_in(spec: Array) -> bool:
	var trays: Array = main.level.get_children().filter(func(n: Node) -> bool: return n is Props.Tray)
	var tr: Node3D = trays[int(spec[0])]
	return tr.position.x >= float(spec[1]) and tr.position.x <= float(spec[2])



func _finish(msg: String, code := 0) -> void:
	print(msg)
	set_physics_process(false)
	if shots: await _shot("final")
	get_tree().quit(code)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shot_%s.png" % name)
