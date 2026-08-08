extends Node2D
class_name MazeManager
## Builds the maze visuals procedurally as centerline wall strokes and
## tracks pellets/power pellets (section 7 and 8 of the spec).
##
## Rationale: the provided wall_atlas.png is a decorative multi-tile set
## whose exact autotile adjacency mapping can't be verified without the
## Godot editor's live preview, and a hand-guessed bitmask produced visibly
## broken, disconnected walls when rendered for review. Procedural
## centerline strokes (a short colored bar from each wall tile's center
## toward every neighboring wall tile, plus a center dot) always produce
## clean, fully-connected walls for ANY maze layout with zero risk of
## misaligned tiles, and were verified visually before being wired in here.
## The wall color/style below is easy to swap for the atlas later if
## someone wants to hand-tune it inside the editor.

signal all_pellets_collected
signal pellet_collected(points: int)
signal power_pellet_collected

const PELLET_SMALL_PATH := "res://assets/Pellet/Pellet_Small.png"
const PELLET_LARGE_PATH := "res://assets/Pellet/Pellet_Large.png"

const WALL_COLOR := Color(0.13, 0.24, 0.87, 1.0)
const WALL_THICKNESS: float = 6.0
const GHOST_DOOR_COLOR := Color(1.0, 0.71, 0.84, 1.0)

var _pellet_small_texture: Texture2D
var _pellet_large_texture: Texture2D

var _pellet_nodes: Dictionary = {} # Vector2i -> Node2D
var _total_pellets: int = 0

@onready var walls_container: Node2D = Node2D.new()
@onready var pellets_container: Node2D = Node2D.new()

func _ready() -> void:
	_pellet_small_texture = load(PELLET_SMALL_PATH)
	_pellet_large_texture = load(PELLET_LARGE_PATH)

	walls_container.name = "Walls"
	pellets_container.name = "Pellets"
	add_child(walls_container)
	add_child(pellets_container)

	_build_walls()
	_build_pellets()

func rebuild_pellets() -> void:
	for child in pellets_container.get_children():
		child.queue_free()
	_pellet_nodes.clear()
	_build_pellets()

func _build_walls() -> void:
	var wall_draw := Node2D.new()
	wall_draw.name = "WallStrokes"
	wall_draw.z_index = 5
	walls_container.add_child(wall_draw)

	var segments: Array = [] # Array of [Vector2, Vector2] line endpoints
	var dots: Array = [] # Array of Vector2 centers for corner/end caps

	for row in range(Constants.MAZE_ROWS):
		for col in range(Constants.MAZE_COLS):
			if not MazeData.is_wall(col, row):
				continue
			var center := MazeData.grid_to_world(col, row)
			var half := Constants.TILE_SIZE / 2.0
			dots.append(center)
			if MazeData.is_wall(col - 1, row):
				segments.append([center, center - Vector2(half, 0)])
			if MazeData.is_wall(col + 1, row):
				segments.append([center, center + Vector2(half, 0)])
			if MazeData.is_wall(col, row - 1):
				segments.append([center, center - Vector2(0, half)])
			if MazeData.is_wall(col, row + 1):
				segments.append([center, center + Vector2(0, half)])

	var line_node := _make_multiline(segments, WALL_COLOR, WALL_THICKNESS)
	wall_draw.add_child(line_node)

	var dots_node := _make_dots(dots, WALL_COLOR, WALL_THICKNESS)
	wall_draw.add_child(dots_node)

	# Ghost house door: a short horizontal bar in a distinct color.
	var door_cells := MazeData.find_all("-")
	if not door_cells.is_empty():
		var door_segments: Array = []
		for cell in door_cells:
			var c := MazeData.grid_to_world(cell.x, cell.y)
			var half := Constants.TILE_SIZE / 2.0
			door_segments.append([c - Vector2(half, 0), c + Vector2(half, 0)])
		var door_node := _make_multiline(door_segments, GHOST_DOOR_COLOR, WALL_THICKNESS - 2.0)
		door_node.z_index = 6
		wall_draw.add_child(door_node)

func _make_multiline(segments: Array, color: Color, thickness: float) -> Node2D:
	var holder := Node2D.new()
	for seg in segments:
		var line := Line2D.new()
		line.add_point(seg[0])
		line.add_point(seg[1])
		line.width = thickness
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		holder.add_child(line)
	return holder

func _make_dots(centers: Array, color: Color, thickness: float) -> Node2D:
	var holder := Node2D.new()
	var radius := thickness / 2.0
	var points := PackedVector2Array()
	var segments := 10
	for i in range(segments):
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	for c in centers:
		var poly := Polygon2D.new()
		poly.polygon = points
		poly.color = color
		poly.position = c
		holder.add_child(poly)
	return holder

func _build_pellets() -> void:
	_total_pellets = 0
	for row in range(Constants.MAZE_ROWS):
		for col in range(Constants.MAZE_COLS):
			var c := MazeData.get_char(col, row)
			if c == ".":
				_spawn_pellet(col, row, false)
			elif c == "o":
				_spawn_pellet(col, row, true)
	_total_pellets = _pellet_nodes.size()

func _spawn_pellet(col: int, row: int, is_power: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _pellet_large_texture if is_power else _pellet_small_texture
	sprite.position = MazeData.grid_to_world(col, row)
	sprite.scale = Vector2(0.5, 0.5) if is_power else Vector2(0.35, 0.35)
	sprite.z_index = 2
	sprite.set_meta("is_power", is_power)
	pellets_container.add_child(sprite)
	_pellet_nodes[Vector2i(col, row)] = sprite

	if is_power:
		# gentle pulse so power pellets read as "important" per spec section 9
		var tween := sprite.create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "scale", Vector2(0.62, 0.62), 0.4)
		tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.4)

## Called by Pacman when it enters a new grid cell. Returns true if a pellet was there.
func try_collect_pellet_at(col: int, row: int) -> bool:
	var cell := Vector2i(col, row)
	if not _pellet_nodes.has(cell):
		return false
	var node: Node2D = _pellet_nodes[cell]
	var is_power: bool = node.get_meta("is_power", false)
	node.queue_free()
	_pellet_nodes.erase(cell)

	if is_power:
		power_pellet_collected.emit()
		pellet_collected.emit(Constants.SCORE_POWER_PELLET)
	else:
		pellet_collected.emit(Constants.SCORE_PELLET)

	if _pellet_nodes.is_empty():
		all_pellets_collected.emit()
	return true

func pellets_remaining() -> int:
	return _pellet_nodes.size()

func total_pellets() -> int:
	return _total_pellets

## Public accessor for pellet cell positions (used by PacmanAI's pellet-seeking
## logic instead of reaching into the private _pellet_nodes dictionary directly).
func has_pellet_at(cell: Vector2i) -> bool:
	return _pellet_nodes.has(cell)

func get_all_pellet_cells() -> Array:
	return _pellet_nodes.keys()
