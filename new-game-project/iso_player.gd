extends Node2D
class_name ISO_Player

@export var move_range: int = 4
@export var can_fly: bool = false
@export var move_time_per_tile: float = 0.16

# --- Iso tile footprint ---
const TILE_W: float = 32.0
const TILE_H: float = 16.0
# Use the TileSet's anchor directly (map.map_to_local returns that origin).
# const STAND_OFFSET: Vector2 = Vector2.ZERO
const STAND_OFFSET: Vector2 = Vector2(0.0, -12)

enum Facing { DOWN, LEFT, UP, RIGHT }
enum Action { IDLE, WALK }

@onready var map: TileMapLayer = get_parent().get_node("TileMapLayer")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var cell: Vector2i = Vector2i(3, 3)
var is_moving: bool = false
var _tween: Tween = null

var facing: Facing = Facing.DOWN
var action: Action = Action.IDLE


# ---------------------------
# Position / projection
# ---------------------------

func cell_to_world_center(c: Vector2i) -> Vector2:
	# Center of diamond because you set your TileSet anchor to center
	var local := map.map_to_local(c)
	return map.to_global(local)

func cell_stand_pos(c: Vector2i) -> Vector2:
	return cell_to_world_center(c) + STAND_OFFSET


# ---------------------------
# Facing + animation mapping
# Your existing animation names:
#   walk_down, walk_left
# This code also supports idle_* if you add them later.
# If you don't have idle animations yet, it will just stop on the current frame.
# ---------------------------

func facing_from_dir(d: Vector2i) -> Facing:
	if d == Vector2i(0, 1):  return Facing.DOWN
	if d == Vector2i(-1, 0): return Facing.LEFT
	if d == Vector2i(0, -1): return Facing.UP
	if d == Vector2i(1, 0):  return Facing.RIGHT
	return facing

func _apply_anim() -> void:
	# We only have base art for DOWN and LEFT.
	# RIGHT uses DOWN flipped; UP uses LEFT flipped.
	var base: String
	var flip_h := false

	match facing:
		Facing.DOWN:
			base = "down"
		Facing.LEFT:
			base = "left"
		Facing.RIGHT:
			base = "down"
			flip_h = true
		Facing.UP:
			base = "left"
			flip_h = true

	sprite.flip_h = flip_h

	var anim: String
	match action:
		Action.WALK:
			anim = "walk_%s" % base
		Action.IDLE:
			anim = "idle_%s" % base

	# If you don't have idle_* animations yet, don't error; just stop moving animation.
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
	else:
		# Fallback: no idle anim exists. Stop on current frame.
		if action == Action.IDLE and sprite.is_playing():
			sprite.stop()

func set_action(new_action: Action) -> void:
	if action == new_action:
		return
	action = new_action
	_apply_anim()

func set_facing_from_step(from: Vector2i, to: Vector2i) -> void:
	var d := to - from
	var new_facing := facing_from_dir(d)
	if new_facing != facing:
		facing = new_facing
	_apply_anim()


# ---------------------------
# Lifecycle
# ---------------------------

func _ready() -> void:
	position = cell_stand_pos(cell)
	set_action(Action.IDLE)
	_apply_anim()


# ---------------------------
# Movement
# ---------------------------

func move_along_path(path: Array[Vector2i]) -> void:
	if is_moving:
		return
	if path.size() <= 1:
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	is_moving = true
	set_action(Action.WALK)

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	# Start from the second node (first is current cell)
	var prev_cell: Vector2i = cell
	for i: int in range(1, path.size()):
		var step_cell: Vector2i = path[i]

		# Update facing for this step BEFORE moving
		_tween.tween_callback(Callable(self, "set_facing_from_step").bind(prev_cell, step_cell))

		var step_pos: Vector2 = cell_stand_pos(step_cell)
		_tween.tween_property(self, "position", step_pos, move_time_per_tile)
		_tween.tween_callback(Callable(self, "_on_step_reached").bind(step_cell))

		prev_cell = step_cell

	_tween.finished.connect(_on_move_finished)

func fly_to(target: Vector2i, total_time: float) -> void:
	if is_moving:
		return
	if not can_fly:
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	is_moving = true
	set_action(Action.WALK)

	# Face toward target for the flight (approx: pick dominant axis from delta)
	var d := target - cell
	if abs(d.x) > abs(d.y):
		facing = Facing.RIGHT if d.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if d.y > 0 else Facing.UP
	_apply_anim()

	cell = target

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", cell_stand_pos(target), total_time)
	_tween.finished.connect(_on_move_finished)

func _on_step_reached(step_cell: Vector2i) -> void:
	cell = step_cell

func _on_move_finished() -> void:
	is_moving = false
	set_action(Action.IDLE)

func can_reach(target: Vector2i) -> bool:
	var d: int = absi(target.x - cell.x) + absi(target.y - cell.y)
	return d <= move_range
