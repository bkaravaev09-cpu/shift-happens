## The hero: a voxel letter. Shift toggles lowercase (small, light, high jump)
## and uppercase (tall, heavy, low jump, breaks '=' planks).
class_name Player
extends CharacterBody3D

signal case_changed(is_upper: bool)

@export var letter := "o"
@export var color := Color("e4572e")
@export var run_speed := 28.0
@export var accel := 220.0
@export var gravity := 200.0
@export var jump_height_lower := 11.0
@export var jump_height_upper := 6.5
@export var coyote_time := 0.1
@export var jump_buffer := 0.12
@export var step_height := 4.5  ## auto step-up over small bumps (spaces, ascenders)

const W := 4.8
const H_LOWER := 4.8
const H_UPPER := 6.8

var is_upper := false
var _shape: BoxShape3D
var _collider: CollisionShape3D
var _visual: Node3D
var _coyote := 0.0
var _buffer := 0.0


func _ready() -> void:
	_shape = BoxShape3D.new()
	_collider = CollisionShape3D.new()
	_collider.shape = _shape
	add_child(_collider)
	_apply_case()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		_coyote -= delta
	else:
		_coyote = coyote_time

	_buffer -= delta
	if Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer
	if _buffer > 0.0 and _coyote > 0.0:
		var h := jump_height_upper if is_upper else jump_height_lower
		velocity.y = sqrt(2.0 * gravity * h)
		_buffer = 0.0
		_coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5  # variable jump height

	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)
	velocity.z = 0.0

	if Input.is_action_just_pressed("shift_case"):
		try_toggle_case()

	_try_step(dir)
	move_and_slide()
	position.z = 0.0
	_check_fragile()


## Walks up ledges lower than step_height instead of stopping at them.
func _try_step(dir: float) -> void:
	if is_zero_approx(dir) or not is_on_floor():
		return
	var fwd := Vector3(signf(dir) * 0.8, 0, 0)
	if not test_move(global_transform, fwd):
		return
	var up := Vector3(0, step_height, 0)
	if test_move(global_transform, up):
		return
	var raised := global_transform.translated(up)
	if test_move(raised, fwd):
		return
	global_position += up + fwd
	move_and_collide(Vector3(0, -step_height, 0))


## Lowercase -> uppercase needs 2 voxels of headroom; shrinking is always allowed.
func try_toggle_case() -> bool:
	if not is_upper and test_move(global_transform, Vector3(0, H_UPPER - H_LOWER, 0)):
		_bump()
		return false
	is_upper = not is_upper
	_apply_case()
	case_changed.emit(is_upper)
	return true


func _apply_case() -> void:
	var h := H_UPPER if is_upper else H_LOWER
	_shape.size = Vector3(W, h, 2.0)
	_collider.position = Vector3(0, h * 0.5, 0)  # origin = feet
	if _visual:
		_visual.queue_free()
	var c := letter.to_upper() if is_upper else letter.to_lower()
	# Glyph baseline is row 6 -> shift so the bottom row sits on the feet.
	var origin := Vector3(-2.5, 7.0, 0.0)
	_visual = Voxel.build_mesh(Voxel.glyph_centers(c, origin), color)
	add_child(_visual)


## Heavy (uppercase) hero breaks fragile planks it stands on.
func _check_fragile() -> void:
	if not is_upper:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var body := col.get_collider() as Node
		if body and body.is_in_group("fragile") and col.get_normal().y > 0.7:
			body.queue_free()


func _bump() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(1.15, 0.85, 1), 0.06)
	t.tween_property(self, "scale", Vector3.ONE, 0.08)
