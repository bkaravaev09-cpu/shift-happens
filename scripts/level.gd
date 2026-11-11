## Loads a level from a .txt file and builds it from voxel letters.
##
## File format:
##   title: Level name
##   hint: Text shown at the top
##   line: Line of the final letter restored by this level
##   ---
##   <grid>   each character = one cell (6x10 voxels)
##
## Grid legend:
##   a-z A-Z ! ? . , -  text terrain (Caps Lock makes all letters uppercase)
##   _  underline bridge at baseline. A single space between two letters
##      becomes "_" automatically, so words read like snake_case and stay walkable.
##      Two or more spaces = a real pit.
##   #  solid ink block (never changes)
##   =  fragile plank (breaks under the UPPERCASE hero)
##   @  player start     *  goal (missing ink drop)
##   ~ % $ > : +  props, see scripts/props.gd (water, grins, tea trays, cards)
class_name Level
extends Node3D

const NON_TEXT := ["#", "=", "@", "*", "_", "~", "%", "$", ">", ":", "+"]

signal completed
signal caps_changed(on: bool)

const INK := Color("2b2d42")
const BLOCK := Color("3d405b")
const PLANK := Color("b08968")
const GOAL := Color("f2b134")

var title := ""
var hint := ""
var line := ""
var caps_on := false
var spawn := Vector3.ZERO
var bottom_y := 0.0

var _cells: Array[Dictionary] = []  # {ch, col, row}
var _water := {}  # Vector2i(col, row) -> true
var _rows: Array[String] = []
var _terrain: Node3D


func load_file(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open level: %s" % path)
		return false
	var in_grid := false
	var row := 0
	while not f.eof_reached():
		var l := f.get_line()
		if not in_grid:
			if l.strip_edges() == "---":
				in_grid = true
			elif l.begins_with("title:"):
				title = l.substr(6).strip_edges()
			elif l.begins_with("hint:"):
				hint = l.substr(5).strip_edges()
			elif l.begins_with("line:"):
				line = l.substr(5).strip_edges()
			continue
		_rows.append(l)
		for col in l.length():
			var ch := l[col]
			if ch == " " and col > 0 and col < l.length() - 1 \
					and _is_text(l[col - 1]) and _is_text(l[col + 1]):
				ch = "_"
			if ch != " ":
				_cells.append({"ch": ch, "col": col, "row": row})
		row += 1
	bottom_y = -row * Voxel.CELL_H - 30.0
	_build_static()
	_build_terrain()
	return true


static func _is_text(ch: String) -> bool:
	return ch != " " and ch not in NON_TEXT


## True if a world position is inside a water cell.
func is_water(p: Vector3) -> bool:
	var cell := Vector2i(floori(p.x / Voxel.CELL_W), floori(-p.y / Voxel.CELL_H))
	return _water.has(cell)


func toggle_caps() -> void:
	caps_on = not caps_on
	_build_terrain()
	caps_changed.emit(caps_on)


## Things that never change: blocks, planks, goal, spawn.
func _build_static() -> void:
	var block_centers: Array[Vector3] = []
	var block_body := StaticBody3D.new()
	add_child(block_body)
	for c in _cells:
		var o := Voxel.cell_origin(c.col, c.row)
		match c.ch:
			"#":
				block_centers.append_array(Voxel.glyph_centers("#", o))
				Voxel.add_box(block_body, o, Vector2(5, 7))
			"=":
				_add_plank(o)
			"@":
				spawn = o + Vector3(3.0, -7.0, 0.0)
			"*":
				_add_goal(o)
			"~":
				_water[Vector2i(c.col, c.row)] = true
			"%", "$":
				var g := Props.Grin.new()
				add_child(g)
				g.setup(o, 0 if c.ch == "%" else 1)
			"+":
				var card := Props.Card.new()
				add_child(card)
				card.setup(o)
			">":
				_add_tray(c.col, c.row)
	_build_water()
	if not block_centers.is_empty():
		add_child(Voxel.build_mesh(block_centers, BLOCK))


func _build_terrain() -> void:
	if _terrain:
		_terrain.queue_free()
	_terrain = Node3D.new()
	add_child(_terrain)
	var body := StaticBody3D.new()
	_terrain.add_child(body)
	var centers: Array[Vector3] = []
	for c in _cells:
		var ch: String = c.ch
		if ch in NON_TEXT and ch != "_":
			continue
		if caps_on:
			ch = ch.to_upper()
		var o := Voxel.cell_origin(c.col, c.row)
		if ch == "_":
			for x in Voxel.CELL_W:
				centers.append(o + Vector3(x + 0.5, -6.5, 0))
			Voxel.add_box(body, o + Vector3(0, -6.0, 0), Vector2(Voxel.CELL_W, 1))
			continue
		centers.append_array(Voxel.glyph_centers(ch, o))
		Voxel.add_glyph_collision(body, ch, o)
	if not centers.is_empty():
		_terrain.add_child(Voxel.build_mesh(centers, INK))


func _build_water() -> void:
	for r in _rows.size():
		var l := _rows[r]
		var col := 0
		while col < l.length():
			if l[col] != "~":
				col += 1
				continue
			var start := col
			while col < l.length() and l[col] == "~":
				col += 1
			add_child(Props.water_mesh(Voxel.cell_origin(start, r), col - start))


## Tray travels over the contiguous run of ':' / '>' cells in its row.
func _add_tray(col: int, row: int) -> void:
	var l := _rows[row]
	var a := col
	while a > 0 and l[a - 1] in [":", ">"]:
		a -= 1
	var b := col
	while b < l.length() - 1 and l[b + 1] in [":", ">"]:
		b += 1
	var t := Props.Tray.new()
	add_child(t)
	t.setup(Voxel.cell_origin(col, row), a * Voxel.CELL_W, b * Voxel.CELL_W)


func _add_plank(o: Vector3) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("fragile")
	add_child(body)
	var top := o + Vector3(0, -6.0, 0)
	Voxel.add_box(body, top, Vector2(6, 2))
	var centers: Array[Vector3] = []
	for x in 6:
		for y in 2:
			centers.append(top + Vector3(x + 0.5, -(y + 0.5), 0))
	body.add_child(Voxel.build_mesh(centers, PLANK))


func _add_goal(o: Vector3) -> void:
	var area := Area3D.new()
	add_child(area)
	Voxel.add_box(area, o, Vector2(Voxel.CELL_W, Voxel.CELL_H))
	var center := o + Vector3(3.0, -5.0, 0.0)
	var centers: Array[Vector3] = []
	for p in [Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, -1, 0)]:
		centers.append(center + p)
	var mesh := Voxel.build_mesh(centers, GOAL)
	area.add_child(mesh)
	var t := mesh.create_tween().set_loops()
	t.tween_property(mesh, "position:y", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(mesh, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	area.body_entered.connect(func(b: Node) -> void:
		if b is Player:
			completed.emit())
