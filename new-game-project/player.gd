extends Node2D
class_name Player

@export var cell_size: int = 64
@export var move_range: int = 4
@export var can_fly: bool = false
@export var move_time_per_tile: float = 0.08

var cell: Vector2i = Vector2i(3, 3)
var is_moving: bool = false
var _tween: Tween = null

func _ready() -> void:
	position = cell_center(cell)

func move_along_path(path: Array[Vector2i]) -> void:
	if is_moving:
		return
	if path.size() <= 1:
		return

	# Kill any previous tween (safety)
	if _tween != null and _tween.is_valid():
		_tween.kill()

	is_moving = true
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	# Start from the second node (first is current cell)
	for i: int in range(1, path.size()):
		var step_cell: Vector2i = path[i]
		var step_pos: Vector2 = cell_center(step_cell)
		_tween.tween_property(self, "position", step_pos, move_time_per_tile)
		_tween.tween_callback(Callable(self, "_on_step_reached").bind(step_cell))

	_tween.finished.connect(_on_move_finished)

func fly_to(target: Vector2i, total_time: float) -> void:
	if is_moving:
		return
	if not can_fly:
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	is_moving = true
	cell = target

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", cell_center(target), total_time)
	_tween.finished.connect(_on_move_finished)

func _on_step_reached(step_cell: Vector2i) -> void:
	cell = step_cell

func _on_move_finished() -> void:
	is_moving = false

func cell_center(c: Vector2i) -> Vector2:
	var px: float = float(c.x * cell_size + cell_size / 2)
	var py: float = float(c.y * cell_size + cell_size / 2)
	return Vector2(px, py)

func can_reach(target: Vector2i) -> bool:
	var d: int = absi(target.x - cell.x) + absi(target.y - cell.y)
	return d <= move_range
