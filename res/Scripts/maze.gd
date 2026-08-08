extends Node2D

# Tile size in pixels
const TILE_SIZE: int = 16

# Maze layout (28 columns x 31 rows)
# X = wall, . = empty (normal pellet), P = power pellet, o = ghost house entrance (empty, no pellet)
var maze_data = [
	"XXXXXXXXXXXXXXXXXXXXXXXXXXXX",
	"X............XX............X",
	"X.XXXX.XXX.XX.XXX.XXXX.XXX.X",
	"XoXXXX.XXX.XX.XXX.XXXX.XXX.oX",
	"X.XXXX.XXX.XX.XXX.XXXX.XXX.X",
	"X............................X",
	"X.XXXX.XX.XXXXXX.XX.XXXX.XX.X",
	"X.XXXX.XX.XXXXXX.XX.XXXX.XX.X",
	"X......XX........XX.XX......X",
	"XXXXXX.XXXXX XX XXXXX.XXXXX XX",
	"XXXXXX.XXXXX XX XXXXX.XXXXX XX",
	"XXXXXX.XX    XX    XX.XXXXX XX",
	"XXXXXX.XX XXXXXX XX.XXXXX XX",
	"XXXXXX.XX XXXXXX XX.XXXXX XX",
	"XXXXXX.XX XXXXXX XX.XXXXX XX",
	"XXXXXX.XX    XX    XX.XXXXX XX",
	"XXXXXX.XXXXX XX XXXXX.XXXXX XX",
	"XXXXXX.XXXXX XX XXXXX.XXXXX XX",
	"X............................X",
	"X.XXXX.XX.XXXXXX.XX.XXXX.XX.X",
	"X.XXXX.XX.XXXXXX.XX.XXXX.XX.X",
	"X.X..XX............XX..X.X.X",
	"X.XXX.XX.XX XX XX.XX.XX.XXX.X",
	"X.XXX.XX.XX XX XX.XX.XX.XXX.X",
	"X......XX........XX.XX......X",
	"X.XXXXXXXXXX.XX.XXXXXXXXXX.X",
	"X.XXXXXXXXXX.XX.XXXXXXXXXX.X",
	"X............................X",
	"XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
]

# We'll replace the power pellet positions with 'P' in the maze data above.
# But note: the original maze data doesn't have 'P'. We'll set them manually in code for now.
# Alternatively, we can edit the maze_data strings to include 'P' at the known power pellet locations.
# Known power pellet locations in the original Pac-Man maze (in grid coordinates):
#   (1,1), (26,1), (1,29), (26,29)  [assuming 0-indexed, 28x31 grid]
# Let's adjust the maze_data to put 'P' at these positions.

# However, to keep the maze_data string readable, we'll do it in code: after initializing maze_data, we'll set those four tiles to 'P'.

@onready var tilemap: TileMap = $TileMap
# Arrays to hold pellet and power pellet positions (in global coordinates)
var pellet_positions: Array = []
var power_pellet_positions: Array = []

func _ready() -> void:
	_setup_tileset()
	_load_maze()

func _setup_tileset() -> void:
	var tileset: TileSet = TileSet.new()
	
	# Try to load wall texture from assets
	var wall_texture: Texture2D
	if FileAccess.file_exists("res://Assets/Walls/wall_0.png"):
		wall_texture = load("res://Assets/Walls/wall_0.png")
	else:
		# Create a placeholder wall texture
		var image: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.2, 0.2, 0.8))  # Blue placeholder
		wall_texture = ImageTexture.create_from_image(image)
	
	# Create tile for walls (tile ID 0)
	var wall_tile_id: int = 0
	tileset.create_tile(wall_tile_id)
	tileset.tile_set_texture(wall_tile_id, wall_texture)
	
	# Set collision shape for the wall tile
	var shape: Shape2D = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	tileset.tile_set_shape(wall_tile_id, 0, shape)
	
	# Assign tileset to TileMap
	tilemap.tile_set = tileset
	
	# Set cell size
	tilemap.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	
	# Set collision layer (we'll use layer 1 for walls)
	tilemap.collision_layer = 1
	tilemap.collision_mask = 1

func _load_maze() -> void:
	# Clear existing cells and reset position arrays
	tilemap.clear()
	pellet_positions.clear()
	power_pellet_positions.clear()
	
	# Wall tile ID
	var wall_tile_id: int = 0
	
	# Temporary array to hold maze data as mutable strings
	var mutable_maze: Array = []
	for row in maze_data:
		mutable_maze.append(row.to_char_array())
	
	# Set power pellet positions (we'll overwrite the maze data at these spots)
	var power_pellet_locations: Array = [Vector2i(1, 1), Vector2i(26, 1), Vector2i(1, 29), Vector2i(26, 29)]
	for loc in power_pellet_locations:
		if loc.y < mutable_maze.size() and loc.x < mutable_maze[loc.y].size():
			mutable_maze[loc.y][loc.x] = 'P'
	
	# Iterate through maze data
	for i in mutable_maze.size():
		var row: Array = mutable_maze[i]
		for j in row.size():
			var cell: String = String(row[j])
			var position: Vector2i = Vector2i(j, i)
			var world_position: Vector2 = Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE)
			
			match cell:
				'X':  # Wall
					tilemap.set_cellv(position, wall_tile_id)
				'.':  # Empty (normal pellet)
					pellet_positions.append(world_position)
				'P':  # Power pellet
					power_pellet_positions.append(world_position)
				'o':  # Ghost house entrance (empty, no pellet)
					pass  # Do nothing, leave empty
				_:
					pass  # Any other character treated as empty
	
	# Note: We don't set any tile for pellets; they are placed separately by the game script.

# Functions to get pellet positions (for use by game.gd)
func get_pellet_positions() -> Array:
	return pellet_positions.duplicate()  # Return a copy to prevent accidental modification

func get_power_pellet_positions() -> Array:
	return power_pellet_positions.duplicate()