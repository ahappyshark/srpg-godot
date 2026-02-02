extends Node2D

@export var cell_size := 64
@export var move_range := 4

var cell := Vector2i(3, 3)

func _ready() -> void:
	update_position()

func set_cell(new_cell: Vector2i) -> void:
	cell = new_cell
	update_position()

func update_position() -> void:
	position = Vector2(cell.x * cell_size, cell.y * cell_size)

func can_reach(target: Vector2i) -> bool:
	var d :int = abs(target.x - cell.x) + abs(target.y - cell.y)
	return d <= move_range
