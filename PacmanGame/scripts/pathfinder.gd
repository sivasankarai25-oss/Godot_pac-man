extends Node
class_name Pathfinder
## Lightweight BFS pathfinding over the maze grid.
## Deliberately NOT a full A*/weighted search -- the maze is small (28x31),
## uniform-cost, and BFS gives optimal shortest paths with simple, readable
## code, per the spec's request for "simple and reliable" AI logic.

const DIRS := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

## Returns the shortest path (list of grid cells, including start and goal)
## from start to goal, or an empty array if unreachable.
## allow_ghost_house: whether the path may pass through ghost-house tiles.
static func find_path(start: Vector2i, goal: Vector2i, allow_ghost_house: bool = false) -> Array[Vector2i]:
	if start == goal:
		return [start]

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: Vector2i(-9999, -9999)}
	var head := 0

	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1

		if current == goal:
			return _reconstruct(came_from, start, goal)

		for d in DIRS:
			var next: Vector2i = current + d
			next = _wrap_tunnel(next)
			if came_from.has(next):
				continue
			if not MazeData.is_walkable(next.x, next.y, allow_ghost_house):
				continue
			came_from[next] = current
			frontier.append(next)

	return [] # unreachable

## Returns just the next step direction (Vector2i) to move from start toward goal.
## Vector2i.ZERO if no path or already at goal.
static func next_direction(start: Vector2i, goal: Vector2i, allow_ghost_house: bool = false) -> Vector2i:
	var path := find_path(start, goal, allow_ghost_house)
	if path.size() < 2:
		return Vector2i.ZERO
	return path[1] - path[0]

## Returns valid movement directions from a cell (used at intersections).
static func valid_directions(cell: Vector2i, allow_ghost_house: bool = false, exclude_reverse: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for d in DIRS:
		if d == -exclude_reverse and exclude_reverse != Vector2i.ZERO:
			continue # ghosts/AI avoid reversing at intersections, classic Pac-Man rule
		var next := _wrap_tunnel(cell + d)
		if MazeData.is_walkable(next.x, next.y, allow_ghost_house):
			options.append(d)
	return options

static func _wrap_tunnel(cell: Vector2i) -> Vector2i:
	if cell.x < 0:
		return Vector2i(Constants.MAZE_COLS - 1, cell.y)
	if cell.x >= Constants.MAZE_COLS:
		return Vector2i(0, cell.y)
	return cell

static func _reconstruct(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := goal
	while current != start:
		path.append(current)
		current = came_from[current]
	path.append(start)
	path.reverse()
	return path

static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
