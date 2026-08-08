extends CharacterBody2D
class_name Pacman
## Pac-Man controller. Moves on a grid-aligned basis (classic Pac-Man feel):
## continuous smooth movement between tile centers, direction changes only
## commit when the requested direction is actually open. Can be driven by
## player input or by PacmanAI (section 2 and 6 of the spec).

signal died
signal direction_changed(new_dir: Vector2i)

@export var ai_controlled: bool = false

var grid_pos: Vector2i
var move_dir: Vector2i = Vector2i.ZERO
var requested_dir: Vector2i = Vector2i.ZERO
var speed: float = Constants.PACMAN_SPEED * Constants.TILE_SIZE
var is_dying: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var maze_manager: MazeManager = get_tree().current_scene.get_node("MazeManager")
@onready var ai: PacmanAI = $PacmanAI if has_node("PacmanAI") else null

var _target_world_pos: Vector2
var _is_between_tiles: bool = false

func _ready() -> void:
	var start := MazeData.find_first("P")
	grid_pos = start
	position = MazeData.grid_to_world(start.x, start.y)
	_target_world_pos = position
	if ai:
		ai.set_active(ai_controlled)

func reset_to_start() -> void:
	is_dying = false
	visible = true
	var start := MazeData.find_first("P")
	grid_pos = start
	position = MazeData.grid_to_world(start.x, start.y)
	_target_world_pos = position
	move_dir = Vector2i.ZERO
	requested_dir = Vector2i.ZERO
	_is_between_tiles = false
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func set_ai_controlled(value: bool) -> void:
	ai_controlled = value
	if ai:
		ai.set_active(value)

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	if GameManager.current_state != GameManager.State.PLAYING and GameManager.current_state != GameManager.State.POWER_MODE:
		return

	speed = Constants.PACMAN_SPEED * Constants.TILE_SIZE * GameManager.get_speed_multiplier()

	if ai_controlled and ai:
		requested_dir = ai.get_desired_direction(grid_pos, move_dir)
	else:
		requested_dir = _read_input_direction()

	_process_movement(delta)
	_update_animation()

func _read_input_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	if Input.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	if Input.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	# Touch swipe input is written into TouchInputState by InputManager.
	if InputManager and InputManager.has_pending_swipe():
		return InputManager.consume_swipe_direction()
	return move_dir

func _process_movement(delta: float) -> void:
	if not _is_between_tiles:
		# At a tile center: decide direction.
		if requested_dir != Vector2i.ZERO and _can_move(grid_pos, requested_dir):
			move_dir = requested_dir
		if move_dir == Vector2i.ZERO or not _can_move(grid_pos, move_dir):
			move_dir = Vector2i.ZERO
			return
		var next_cell := _wrap(grid_pos + move_dir)
		_target_world_pos = MazeData.grid_to_world(next_cell.x, next_cell.y)
		_is_between_tiles = true
		if move_dir != Vector2i.ZERO:
			direction_changed.emit(move_dir)

	var to_target := _target_world_pos - position
	var step := speed * delta
	if to_target.length() <= step:
		position = _target_world_pos
		grid_pos = _wrap(MazeData.world_to_grid(position))
		_is_between_tiles = false
		if maze_manager.try_collect_pellet_at(grid_pos.x, grid_pos.y):
			AudioManager.play("chomp")
	else:
		position += to_target.normalized() * step

func _can_move(from: Vector2i, dir: Vector2i) -> bool:
	var next := _wrap(from + dir)
	return MazeData.is_walkable(next.x, next.y, false)

func _wrap(cell: Vector2i) -> Vector2i:
	if cell.x < 0:
		return Vector2i(Constants.MAZE_COLS - 1, cell.y)
	if cell.x >= Constants.MAZE_COLS:
		return Vector2i(0, cell.y)
	return cell

func _update_animation() -> void:
	if move_dir == Vector2i.ZERO:
		if anim_player.has_animation("idle"):
			anim_player.play("idle")
		return
	if anim_player.has_animation("chomp"):
		if anim_player.current_animation != "chomp":
			anim_player.play("chomp")
	var angle := 0.0
	if move_dir == Vector2i(1, 0):
		angle = 0.0
	elif move_dir == Vector2i(-1, 0):
		angle = PI
	elif move_dir == Vector2i(0, -1):
		angle = -PI / 2
	elif move_dir == Vector2i(0, 1):
		angle = PI / 2
	sprite.rotation = angle

func play_death_animation() -> void:
	is_dying = true
	move_dir = Vector2i.ZERO
	AudioManager.play("death")
	if anim_player.has_animation("death"):
		anim_player.play("death")
		await anim_player.animation_finished
	died.emit()

func get_grid_position() -> Vector2i:
	return grid_pos
