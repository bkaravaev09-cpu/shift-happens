## Game flow: input map, camera, lighting, UI and level sequence.
extends Node3D

const LEVELS: Array[String] = [
	"res://levels/level_01.txt",
	"res://levels/level_02.txt",
	"res://levels/level_03.txt",
	"res://levels/level_04.txt",
]
const PAPER := Color("f1e6cf")

var level_index := 0
var level: Level
var player: Player
var camera: Camera3D
var hint_label: Label
var letter_lines: Array[String] = []
var _transitioning := false


func _ready() -> void:
	_setup_input()
	_setup_world()
	_setup_ui()
	_load_level(0)


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"shift_case": [KEY_SHIFT],
		"caps_world": [KEY_CAPSLOCK, KEY_TAB],
		"restart": [KEY_R],
	}
	for action: String in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _setup_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PAPER
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = PAPER
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)

	# Paper sheet behind the letters so they cast shadows on it.
	var paper := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4000, 4000)
	paper.mesh = plane
	paper.rotation_degrees = Vector3(90, 0, 0)
	paper.position = Vector3(0, 0, -3.0)
	paper.material_override = Voxel.make_material(PAPER.darkened(0.05))
	add_child(paper)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 70.0
	camera.rotation_degrees = Vector3(-10, 12, 0)
	add_child(camera)


func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	hint_label = Label.new()
	hint_label.position = Vector2(8, 6)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color("2b2d42"))
	ui.add_child(hint_label)


func _load_level(i: int) -> void:
	if level:
		level.queue_free()
	if player:
		player.queue_free()
	level_index = i
	level = Level.new()
	add_child(level)
	level.load_file(LEVELS[i])
	level.completed.connect(_on_level_completed)
	player = Player.new()
	add_child(player)
	player.position = level.spawn
	camera.position = _camera_target()
	hint_label.text = "%s\n%s" % [level.title, level.hint]
	_transitioning = false


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if Input.is_action_just_pressed("caps_world"):
		level.toggle_caps()
	if Input.is_action_just_pressed("restart") or player.position.y < level.bottom_y:
		_load_level(level_index)
		return
	camera.position = camera.position.lerp(_camera_target(), 1.0 - exp(-6.0 * delta))


func _camera_target() -> Vector3:
	var p := player.position if player else Vector3.ZERO
	# Offset back along the camera's view direction so the tilt stays centered.
	return p + Vector3(0, 6, 0) + camera.basis.z * 100.0


func _on_level_completed() -> void:
	if _transitioning:
		return
	_transitioning = true
	letter_lines.append(level.line)
	if level_index + 1 < LEVELS.size():
		hint_label.text = "\"%s\"" % level.line
		await get_tree().create_timer(1.2).timeout
		_load_level(level_index + 1)
	else:
		hint_label.text = "\n".join(letter_lines) + "\n\nThe end. Thanks for playing!"
