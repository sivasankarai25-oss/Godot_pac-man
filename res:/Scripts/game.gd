extends Node2D

# Game constants
const PELLET_SCORE: int = 10
const POWER_PELLET_SCORE: int = 50
const GHOST_EAT_SCORES: Array = [200, 400, 800, 1600]

# Game state
var score: int = 0
var lives: int = 3
var level: int = 1
var pellets_remaining: int = 0

# References
@onready var hud: HUD = $HUD
@onready var maze: Node2D = $Maze
@onready var pacman: CharacterBody2D = $Pacman
@onready var blinky: CharacterBody2D = $Blinky
@onready var pinky: CharacterBody2D = $Pinky
@onready var inky: CharacterBody2D = $Inky
@onready var clyde: CharacterBody2D = $Clyde

# Ghosts array for easy access
var ghosts: Array = [blinky, pinky, inky, clyde]

# Timers
var level_timer: Timer
var frightened_timer: Timer

# Game state enum
enum State { READY, PLAYING, PAUSED, LEVEL_COMPLETE, GAME_OVER, VICTORY }
var state: State = State.READY

func _ready() -> void:
	# Initialize the game
	_setup_maze()
	_spawn_pellets()
	_position_entities()
	
	# Connect signals
	pacman.pellet_collected.connect(_on_pacman_collected_pellet)
	pacman.power_pellet_collected.connect(_on_pacman_collected_power_pellet)
	
	for ghost in ghosts:
		ghost.eaten.connect(_on_ghost_eaten)
	
	# Start the game
	_start_ready_countdown()

func _setup_maze() -> void:
	# The maze is already set up in the Maze scene via its script
	pass

func _spawn_pellets() -> void:
	# We'll spawn pellets based on the maze data in the Maze script
	# For now, we'll assume the Maze script has a function to get pellet positions
	var maze_script: Maze = maze.get_script()
	if maze_script and maze_script.has_method("get_pellet_positions"):
		var pellet_positions: Array = maze_script.get_pellet_positions()
		var power_pellet_positions: Array = maze_script.get_power_pellet_positions()
		
		for pos in pellet_positions:
			var pellet_instance: Pellet = preload("res://Scenes/Pellet.tscn").instantiate()
			pellet_instance.global_position = pos
			add_child(pellet_instance)
			pellets_remaining += 1
		
		for pos in power_pellet_positions:
			var power_pellet_instance: PowerPellet = preload("res://Scenes/PowerPellet.tscn").instantiate()
			power_pellet_instance.global_position = pos
			add_child(power_pellet_instance)
			pellets_remaining += 1  # Count power pellets as pellets too for level completion
	
	# Update HUD
	hud.set_score(score)
	hud.set_lives(lives)
	hud.set_level(level)

func _position_entities() -> void:
	# Position Pac-Man and ghosts at their starting points
	# These positions should be defined in the maze or as constants
	var pacman_start: Vector2 = Vector2(13.5 * 16, 17 * 16)  # Example
	var ghost_house_center: Vector2 = Vector2(13.5 * 16, 11 * 16)
	
	pacman.global_position = pacman_start
	blinky.global_position = ghost_house_center
	pinky.global_position = ghost_house_center
	inky.global_position = ghost_house_center
	clyde.global_position = ghost_house_center
	
	# Reset ghost states
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.state = Ghost.State.SCATTER  # or whatever initial state
			ghost_script.direction = Vector2.ZERO
			ghost_script.velocity = Vector2.ZERO

func _start_ready_countdown() -> void:
	state = State.READY
	hud.show_ready()
	
	# Create a timer for the ready countdown
	var ready_timer: Timer = Timer.new()
	ready_timer.wait_time = 2.0  # 2 seconds
	ready_timer.one_shot = true
	ready_timer.timeout.connect(_on_ready_timer_timeout)
	add_child(ready_timer)
	ready_timer.start()

func _on_ready_timer_timeout() -> void:
	hud.hide_ready()
	state = State.PLAYING

func _on_pacman_collected_pellet() -> void:
	score += PELLET_SCORE
	pellets_remaining -= 1
	hud.set_score(score)
	_check_level_complete()

func _on_pacman_collected_power_pellet() -> void:
	score += POWER_PELLET_SCORE
	pellets_remaining -= 1
	hud.set_score(score)
	
	# Make ghosts frightened
	_for_each_ghost(func(ghost):
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.make_frightened(6.0)  # Base frightened time
	)
	
	_check_level_complete()

func _on_ghost_eaten(ghost: CharacterBody2D) -> void:
	# Determine which ghost was eaten for scoring
	var ghost_index: int = ghosts.find(ghost)
	if ghost_index >= 0:
		var score_to_add: int = GHOST_EAT_SCORES[ghost_index]
		score += score_to_add
		hud.set_score(score)
	
	# The ghost will handle returning home via its own state machine

func _check_level_complete() -> void:
	if pellets_remaining <= 0:
		_state = State.LEVEL_COMPLETE
		_level_complete()

func _level_complete() -> void:
	# Stop gameplay
	state = State.LEVEL_COMPLETE
	
	# Show victory label for a moment, then go to next level
	hud.show_victory()
	
	var level_complete_timer: Timer = Timer.new()
	level_complete_timer.wait_time = 2.0
	level_complete_timer.one_shot = true
	level_complete_timer.timeout.connect(_on_level_complete_timeout)
	add_child(level_complete_timer)
	level_complete_timer.start()

func _on_level_complete_timeout() -> void:
	hud.hide_victory()
	level += 1
	_reset_level()

func _reset_level() -> void:
	# Clear all pellets and power pellets
	var children: Array = get_children()
	for child in children:
		if child is Pellet or child is PowerPellet:
			child.queue_free()
	
	# Reset pellets remaining count (will be recalculated in _spawn_pellets)
	pellets_remaining = 0
	
	# Respawn pellets
	_spawn_pellets()
	
	# Reset entities
	_position_entities()
	
	# Increase ghost speed for next level (example)
	var speed_increase: float = 0.1 * (level - 1)  # 10% faster each level
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.speed += speed_increase
	
	# Reset state
	state = State.READY
	_start_ready_countdown()

func _on_pacman_death() -> void:
	# This would be called from the player script when Pac-Man collides with a ghost (non-frightened)
	lives -= 1
	hud.set_lives(lives)
	
	if lives <= 0:
		_game_over()
	else:
		# Reset positions and continue
		_reset_round()

func _reset_round() -> void:
	# Reset positions of Pac-Man and ghosts
	_position_entities()
	
	# Reset ghost states (to scatter/chase as appropriate)
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.state = Ghost.State.SCATTER  # or based on game state
			ghost_script.direction = Vector2.ZERO
			ghost_script.velocity = Vector2.ZERO
	
	# Reset Pac-Man
	pacman.direction = Vector2.ZERO
	pacman.velocity = Vector2.ZERO
	
	# Ready countdown
	state = State.READY
	hud.show_ready()
	var ready_timer: Timer = Timer.new()
	ready_timer.wait_time = 2.0
	ready_timer.one_shot = true
	ready_timer.timeout.connect(_on_ready_timer_timeout)
	add_child(ready_timer)
	ready_timer.start()

func _game_over() -> void:
	state = State.GAME_OVER
	hud.show_game_over()
	
	# Optionally, show game over screen after a delay
	var game_over_timer: Timer = Timer.new()
	game_over_timer.wait_time = 3.0
	game_over_timer.one_shot = true
	game_over_timer.timeout.connect(_show_game_over_scene)
	add_child(game_over_timer)
	game_over_timer.start()

func _show_game_over_scene() -> void:
	# Change to game over scene (we'll handle this in the main game manager)
	# For now, we'll just tell the game manager to change state
	get_tree().call_group("game_manager", "change_state", GameManager.State.GAME_OVER)

func _for_each_ghost(func) -> void:
	for ghost in ghosts:
		if ghost:
			func(ghost)

# Game constants
const PELLET_SCORE: int = 10
const POWER_PELLET_SCORE: int = 50
const GHOST_EAT_SCORES: Array = [200, 400, 800, 1600]

# Game state
var score: int = 0
var lives: int = 3
var level: int = 1
var pellets_remaining: int = 0

# References
@onready var hud: HUD = $HUD
@onready var maze: Node2D = $Maze
@onready var pacman: CharacterBody2D = $Pacman
@onready var blinky: CharacterBody2D = $Blinky
@onready var pinky: CharacterBody2D = $Pinky
@onready var inky: CharacterBody2D = $Inky
@onready var clyde: CharacterBody2D = $Clyde

# Ghosts array for easy access
var ghosts: Array = [blinky, pinky, inky, clyde]

# Timers
var level_timer: Timer
var frightened_timer: Timer

# Game state enum
enum State { READY, PLAYING, PAUSED, LEVEL_COMPLETE, GAME_OVER, VICTORY }
var state: State = State.READY

func _ready() -> void:
	# Initialize the game
	_setup_maze()
	_spawn_pellets()
	_position_entities()
	
	# Connect signals
	pacman.pellet_collected.connect(_on_pacman_collected_pellet)
	pacman.power_pellet_collected.connect(_on_pacman_collected_power_pellet)
	
	for ghost in ghosts:
		ghost.eaten.connect(_on_ghost_eaten)
	
	# Start the game
	_start_ready_countdown()

func _setup_maze() -> void:
	# The maze is already set up in the Maze scene via its script
	pass

func _spawn_pellets() -> void:
	# We'll spawn pellets based on the maze data in the Maze script
	# For now, we'll assume the Maze script has a function to get pellet positions
	var maze_script: Maze = maze.get_script()
	if maze_script and maze_script.has_method("get_pellet_positions"):
		var pellet_positions: Array = maze_script.get_pellet_positions()
		var power_pellet_positions: Array = maze_script.get_power_pellet_positions()
		
		for pos in pellet_positions:
			var pellet_instance: Pellet = preload("res://Scenes/Pellet.tscn").instantiate()
			pellet_instance.global_position = pos
			add_child(pellet_instance)
			pellets_remaining += 1
		
		for pos in power_pellet_positions:
			var power_pellet_instance: PowerPellet = preload("res://Scenes/PowerPellet.tscn").instantiate()
			power_pellet_instance.global_position = pos
			add_child(power_pellet_instance)
			pellets_remaining += 1  # Count power pellets as pellets too for level completion
	
	# Update HUD
	hud.set_score(score)
	hud.set_lives(lives)
	hud.set_level(level)

func _position_entities() -> void:
	# Position Pac-Man and ghosts at their starting points
	# These positions should be defined in the maze or as constants
	var pacman_start: Vector2 = Vector2(13.5 * 16, 17 * 16)  # Example
	var ghost_house_center: Vector2 = Vector2(13.5 * 16, 11 * 16)
	
	pacman.global_position = pacman_start
	blinky.global_position = ghost_house_center
	pinky.global_position = ghost_house_center
	inky.global_position = ghost_house_center
	clyde.global_position = ghost_house_center
	
	# Reset ghost states
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.state = Ghost.State.SCATTER  # or whatever initial state
			ghost_script.direction = Vector2.ZERO
			ghost_script.velocity = Vector2.ZERO

func _start_ready_countdown() -> void:
	state = State.READY
	hud.show_ready()
	
	# Create a timer for the ready countdown
	var ready_timer: Timer = Timer.new()
	ready_timer.wait_time = 2.0  # 2 seconds
	ready_timer.one_shot = true
	ready_timer.timeout.connect(_on_ready_timer_timeout)
	add_child(ready_timer)
	ready_timer.start()

func _on_ready_timer_timeout() -> void:
	hud.hide_ready()
	state = State.PLAYING

func _on_pacman_collected_pellet() -> void:
	score += PELLET_SCORE
	pellets_remaining -= 1
	hud.set_score(score)
	_check_level_complete()

func _on_pacman_collected_power_pellet() -> void:
	score += POWER_PELLET_SCORE
	pellets_remaining -= 1
	hud.set_score(score)
	
	# Make ghosts frightened
	_for_each_ghost(func(ghost):
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.make_frightened(6.0)  # Base frightened time
	)
	
	_check_level_complete()

func _on_ghost_eaten(ghost: CharacterBody2D) -> void:
	# Determine which ghost was eaten for scoring
	var ghost_index: int = ghosts.find(ghost)
	if ghost_index >= 0:
		var score_to_add: int = GHOST_EAT_SCORES[ghost_index]
		score += score_to_add
		hud.set_score(score)
	
	# The ghost will handle returning home via its own state machine

func _check_level_complete() -> void:
	if pellets_remaining <= 0:
		_state = State.LEVEL_COMPLETE
		_level_complete()

func _level_complete() -> void:
	# Stop gameplay
	state = State.LEVEL_COMPLETE
	
	# Show victory label for a moment, then go to next level
	hud.show_victory()
	
	var level_complete_timer: Timer = Timer.new()
	level_complete_timer.wait_time = 2.0
	level_complete_timer.one_shot = true
	level_complete_timer.timeout.connect(_on_level_complete_timeout)
	add_child(level_complete_timer)
	level_complete_timer.start()

func _on_level_complete_timeout() -> void:
	hud.hide_victory()
	level += 1
	_reset_level()

func _reset_level() -> void:
	# Clear all pellets and power pellets
	var children: Array = get_children()
	for child in children:
		if child is Pellet or child is PowerPellet:
			child.queue_free()
	
	# Reset pellets remaining count (will be recalculated in _spawn_pellets)
	pellets_remaining = 0
	
	# Respawn pellets
	_spawn_pellets()
	
	# Reset entities
	_position_entities()
	
	# Increase ghost speed for next level (example)
	var speed_increase: float = 0.1 * (level - 1)  # 10% faster each level
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.speed += speed_increase
	
	# Reset state
	state = State.READY
	_start_ready_countdown()

func _on_pacman_death() -> void:
	# This would be called from the player script when Pac-Man collides with a ghost (non-frightened)
	lives -= 1
	hud.set_lives(lives)
	
	if lives <= 0:
		_game_over()
	else:
		# Reset positions and continue
		_reset_round()

func _reset_round() -> void:
	# Reset positions of Pac-Man and ghosts
	_position_entities()
	
	# Reset ghost states (to scatter/chase as appropriate)
	for ghost in ghosts:
		var ghost_script: Ghost = ghost.get_script()
		if ghost_script:
			ghost_script.state = Ghost.State.SCATTER  # or based on game state
			ghost_script.direction = Vector2.ZERO
			ghost_script.velocity = Vector2.ZERO
	
	# Reset Pac-Man
	pacman.direction = Vector2.ZERO
	pacman.velocity = Vector2.ZERO
	
	# Ready countdown
	state = State.READY
	hud.show_ready()
	var ready_timer: Timer = Timer.new()
	ready_timer.wait_time = 2.0
	ready_timer.one_shot = true
	ready_timer.timeout.connect(_on_ready_timer_timeout)
	add_child(ready_timer)
	ready_timer.start()

func _game_over() -> void:
	state = State.GAME_OVER
	hud.show_game_over()
	
	# Optionally, show game over screen after a delay
	var game_over_timer: Timer = Timer.new()
	game_over_timer.wait_time = 3.0
	game_over_timer.one_shot = true
	game_over_timer.timeout.connect(_show_game_over_scene)
	add_child(game_over_timer)
	game_over_timer.start()

func _show_game_over_scene() -> void:
	# Change to game over scene (we'll handle this in the main game manager)
	# For now, we'll just tell the game manager to change state
	get_tree().call_group("game_manager", "change_state", GameManager.State.GAME_OVER)

func _for_each_ghost(func) -> void:
	for ghost in ghosts:
		if ghost:
			func(ghost)