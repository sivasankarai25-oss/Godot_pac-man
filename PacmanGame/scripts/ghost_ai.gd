extends Node
class_name GhostAI
## Personality-driven targeting for one ghost (section 3 of the spec).
## Each personality only differs in HOW it picks a target tile; the actual
## pathing to that tile uses the same BFS-based direction choice for all
## ghosts, so behavior differences come from targeting logic, matching how
## the original game's ghosts work.

enum Personality { CHASER, AMBUSHER, STRATEGIST, SHY }

@export var personality: Personality = Personality.CHASER

const SHY_FLEE_DISTANCE: int = 8 # tiles; Orange-ghost-style: flee if closer than this

var _ghost: Ghost
var _pacman_ref: Node

func _ready() -> void:
	_ghost = get_parent()
	call_deferred("_late_init")

func _late_init() -> void:
	_pacman_ref = get_tree().current_scene.get_node_or_null("Pacman")

## Returns the direction the ghost should move this tile, or Vector2i.ZERO
## if it should stay (e.g. still waiting in house).
func decide_direction(current_cell: Vector2i, current_move_dir: Vector2i, mode: Ghost.Mode, scatter_corner: Vector2i, allow_house: bool) -> Vector2i:
	if mode == Ghost.Mode.IN_HOUSE:
		return Vector2i.ZERO

	var options := Pathfinder.valid_directions(current_cell, allow_house, current_move_dir)
	if options.is_empty():
		options = Pathfinder.valid_directions(current_cell, allow_house, Vector2i.ZERO)
		if options.is_empty():
			return Vector2i.ZERO

	var target: Vector2i

	match mode:
		Ghost.Mode.EATEN:
			# Head all the way back to the ghost's own house spawn cell (not just
			# the door) so the "reached home" check in ghost.gd can compare
			# against the same cell it targets here.
			target = _ghost.get_house_cell()
			return _best_direction_toward(current_cell, target, options, true)
		Ghost.Mode.EXITING:
			# Walk from the house interior out through the door into the open maze.
			target = _get_exit_target(current_cell)
			return _best_direction_toward(current_cell, target, options, true)
		Ghost.Mode.FRIGHTENED:
			# Frightened ghosts move semi-randomly but avoid Pac-Man; pick the
			# option that maximizes distance from Pac-Man for a "fleeing" feel.
			return _flee_direction(current_cell, options)
		Ghost.Mode.SCATTER:
			target = scatter_corner
			return _best_direction_toward(current_cell, target, options, false)
		Ghost.Mode.CHASE:
			target = _get_chase_target(current_cell)
			return _best_direction_toward(current_cell, target, options, false)

	return options[0]

func _get_chase_target(ghost_cell: Vector2i) -> Vector2i:
	if not _pacman_ref or not is_instance_valid(_pacman_ref):
		return ghost_cell

	var pac_cell: Vector2i = _pacman_ref.get_grid_position()
	var pac_dir: Vector2i = _pacman_ref.move_dir

	match personality:
		Personality.CHASER:
			# Red ghost: direct pursuit, targets Pac-Man's current tile.
			return pac_cell

		Personality.AMBUSHER:
			# Pink ghost: targets several tiles ahead of Pac-Man's current
			# direction, trying to intercept rather than tail him.
			var lookahead := 4
			var predicted := pac_cell + pac_dir * lookahead
			return _clamp_to_maze(predicted)

		Personality.STRATEGIST:
			# Blue ghost: targets a point that mixes Pac-Man's position with
			# the Red (chaser) ghost's position, producing flanking routes --
			# a simplified stand-in for the original "vector doubling" trick.
			var chaser := _find_ghost_by_personality(Personality.CHASER)
			if chaser and is_instance_valid(chaser):
				var chaser_cell: Vector2i = chaser.get_grid_position()
				var pivot := pac_cell + pac_dir * 2
				var vec := pivot - chaser_cell
				return _clamp_to_maze(chaser_cell + vec * 2)
			return pac_cell

		Personality.SHY:
			# Orange ghost: chases when far away, but flees toward its scatter
			# corner when it gets close, making it behave erratically.
			var dist := Pathfinder.manhattan_distance(ghost_cell, pac_cell)
			if dist > SHY_FLEE_DISTANCE:
				return pac_cell
			else:
				return _ghost.scatter_corner

	return pac_cell

func _clamp_to_maze(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, Constants.MAZE_COLS - 1),
		clampi(cell.y, 0, Constants.MAZE_ROWS - 1)
	)

## Target used while a ghost is walking out of the house at round start.
## Head for the door cell first; once the ghost is standing on or above the
## door (no longer on a 'G' tile), _process_movement flips it out of
## EXITING mode, so this only ever needs to point at the door itself.
func _get_exit_target(_current_cell: Vector2i) -> Vector2i:
	var door := MazeData.find_first("-")
	if door != Vector2i(-1, -1):
		return door
	return _ghost.get_house_cell()

func _find_ghost_by_personality(target_personality: Personality) -> Ghost:
	var ghosts_node := get_tree().current_scene.get_node_or_null("Ghosts")
	if not ghosts_node:
		return null
	for g in ghosts_node.get_children():
		if g.ai and g.ai.personality == target_personality:
			return g
	return null

## Picks the option direction whose resulting cell has the shortest BFS
## path to target. use_bfs_full does a real path search (needed for EATEN
## so eyes correctly navigate back through the door); otherwise we use a
## cheap manhattan-distance heuristic per option for performance, since
## ghosts recompute every tile and the maze is small either way.
func _best_direction_toward(current_cell: Vector2i, target: Vector2i, options: Array[Vector2i], use_bfs_full: bool) -> Vector2i:
	var best_dir: Vector2i = options[0]
	var best_dist: float = INF

	for dir in options:
		var candidate := current_cell + dir
		var dist: float
		if use_bfs_full:
			var path := Pathfinder.find_path(candidate, target, true)
			dist = path.size() if not path.is_empty() else 99999.0
		else:
			dist = Pathfinder.manhattan_distance(candidate, target)
		if dist < best_dist:
			best_dist = dist
			best_dir = dir

	return best_dir

func _flee_direction(current_cell: Vector2i, options: Array[Vector2i]) -> Vector2i:
	if not _pacman_ref or not is_instance_valid(_pacman_ref):
		return options[randi() % options.size()]
	var pac_cell: Vector2i = _pacman_ref.get_grid_position()
	var best_dir: Vector2i = options[0]
	var best_dist: float = -INF
	for dir in options:
		var candidate := current_cell + dir
		var dist := Pathfinder.manhattan_distance(candidate, pac_cell)
		if dist > best_dist:
			best_dist = dist
			best_dir = dir
	return best_dir
