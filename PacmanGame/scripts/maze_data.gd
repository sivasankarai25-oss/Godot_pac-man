extends Node
class_name MazeData
## Static maze layout data. 28 cols x 31 rows, classic arcade proportions.
## Legend:
##  '#' wall        '.' pellet        'o' power pellet (frightened trigger)
##  ' ' empty path  '-' ghost door    'T' tunnel (screen-warp) opening
##  'P' pacman spawn 'G' ghost house area (walkable, ghosts only)

const LAYOUT: Array[String] = [
	"############################",
	"#............##............#",
	"#.####.#####.##.#####.####.#",
	"#o####.#####.##.#####.####o#",
	"#.####.#####.##.#####.####.#",
	"#..........................#",
	"#.####.##.########.##.####.#",
	"#.####.##.########.##.####.#",
	"#......##....##....##......#",
	"######.##### ## #####.######",
	"     #.##### ## #####.#     ",
	"     #.##          ##.#     ",
	"     #.## ###--### ##.#     ",
	"######.## #GGGGGG# ##.######",
	"T     .   #GGGGGG#   .     T",
	"######.## #GGGGGG# ##.######",
	"     #.## ######## ##.#     ",
	"     #.##          ##.#     ",
	"     #.## ######## ##.#     ",
	"######.## ######## ##.######",
	"#............##............#",
	"#.####.#####.##.#####.####.#",
	"#.####.#####.##.#####.####.#",
	"#o..##................##..o#",
	"###.##.##.########.##.##.###",
	"###.##.##.########.##.##.###",
	"#......##....##....##......#",
	"#.##########.##.##########.#",
	"#.##########.##.##########.#",
	"#...........P..............#",
	"############################",
]

static func get_char(col: int, row: int) -> String:
	if row < 0 or row >= LAYOUT.size():
		return "#"
	var line: String = LAYOUT[row]
	if col < 0 or col >= line.length():
		return "#"
	return line[col]

static func is_wall(col: int, row: int) -> bool:
	# Tunnel row wraps around, so out-of-bounds on that row is NOT a wall,
	# it's handled separately by the tunnel warp logic.
	var c := get_char(col, row)
	return c == "#"

static func is_ghost_house(col: int, row: int) -> bool:
	return get_char(col, row) == "G"

static func is_ghost_door(col: int, row: int) -> bool:
	return get_char(col, row) == "-"

static func is_tunnel(col: int, row: int) -> bool:
	return get_char(col, row) == "T"

## Walkable = not a solid wall. Ghost house interior tiles ('G') are only
## walkable when allow_ghost_house is true (ghosts). The door ('-') is a
## ghost-only passage: it always blocks Pac-Man, but is always open to
## ghosts (entering as EATEN eyes or leaving on release), independent of
## allow_ghost_house, matching classic Pac-Man where players can never
## walk into the ghost house.
static func is_walkable(col: int, row: int, allow_ghost_house: bool = false) -> bool:
	var c := get_char(col, row)
	if c == "#":
		return false
	if c == "-":
		return allow_ghost_house
	if c == "G" and not allow_ghost_house:
		return false
	return true

static func find_all(target_char: String) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for row in range(LAYOUT.size()):
		var line: String = LAYOUT[row]
		for col in range(line.length()):
			if line[col] == target_char:
				results.append(Vector2i(col, row))
	return results

static func find_first(target_char: String) -> Vector2i:
	var all := find_all(target_char)
	if all.size() > 0:
		return all[0]
	return Vector2i(-1, -1)

static func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(col * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		row * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0)

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / Constants.TILE_SIZE), int(world_pos.y / Constants.TILE_SIZE))
