## Interactive props built by Level from special grid characters.
##   ~  water (Pool of Tears)        %  $  Cheshire grins (blink in turns)
##   >  tea tray, rides along its row of ':' track cells (Mad Tea-Party)
##   +  playing card, falls soon after you step on it (The Trial)
class_name Props
extends RefCounted

const WATER := Color(0.36, 0.62, 0.92, 0.45)
const GRIN := Color("c86bfa")
const TRAY := Color("d4a373")
const CARD := Color("f8f4ec")
const CARD_MARK := Color("d62828")


## Thin 6x2 slab at the bottom of a cell (rows 5-6), used by grins, trays and cards.
static func slab_centers(top_left: Vector3, color_rows := 2) -> Array[Vector3]:
	var res: Array[Vector3] = []
	for x in Voxel.CELL_W:
		for y in color_rows:
			res.append(top_left + Vector3(x + 0.5, -(y + 0.5), 0))
	return res


## Builds a transparent water volume for a horizontal run of `len` cells.
static func water_mesh(o: Vector3, len: int) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(len * Voxel.CELL_W, Voxel.CELL_H, Voxel.DEPTH + 0.4)
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WATER
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = o + Vector3(len * Voxel.CELL_W * 0.5, -Voxel.CELL_H * 0.5, 0)
	return m


## A Cheshire grin: a smile-shaped platform that fades in and out.
## Cycle = 2 * period. Each grin is ON for 60% of it; '%' and '$' are offset by one
## period, so for a short moment both are visible — that is when you jump across.
class Grin extends StaticBody3D:
	var phase := 0
	var period := 1.6
	var _shape: CollisionShape3D
	var _mesh: MultiMeshInstance3D
	var _t := 0.0

	func setup(o: Vector3, p: int) -> void:
		phase = p
		var top := o + Vector3(0, -5.0, 0)
		Voxel.add_box(self, top, Vector2(Voxel.CELL_W, 2))
		_shape = get_child(0)
		var c: Array[Vector3] = []
		for x in Voxel.CELL_W:  # smile: corners one voxel higher
			var lift := 1.0 if x == 0 or x == Voxel.CELL_W - 1 else 0.0
			c.append(top + Vector3(x + 0.5, -0.5 + lift, 0))
			c.append(top + Vector3(x + 0.5, -1.5 + lift, 0))
		_mesh = Voxel.build_mesh(c, Props.GRIN)
		add_child(_mesh)
		_update()

	func _physics_process(delta: float) -> void:
		_t += delta
		_update()

	## Seconds since this grin appeared, or -1 when hidden.
	func time_on() -> float:
		var local := fmod(_t - phase * period + 2.0 * period, 2.0 * period)
		return local if local < 1.2 * period else -1.0

	func _update() -> void:
		var on := time_on() >= 0.0
		_shape.disabled = not on
		var left := 1.2 * period - time_on()
		_mesh.visible = on and not (left < 0.4 and fmod(left, 0.12) < 0.06)


## A tea tray that slides back and forth along its row (between `x_min` and `x_max`).
class Tray extends AnimatableBody3D:
	var speed := 14.0
	var _a := 0.0
	var _b := 0.0
	var _dir := 1.0
	var _wait := 0.0
	var pause := 0.7  # seconds to rest at each end of the track

	func setup(o: Vector3, x_min: float, x_max: float) -> void:
		sync_to_physics = false  # we move it ourselves in _physics_process
		var top := Vector3(0, -5.0, 0)
		Voxel.add_box(self, top, Vector2(Voxel.CELL_W, 2))
		add_child(Voxel.build_mesh(Props.slab_centers(top), Props.TRAY))
		position = Vector3(o.x, o.y, 0)
		_a = x_min
		_b = x_max

	func _physics_process(delta: float) -> void:
		if _wait > 0.0:
			_wait -= delta
			return
		position.x += _dir * speed * delta
		if position.x >= _b:
			position.x = _b
			_dir = -1.0
			_wait = pause
		elif position.x <= _a:
			position.x = _a
			_dir = 1.0
			_wait = pause


## A playing card: shakes and falls 0.45 s after being touched, returns after 2.5 s.
class Card extends StaticBody3D:
	var _shape: CollisionShape3D
	var _mesh: Node3D
	var _busy := false

	func setup(o: Vector3) -> void:
		add_to_group("card")
		var top := o + Vector3(0, -5.0, 0)
		Voxel.add_box(self, top, Vector2(Voxel.CELL_W, 2))
		_shape = get_child(0)
		_mesh = Node3D.new()
		add_child(_mesh)
		_mesh.add_child(Voxel.build_mesh(Props.slab_centers(top), Props.CARD))
		var mark: Array[Vector3] = [top + Vector3(3.0, -0.5, 0.2)]
		var red := Voxel.build_mesh(mark, Props.CARD_MARK)
		red.position.z = 0.1
		_mesh.add_child(red)

	func touch() -> void:
		if _busy:
			return
		_busy = true
		var t := create_tween()
		for i in 3:
			t.tween_property(_mesh, "position:x", 0.4, 0.05)
			t.tween_property(_mesh, "position:x", -0.4, 0.05)
		t.tween_property(_mesh, "position:x", 0.0, 0.05)
		t.tween_callback(func() -> void:
			_shape.disabled = true
			_mesh.visible = false)
		t.tween_interval(2.5)
		t.tween_callback(func() -> void:
			_shape.disabled = false
			_mesh.visible = true
			_busy = false)
