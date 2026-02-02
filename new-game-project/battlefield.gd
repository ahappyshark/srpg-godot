extends Node2D

@export var cols: int = 8
@export var rows: int = 8
@export var cell_size: int = 64

@onready var player = $Player

var hover_cell := Vector2i(-1, -1)
var valid_cells: Array[Vector2i] = []
var blocked: Dictionary = {} # Dictionary[Vector2i, bool]


func _process(_dt: float) -> void:
	hover_cell = world_to_cell(get_global_mouse_position())
	valid_cells = get_valid_move_cells()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var c: Vector2i = world_to_cell(get_global_mouse_position())
		if not is_in_bounds(c):
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			# don't let you block the player's current cell
			if c != player.cell:
				set_blocked(c, not is_blocked(c))
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_valid_move_cell(c):
				player.set_cell(c)

func world_to_cell(world: Vector2) -> Vector2i:
	var local = to_local(world)
	return Vector2i(floor(local.x / cell_size), floor(local.y / cell_size))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows

func is_valid_move_cell(cell: Vector2i) -> bool:
	return valid_cells.has(cell) and not is_blocked(cell)

func get_valid_move_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	var start: Vector2i = player.cell
	var max_cost: int = player.move_range

	# cost_so_far[cell] = steps to reach
	var cost_so_far: Dictionary = {}
	cost_so_far[start] = 0

	var q: Array[Vector2i] = [start]

	while q.size() > 0:
		var current: Vector2i = q.pop_front()
		var current_cost: int = int(cost_so_far[current])

		# include current as reachable (you can decide later if you want to exclude start)
		out.append(current)

		# stop expanding if we've reached max range
		if current_cost >= max_cost:
			continue

		var neighbors: Array[Vector2i] = [
			current + Vector2i(1, 0),
			current + Vector2i(-1, 0),
			current + Vector2i(0, 1),
			current + Vector2i(0, -1),
		]

		for n in neighbors:
			if not is_in_bounds(n):
				continue
			if is_blocked(n):
				continue
			if cost_so_far.has(n):
				continue

			cost_so_far[n] = current_cost + 1
			q.append(n)

	return out
func is_blocked(cell: Vector2i) -> bool:
	return blocked.has(cell)

func set_blocked(cell: Vector2i, value: bool) -> void:
	if value:
		blocked[cell] = true
	else:
		blocked.erase(cell)
func _draw() -> void:
	# Highlight valid cells (soft fill)
	for c in valid_cells:
		var p = cell_to_world(c)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(0.2, 0.8, 1.0, 0.10), true)

	# draw blocked cells
	for key in blocked.keys():
		var c: Vector2i = key
		var p: Vector2 = cell_to_world(c)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(0.0, 0.0, 0.0, 0.35), true)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(0.0, 0.0, 0.0, 0.8), false, 2.0)
	# Grid lines
	for x in range(cols + 1):
		draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, rows * cell_size), Color(1,1,1,0.25))
	for y in range(rows + 1):
		draw_line(Vector2(0, y * cell_size), Vector2(cols * cell_size, y * cell_size), Color(1,1,1,0.25))

	# Hover highlight (stronger border)
	if is_in_bounds(hover_cell):
		var p = cell_to_world(hover_cell)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(1,1,1,0.12), true)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(1,1,1,0.5), false, 2.0)
