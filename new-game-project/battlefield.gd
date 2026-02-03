extends Node2D

@export var cols: int = 8
@export var rows: int = 8
@export var cell_size: int = 32
@export var damage_penalty: int = 6

@onready var player: Player = $Player

var hover_cell: Vector2i = Vector2i(-1, -1)
var valid_cells: Array[Vector2i] = []

var came_from: Dictionary = {} # Dictionary[Vector2i, Vector2i]
var preview_path: Array[Vector2i] = []


# Use a set-like Dictionary: keys are blocked cells, value is true.
var blocked: Dictionary = {} # Dictionary[Vector2i, bool]
var damage: Dictionary = {} # Dictionary[Vector2i, bool]


func _process(_dt: float) -> void:
	hover_cell = world_to_cell(get_global_mouse_position())
	valid_cells = get_valid_move_cells()
	if hover_cell == player.cell:
		preview_path = []
	else:
		preview_path = get_move_path(hover_cell)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var c: Vector2i = world_to_cell(get_global_mouse_position())
		if not is_in_bounds(c):
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if c == player.cell:
				return

			if event.shift_pressed:
				# damage tiles are walkable, but "dangerous"
				set_damage(c, not is_damage(c))
			else:
				# blocked tiles are impassable (unless flying, later)
				set_blocked(c, not is_blocked(c))
				# optional: if you block a tile, clear damage on it
				if is_blocked(c):
					set_damage(c, false)
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if player.is_moving:
				return

			if is_valid_move_cell(c):
				if player.can_fly and event.ctrl_pressed:
					# fly directly (time scales a bit with distance)
					var path: Array[Vector2i] = get_move_path(c)
					var steps: int = max(1, path.size() - 1)
					player.fly_to(c, float(steps) * player.move_time_per_tile)
				else:
					var path2: Array[Vector2i] = get_move_path(c)
					player.move_along_path(path2)

func world_to_cell(world: Vector2) -> Vector2i:
	var local: Vector2 = to_local(world)
	var cx: int = int(floor(local.x / float(cell_size)))
	var cy: int = int(floor(local.y / float(cell_size)))
	return Vector2i(cx, cy)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x * cell_size), float(cell.y * cell_size))

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows

func is_blocked(cell: Vector2i) -> bool:
	return blocked.has(cell)

func set_blocked(cell: Vector2i, value: bool) -> void:
	if value:
		blocked[cell] = true
	else:
		blocked.erase(cell)

func is_damage(cell: Vector2i) -> bool:
	return damage.has(cell)

func set_damage(cell: Vector2i, value: bool) -> void:
	if value:
		damage[cell] = true
	else:
		damage.erase(cell)

func is_valid_move_cell(cell: Vector2i) -> bool:
	return valid_cells.has(cell)

func get_valid_move_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var visited: Dictionary = {} # Dictionary[Vector2i, bool]

	came_from.clear()

	var start: Vector2i = player.cell
	var max_steps: int = player.move_range

	# best_score[cell] = cheapest (steps + penalties) found so far
	var best_score: Dictionary = {} # Dictionary[Vector2i, int]
	# best_steps[cell] = steps used for that best_score
	var best_steps: Dictionary = {} # Dictionary[Vector2i, int]

	best_score[start] = 0
	best_steps[start] = 0
	came_from[start] = start

	var open: Array[Vector2i] = [start]

	while open.size() > 0:
		# pick the open cell with the lowest score
		var current: Vector2i = open[0]
		var current_score: int = int(best_score[current])

		for i: int in range(1, open.size()):
			var c: Vector2i = open[i]
			var s: int = int(best_score[c])
			if s < current_score:
				current = c
				current_score = s

		open.erase(current)
		if visited.has(current):
			continue
		visited[current] = true
		out.append(current)

		out.append(current)

		var steps_used: int = int(best_steps[current])
		if steps_used >= max_steps:
			continue

		var neighbors: Array[Vector2i] = [
			current + Vector2i(1, 0),
			current + Vector2i(-1, 0),
			current + Vector2i(0, 1),
			current + Vector2i(0, -1),
		]

		for n: Vector2i in neighbors:
			if not is_in_bounds(n):
				continue

			# if not flying, blocked tiles are impassable
			if (not player.can_fly) and is_blocked(n):
				continue

			var next_steps: int = steps_used + 1
			if next_steps > max_steps:
				continue

			# base score is current score + 1 step
			var extra: int = 1

			# damage is allowed, but "expensive" so it gets avoided if possible
			if is_damage(n):
				extra += damage_penalty

			var next_score: int = current_score + extra

			if not best_score.has(n) or next_score < int(best_score[n]):
				best_score[n] = next_score
				best_steps[n] = next_steps
				came_from[n] = current
				if not open.has(n):
					open.append(n)

	return out

func get_move_path(target: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	if not valid_cells.has(target):
		return path
	if not came_from.has(target):
		return path

	var start: Vector2i = player.cell
	var current: Vector2i = target

	while true:
		path.append(current)
		if current == start:
			break
		current = came_from[current]

	path.reverse()
	return path


func _draw() -> void:
	# Highlight reachable cells
	for c: Vector2i in valid_cells:
		var p: Vector2 = cell_to_world(c)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(0.2, 0.8, 1.0, 0.10), true)

	# draw damage cells
	for key in damage.keys():
		var c: Vector2i = key
		var p: Vector2 = cell_to_world(c)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), Color(1.0, 0.2, 0.2, 0.20), true)

	# Preview path (stronger fill)
	for c: Vector2i in preview_path:
		var p: Vector2 = cell_to_world(c)

		var fill: Color = Color(1.0, 1.0, 1.0, 0.10)
		var outline: Color = Color(1.0, 1.0, 1.0, 0.35)

		if is_damage(c):
			fill = Color(1.0, 0.25, 0.25, 0.12)
			outline = Color(1.0, 0.25, 0.25, 0.45)

		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), fill, true)
		draw_rect(Rect2(p, Vector2(cell_size, cell_size)), outline, false, 2.0)

	# draw blocked cells
	for key in blocked.keys():
		var c2: Vector2i = key
		var p2: Vector2 = cell_to_world(c2)
		draw_rect(Rect2(p2, Vector2(cell_size, cell_size)), Color(0.0, 0.0, 0.0, 0.35), true)
		draw_rect(Rect2(p2, Vector2(cell_size, cell_size)), Color(0.0, 0.0, 0.0, 0.8), false, 2.0)	

	# Grid lines
	for x: int in range(cols + 1):
		draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, rows * cell_size), Color(1, 1, 1, 0.25))
	for y: int in range(rows + 1):
		draw_line(Vector2(0, y * cell_size), Vector2(cols * cell_size, y * cell_size), Color(1, 1, 1, 0.25))

	# Hover highlight
	if is_in_bounds(hover_cell):
		var p3: Vector2 = cell_to_world(hover_cell)
		draw_rect(Rect2(p3, Vector2(cell_size, cell_size)), Color(1, 1, 1, 0.12), true)
		draw_rect(Rect2(p3, Vector2(cell_size, cell_size)), Color(1, 1, 1, 0.5), false, 2.0)
