extends Node2D
class_name GameController
## Root script for Game.tscn. Wires together Pacman, the 4 Ghosts, the
## MazeManager, and the Cherry, and owns collision resolution + the
## power-mode countdown. This is the "glue" layer described in spec
## section 15 (game_manager.gd handles pure state; this handles the scene).

@onready var maze_manager: MazeManager = $MazeManager
@onready var pacman: Pacman = $Pacman
@onready var ghosts_node: Node2D = $Ghosts
@onready var cherry: Cherry = $Cherry
@onready var ui: UIManager = $UIManager

var _ghosts: Array = []
var _power_mode_time_left: float = 0.0
var _power_mode_duration: float = 0.0
var _ghost_release_timer: float = 0.0
var _next_ghost_to_release: int = 0

func _ready() -> void:
	_ghosts = ghosts_node.get_children()

	maze_manager.all_pellets_collected.connect(_on_all_pellets_collected)
	maze_manager.pellet_collected.connect(_on_pellet_collected)
	maze_manager.power_pellet_collected.connect(_on_power_pellet_collected)
	pacman.died.connect(_on_pacman_died)
	GameManager.state_changed.connect(_on_state_changed)

	pacman.set_ai_controlled(GameManager.pending_ai_mode)

	GameManager.start_new_game()
	_setup_round()

func _setup_round() -> void:
	pacman.reset_to_start()
	for g in _ghosts:
		g.reset_to_house()
	cherry.reset()
	_ghost_release_timer = 0.0
	_next_ghost_to_release = 0
	maze_manager.rebuild_pellets()
	await get_tree().create_timer(1.0).timeout
	GameManager.begin_playing()

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.State.POWER_MODE:
		_power_mode_time_left -= delta
		GameManager.power_mode_timer_updated.emit(max(_power_mode_time_left, 0.0), _power_mode_duration)
		if _power_mode_time_left <= 0.0:
			GameManager.exit_power_mode()

	if GameManager.current_state == GameManager.State.PLAYING:
		_update_ghost_release(delta)
		_check_ghost_collisions()
	elif GameManager.current_state == GameManager.State.POWER_MODE:
		_check_ghost_collisions()

func _update_ghost_release(delta: float) -> void:
	if _next_ghost_to_release >= _ghosts.size():
		return
	_ghost_release_timer += delta
	if _ghost_release_timer >= Constants.GHOST_RELEASE_INTERVAL * _next_ghost_to_release:
		var g = _ghosts[_next_ghost_to_release]
		if g.current_mode == Ghost.Mode.IN_HOUSE:
			g.release_from_house()
		_next_ghost_to_release += 1

func _check_ghost_collisions() -> void:
	for g in _ghosts:
		if not is_instance_valid(g):
			continue
		if g.current_mode == Ghost.Mode.IN_HOUSE or g.current_mode == Ghost.Mode.EATEN:
			continue
		if g.get_grid_position() == pacman.get_grid_position():
			if g.is_vulnerable():
				_eat_ghost(g)
			else:
				_pacman_hit_by_ghost()
			return # one resolution per frame is enough; avoids double-triggers

func _eat_ghost(g) -> void:
	var points := GameManager.score_ghost_eaten()
	AudioManager.play("eat_ghost")
	g.get_eaten()
	_show_floating_score(g.position, points)

func _pacman_hit_by_ghost() -> void:
	if pacman.is_dying:
		return
	await pacman.play_death_animation()

func _on_pacman_died() -> void:
	GameManager.lose_life()

func _on_pellet_collected(points: int) -> void:
	GameManager.score_pellet() if points == Constants.SCORE_PELLET else GameManager.score_power_pellet()

func _on_power_pellet_collected() -> void:
	AudioManager.play("power_pellet")
	GameManager.enter_power_mode()

func _on_all_pellets_collected() -> void:
	GameManager.complete_level()

func _on_state_changed(new_state: GameManager.State, old_state: GameManager.State) -> void:
	if new_state == GameManager.State.POWER_MODE:
		_power_mode_duration = GameManager.get_frightened_duration()
		_power_mode_time_left = _power_mode_duration
	elif new_state == GameManager.State.READY and old_state != GameManager.State.MENU:
		_setup_round()
	elif new_state == GameManager.State.LEVEL_COMPLETE:
		await get_tree().create_timer(2.0).timeout
		GameManager.advance_to_next_level()

func _show_floating_score(world_pos: Vector2, points: int) -> void:
	var label := Label.new()
	label.text = "+%d" % points
	label.position = world_pos
	label.z_index = 100
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", world_pos.y - 24, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

func restart_game() -> void:
	GameManager.start_new_game()
	_setup_round()
