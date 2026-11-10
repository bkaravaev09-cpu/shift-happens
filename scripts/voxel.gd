## Static helpers that turn glyphs into voxel meshes and collision.
## Coordinates: 1 unit = 1 voxel. Level grid cell = CELL_W x CELL_H voxels.
## World Y goes up, so a glyph pixel (x, y) maps to (x, -y).
class_name Voxel
extends RefCounted

const CELL_W := 6
const CELL_H := 10
const DEPTH := 3.0

static var _box_mesh: BoxMesh


static func box_mesh() -> BoxMesh:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3(1.0, 1.0, DEPTH)
	return _box_mesh


static func make_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m


## Builds one MultiMeshInstance3D from a list of voxel centers.
static func build_mesh(centers: Array[Vector3], color: Color) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box_mesh()
	mm.instance_count = centers.size()
	for i in centers.size():
		mm.set_instance_transform(i, Transform3D(Basis(), centers[i]))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = make_material(color)
	return inst


## Voxel centers of a glyph whose cell top-left corner is at `origin`.
static func glyph_centers(c: String, origin: Vector3) -> Array[Vector3]:
	var res: Array[Vector3] = []
	for p in Glyphs.pixels(c):
		res.append(origin + Vector3(p.x + 0.5, -(p.y + 0.5), 0.0))
	return res


## Adds box collision shapes for a glyph to `body` (horizontal runs merged per row).
static func add_glyph_collision(body: CollisionObject3D, c: String, origin: Vector3) -> void:
	if not Glyphs.has(c):
		return
	var rows: Array = Glyphs.DATA[c]
	for y in rows.size():
		var row: String = rows[y]
		var x := 0
		while x < row.length():
			if row[x] != "#":
				x += 1
				continue
			var start := x
			while x < row.length() and row[x] == "#":
				x += 1
			add_box(body, origin + Vector3(start, -y, 0.0), Vector2(x - start, 1.0))
	return


## Adds a box with top-left corner `top_left` and size (w, h) in voxels.
static func add_box(body: CollisionObject3D, top_left: Vector3, size: Vector2) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, size.y, DEPTH)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = top_left + Vector3(size.x * 0.5, -size.y * 0.5, 0.0)
	body.add_child(cs)


## Top-left corner of grid cell (col, row).
static func cell_origin(col: int, row: int) -> Vector3:
	return Vector3(col * CELL_W, -row * CELL_H, 0.0)
