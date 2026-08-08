extends CharacterBody2D
class_name Ghost
## Shared ghost controller. Personality-specific TARGETING lives in
## ghost_ai.gd (attached as a child node) -- this script owns movement,
## the mode state machine, and visuals common to all 4 ghosts
## (section 3 of the spec).

enum Mode {
	IN_HOUSE,   # waiting inside the ghost house before release
	EXITING,    # walking from house interior through the door to the maze
	SCATTER,    # heads toward its home corner
	CHASE,      # actively targets Pac-Man (personality-driven)
	FRIGHTENED, # vulnerable, flees, can be eaten
	EATEN,      # eyes-only, returning to the ghost house to respawn
}

@export var ghost_color: Color = Color.RED
@export var release_delay: float = 0.0 # seconds after round start before leaving the house
@export var scatter_corner: Vector2i = Vector2i(1, 1)

var current_mode: Mode = Mode.IN_HOUSE
var grid_pos: Vector2i
var move_dir: Vector2i = Vector2i.UP
var speed: float = Constants.GHOST_SPEED * Constants.TILE_SIZE

@onready var body_sprite: Sprite2D = $BodySprite
@onready var eyes_sprite: Sprite2D = $EyesSprite
@onready var ai: GhostAI = $GhostAI

var _target_world_pos: Vector2
var _is_between_tiles: bool = false
var _house_start_pos: Vector2
var _released: bool = false
var _frightened_timer: float = 0.0
var _frightened_flash_state: bool = false

var _eyes_up: Texture2D = preload("res://assets/Ghost/Ghost_Eyes_Up.png")
var _eyes_down: Texture2D = preload("res://assets/Ghost/Ghost_Eyes_Down.png")
var _eyes_left: Texture2D = preload("res://assets/Ghost/Ghost_Eyes_Left.png")
var _eyes_right: Texture2D = preload("res://assets/Ghost/Ghost_Eyes_Right.png")
var _body_frames: Array[Texture2D] = [
	preload("res://assets/Ghost/Ghost_Body_01.png"),
	preload("res://assets/Ghost/Ghost_Body_02.png"),
]
var _vuln_blue_frames: Array[Texture2D] = [
	preload("res://assets/Ghost/Ghost_Vulnerable_Blue_01.png"),
	preload("res://assets/Ghost/Ghost_Vulnerable_Blue_02.png"),
]
var _vuln_white_frames: Array[Texture2D] = [
	preload("res://assets/Ghost/Ghost_Vulnerable_White_01.png"),
	preload("res://assets/Ghost/Ghost_Vulnerable_White_02.png"),
]
var _anim_time: float = 0.0

func _ready() -> void:
	var house_cells := MazeData.find_all("G")
	var spawn := house_cells[0] if house_cells.size() > 0 else Vector2i(13, 14)
	grid_pos = spawn
	position = MazeData.grid_to_world(spawn.x, spawn.y)
	_house_start_pos = position
	_target_world_pos = position
	body_sprite.modulate = ghost_color
	body_sprite.texture = _body_frames[0]
	eyes_sprite.texture = _eyes_down

	GameManager.state_changed.connect(_on_game_state_changed)

func reset_to_house() -> void:
	current_mode = Mode.IN_HOUSE
	_released = false
	position = _house_start_pos
	grid_pos = MazeData.world_to_grid(position)
	_target_world_pos = position
	_is_between_tiles = false
	move_dir = Vector2i.UP
	visible = true
	body_sprite.visible = true
	_update_visual_for_mode()

func release_from_house() -> void:
	_released = true
	current_mode = Mode.EXITING

func _physics_process(delta: float) -> void:
	if GameManager.current_state == GameManager.State.PAUSED:
		return
	if GameManager.current_state == GameManager.State.GAME_OVER or GameManager.current_state == GameManager.State.MENU:
		return

	_anim_time += delta

	match current_mode:
		Mode.IN_HOUSE:
			_bob_in_house(delta)
			return
		Mode.FRIGHTENED:
			_frightened_timer -= delta
			var warn_start: float = Constants.FRIGHTENED_WARNING_TIME
			if _frightened_timer <= warn_start:
				_frightened_flash_state = int(_anim_time * 6.0) % 2 == 0
			if _frightened_timer <= 0.0:
				_end_frightened()
		_:
			pass

	speed = _current_speed()
	_process_movement(delta)
	_update_visual_for_mode()

func _current_speed() -> float:
	var mult := GameManager.get_speed_multiplier()
	match current_mode:
		Mode.FRIGHTENED:
			return Constants.GHOST_FRIGHTENED_SPEED * Constants.TILE_SIZE
		Mode.EATEN:
			return Constants.GHOST_EATEN_SPEED * Constants.TILE_SIZE
		_:
			return Constants.GHOST_SPEED * Constants.TILE_SIZE * mult

func _process_movement(delta: float) -> void:
	if not _is_between_tiles:
		var allow_house := current_mode == Mode.EATEN or current_mode == Mode.IN_HOUSE or current_mode == Mode.EXITING
		var next_dir := ai.decide_direction(grid_pos, move_dir, current_mode, scatter_corner, allow_house)
		if next_dir == Vector2i.ZERO:
			return
		move_dir = next_dir
		var next_cell := _wrap(grid_pos + move_dir)
		_target_world_pos = MazeData.grid_to_world(next_cell.x, next_cell.y)
		_is_between_tiles = true

	var to_target := _target_world_pos - position
	var step := speed * delta
	if to_target.length() <= step:
		position = _target_world_pos
		grid_pos = _wrap(MazeData.world_to_grid(position))
		_is_between_tiles = false

		if current_mode == Mode.EATEN and grid_pos == MazeData.world_to_grid(_house_start_pos):
			_respawn_after_eaten()
		elif current_mode == Mode.EXITING and not MazeData.is_ghost_house(grid_pos.x, grid_pos.y) and not MazeData.is_ghost_door(grid_pos.x, grid_pos.y):
			# Cleared the door into the open maze -- switch to normal roaming.
			current_mode = Mode.SCATTER
	else:
		position += to_target.normalized() * step

func _wrap(cell: Vector2i) -> Vector2i:
	if cell.x < 0:
		return Vector2i(Constants.MAZE_COLS - 1, cell.y)
	if cell.x >= Constants.MAZE_COLS:
		return Vector2i(0, cell.y)
	return cell

func _bob_in_house(delta: float) -> void:
	position.y = _house_start_pos.y + sin(_anim_time * 4.0) * 3.0

func enter_frightened() -> void:
	if current_mode == Mode.EATEN or current_mode == Mode.IN_HOUSE:
		return
	current_mode = Mode.FRIGHTENED
	_frightened_timer = GameManager.get_frightened_duration()
	move_dir = -move_dir # classic Pac-Man: ghosts reverse when frightened begins
	_update_visual_for_mode()

func _end_frightened() -> void:
	if current_mode == Mode.FRIGHTENED:
		current_mode = Mode.CHASE
		_update_visual_for_mode()

func get_eaten() -> void:
	current_mode = Mode.EATEN
	_update_visual_for_mode()

func _respawn_after_eaten() -> void:
	current_mode = Mode.IN_HOUSE
	position = _house_start_pos
	_target_world_pos = position
	_is_between_tiles = false
	# Brief pause then release again.
	await get_tree().create_timer(1.5).timeout
	if current_mode == Mode.IN_HOUSE:
		release_from_house()

func _update_visual_for_mode() -> void:
	match current_mode:
		Mode.FRIGHTENED:
			var frames := _vuln_white_frames if _frightened_flash_state else _vuln_blue_frames
			var frame_idx := int(_anim_time * 4.0) % frames.size()
			body_sprite.texture = frames[frame_idx]
			body_sprite.modulate = Color.WHITE
			body_sprite.visible = true
			eyes_sprite.visible = false
		Mode.EATEN:
			body_sprite.visible = false
			eyes_sprite.visible = true
			_update_eyes_direction()
		_:
			var frame_idx := int(_anim_time * 6.0) % _body_frames.size()
			body_sprite.texture = _body_frames[frame_idx]
			body_sprite.modulate = ghost_color
			body_sprite.visible = true
			eyes_sprite.visible = true
			_update_eyes_direction()

func _update_eyes_direction() -> void:
	if move_dir == Vector2i(0, -1):
		eyes_sprite.texture = _eyes_up
	elif move_dir == Vector2i(0, 1):
		eyes_sprite.texture = _eyes_down
	elif move_dir == Vector2i(-1, 0):
		eyes_sprite.texture = _eyes_left
	elif move_dir == Vector2i(1, 0):
		eyes_sprite.texture = _eyes_right

func _on_game_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	if new_state == GameManager.State.POWER_MODE:
		enter_frightened()

func get_grid_position() -> Vector2i:
	return grid_pos

func get_house_cell() -> Vector2i:
	return MazeData.world_to_grid(_house_start_pos)

func is_vulnerable() -> bool:
	return current_mode == Mode.FRIGHTENED
