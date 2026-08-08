extends Node
class_name PacmanAI
## Optional AI driver for Pac-Man (section 2 of the spec). Lightweight,
## rule-based, no ML: at each tile-center decision point it scores nearby
## options using BFS distances to pellets/power-ups/ghosts and picks the
## best direction. Deliberately simple and easy to reason about.

const DANGER_RADIUS: int = 6 # tiles; ghosts within this range are treated as threats
const HUNT_GHOST_RADIUS: int = 8 # in frightened mode, chase ghosts within this range

var _active: bool = false
var _pacman: Pacman
var _maze_manager: MazeManager
var _ghosts: Array = []

func _ready() -> void:
	_pacman = get_parent()
	call_deferred("_late_init")

func _late_init() -> void:
	_maze_manager = get_tree().current_scene.get_node_or_null("MazeManager")
	var ghosts_node := get_tree().current_scene.get_node_or_null("Ghosts")
	if ghosts_node:
		_ghosts = ghosts_node.get_children()

func set_active(value: bool) -> void:
	_active = value

func is_active() -> bool:
	return _active

## Called every physics frame from Pacman when ai_controlled is true.
## Only makes a new decision when Pac-Man is centered on a tile (handled by
## caller passing current move_dir; if a further move is possible we keep it).
func get_desired_direction(current_cell: Vector2i, current_move_dir: Vector2i) -> Vector2i:
	var options := Pathfinder.valid_directions(current_cell, false, current_move_dir)
	if options.is_empty():
		# Dead end: allow reversal as the only escape.
		options = Pathfinder.valid_directions(current_cell, false, Vector2i.ZERO)
		if options.is_empty():
			return Vector2i.ZERO

	var in_power_mode := GameManager.current_state == GameManager.State.POWER_MODE
	var best_dir: Vector2i = current_move_dir if current_move_dir in options else options[0]
	var best_score: float = -INF

	for dir in options:
		var candidate_cell := current_cell + dir
		var score := _score_direction(candidate_cell, in_power_mode)
		if score > best_score:
			best_score = score
			best_dir = dir

	return best_dir

func _score_direction(cell: Vector2i, in_power_mode: bool) -> float:
	var score: float = 0.0

	# 1. Ghost proximity: avoid dangerous ghosts, seek frightened ones.
	for ghost in _ghosts:
		if not is_instance_valid(ghost):
			continue
		var ghost_cell: Vector2i = ghost.get_grid_position()
		var dist := Pathfinder.manhattan_distance(cell, ghost_cell)
		var ghost_is_dangerous: bool = ghost.current_mode == Ghost.Mode.CHASE or ghost.current_mode == Ghost.Mode.SCATTER
		if ghost_is_dangerous and dist <= DANGER_RADIUS:
			score -= float(DANGER_RADIUS - dist) * 40.0
		elif ghost.current_mode == Ghost.Mode.FRIGHTENED and dist <= HUNT_GHOST_RADIUS:
			score += float(HUNT_GHOST_RADIUS - dist) * 15.0

	# 2. Pellet seeking: prefer directions that lead toward the nearest pellet.
	var nearest_pellet := _find_nearest_pellet(cell)
	if nearest_pellet != Vector2i(-1, -1):
		var pellet_dist := Pathfinder.manhattan_distance(cell, nearest_pellet)
		score -= float(pellet_dist) * 2.0

	# 3. Slight bonus for continuing to be near power pellets when ghosts are close but not adjacent
	# (encourages using power-ups strategically rather than always beelining the closest dot).

	return score

func _find_nearest_pellet(from_cell: Vector2i) -> Vector2i:
	if not _maze_manager:
		return Vector2i(-1, -1)
	var best_cell := Vector2i(-1, -1)
	var best_dist := 999999
	# Scan the maze layout directly for remaining pellets near the search cell,
	# widening the search window if nothing found nearby (cheap for a 28x31 grid).
	for radius in [8, 16, 40]:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var c := from_cell + Vector2i(dx, dy)
				if not _maze_manager.has_pellet_at(c):
					continue
				var d: int = abs(dx) + abs(dy)
				if d < best_dist:
					best_dist = d
					best_cell = c
		if best_cell != Vector2i(-1, -1):
			break
	return best_cell
