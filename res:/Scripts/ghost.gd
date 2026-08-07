extends CharacterBody2D

# Ghost types
enum GhostType { BLINKY, PINKY, INKY, CLYDE }

# Ghost states
enum State { SCATTER, CHASE, FRIGHTENED, EYES_RETURNING, SPAWNING }

# Movement speed (pixels per second)
@export var speed: float = 150.0

# Grid size (should match your tilemap cell size)
const GRID_SIZE: int = 16

# Ghost properties
@export var ghost_type: GhostType = GhostType.BLINKY
@export var scatter_target: Vector2 = Vector2.ZERO
@export var chase_target: NodePath = NodePath("")  # Will be set to player

# Internal state
var state: State = State.SCATTER
var direction: Vector2 = Vector2.ZERO
var target_position: Vector2
var frightened_timer: float = 0.0
var frightened_flash_timer: float = 0.0
var is_frightened: bool = false
var eyes_returning_home: bool = false

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var maze: Node2D = get_node("../Maze")  # Assuming ghost is child of game scene
@onready var player: CharacterBody2D

# Signals
signal eaten
signal returned_home

func _ready() -> void:
	# Get player reference (assuming player is in the game scene)
	var game_scene: Node = get_tree().get_current_scene()
	if game_scene:
		player = game_scene.get_node("Pacman")  # Adjust based on actual node name
	
	# Start at the center of the tile
	snap_to_grid()
	target_position = global_position
	
	# Set initial state based on ghost type
	_setup_initial_state()
	
	# Set initial animation
	_update_animation()

func _physics_process(delta: float) -> void:
	# Update timers
	if is_frightened:
		frightened_timer -= delta
		frightened_flash_timer -= delta
		
		# Flash when nearly out of frightened time
		if frightened_timer <= 3.0:  # Flash for last 3 seconds
			if frightened_flash_timer <= 0:
				frightened_flash_timer = 0.2  # Flash every 0.2 seconds
				animated_sprite.frame = (animated_sprite.frame + 1) % 2  # Toggle between 0 and 1
		
		# End frightened state
		if frightened_timer <= 0:
			_end_frightened()
	
	# Handle state-specific logic
	match state:
		State.SCATTER:
			_update_scatter()
		State.CHASE:
			_update_chase()
		State.FRIGHTENED:
			_update_frightened()
		State.EYES_RETURNING:
			_update_eyes_returning()
		State.SPAWNING:
			_update_spawning()
	
	# Move the ghost
	_move_and_collide()

func _setup_initial_state() -> void:
	# Set initial state based on ghost type
	match ghost_type:
		GhostType.BLINKY:  # Red - starts in chase immediately
			state = State.CHASE
		GhostType.PINKY:   # Pink - starts in scatter
			state = State.SCATTER
		GhostType.INKY:    # Blue - starts in scatter
			state = State.SCATTER
		GhostType.CLYDE:   # Orange - starts in scatter
			state = State.SCATTER
	
	# Set scatter target (corners of the maze)
	match ghost_type:
		GhostType.BLINKY:  # Top-right
			scatter_target = Vector2(30 * GRID_SIZE, 0 * GRID_SIZE)
		GhostType.PINKY:   # Top-left
			scatter_target = Vector2(0 * GRID_SIZE, 0 * GRID_SIZE)
		GhostType.INKY:    # Bottom-right
			scatter_target = Vector2(30 * GRID_SIZE, 30 * GRID_SIZE)
		GhostType.CLYDE:   # Bottom-left
			scatter_target = Vector2(0 * GRID_SIZE, 30 * GRID_SIZE)

func _update_scatter() -> void:
	_target = scatter_target

func _update_chase() -> void:
	if player:
		_target = player.global_position
		# Apply ghost-specific targeting logic
		match ghost_type:
			GhostType.BLINKY:  # Direct chase
				pass  # Already set to player position
			GhostType.PINKY:   # 4 tiles ahead of player
				var player_dir: Vector2 = player.direction
				if player_dir == Vector2.ZERO:
					player_dir = Vector2.LEFT  # Default if not moving
				_target = player.global_position + player_dir * 4 * GRID_SIZE
			GhostType.INKY:    # 2x vector from Blinky to 2 tiles ahead of player
				if player:
					var blinky: CharacterBody2D = get_node("../Blinky")  # Assuming we can get Blinky
					if blinky:
						var player_ahead: Vector2 = player.global_position + player.direction * 2 * GRID_SIZE
						var vector_to_blinky: Vector2 = blinky.global_position - player_ahead
						_target = player_ahead + vector_to_blinky * 2
					else:
						_target = player.global_position  # Fallback
				else:
					_target = Vector2.ZERO
			GhostType.CLYDE:   # Chase if far, scatter if close
				if player:
					var distance_to_player: float = global_position.distance_to(player.global_position)
					if distance_to_player > 8 * GRID_SIZE:  # More than 8 tiles away
						_target = player.global_position
					else:
						_target = scatter_target  # Go to scatter corner
				else:
					_target = scatter_target

func _update_frightened() -> void:
	# Move randomly when frightened
	var valid_directions: Array = [_get_valid_directions()]
	if valid_directions.size() > 0:
		direction = valid_directions.pick_random()
		velocity = direction * speed * 0.5  # Slow down when frightened

func _update_eyes_returning() -> void:
	# Return to ghost house center
	var ghost_house_center: Vector2 = Vector2(13.5 * GRID_SIZE, 14 * GRID_SIZE)  # Center of ghost house
	_target = ghost_house_center
	
	# Check if we've reached the ghost house
	if global_position.distance_to(ghost_house_center) < GRID_SIZE:
		# Reset to starting state
		_state = State.SCATTER
		eyes_returning_home = false
		is_frightened = false
		_update_animation()

func _update_spawning() -> void:
	# Similar to eyes returning but for initial spawn
	var ghost_house_center: Vector2 = Vector2(13.5 * GRID_SIZE, 14 * GRID_SIZE)
	_target = ghost_house_center
	
	if global_position.distance_to(ghost_house_center) < GRID_SIZE:
		_state = State.SCATTER  # Start in scatter state after spawning

func _get_valid_directions() -> Array:
	var valid: Array = []
	var directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for dir in directions:
		if can_move(dir):
			valid.append(dir)
	
	return valid

func can_move(dir: Vector2) -> bool:
	# Check if moving in the given direction would hit a wall
	var start_pos: Vector2 = global_position
	var end_pos: Vector2 = start_pos + dir * GRID_SIZE
	
	# Use a raycast to check for walls (assuming wall is on a specific layer)
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(
		PhysicsRayCast2D.create_ray_query(
			start_pos,
			end_pos,
			[1]  # Assuming walls are on layer 1 (adjust as needed)
		)
	)
	
	return result.empty()

func _move_and_collide() -> void:
	# If we have no direction, try to get one
	if direction == Vector2.ZERO:
		var valid_dirs: Array = _get_valid_directions()
		if valid_dirs.size() > 0:
			direction = valid_dirs.pick_random()
	
	# If we have a direction, try to move in that direction
	if direction != Vector2.ZERO:
		if can_move(direction):
			# Apply speed modifier for frightened state
			var move_speed: float = speed
			if is_frightened:
				move_speed *= 0.5  # Half speed when frightened
			
			velocity = direction * move_speed
			
			# Check if we've reached the target grid cell
			if is_close_to_target():
				snap_to_grid()
				# After snapping, choose new direction based on state
				_choose_new_direction()
		else:
			# Can't move in current direction, choose new direction
			_choose_new_direction()

func _choose_new_direction() -> void:
	var valid_dirs: Array = _get_valid_directions()
	if valid_dirs.size() > 0:
		# Remove the opposite direction to prevent 180-degree turns (except when only option)
		var opposite: Vector2 = -direction
		var filtered_dirs: Array = []
		for dir in valid_dirs:
			if dir != opposite or valid_dirs.size() == 1:
				filtered_dirs.append(dir)
		
		if filtered_dirs.size() > 0:
			direction = filtered_dirs.pick_random()
		else:
			direction = valid_dirs.pick_random()  # Fallback
	else:
		direction = Vector2.ZERO  # Stuck

func is_close_to_target() -> bool:
	return global_position.distance_to(target_position) < 5.0

func snap_to_grid() -> void:
	# Snap current position to the nearest grid cell
	var grid_x: int = round(global_position.x / GRID_SIZE) * GRID_SIZE
	var grid_y: int = round(global_position.y / GRID_SIZE) * GRID_SIZE
	global_position = Vector2(grid_x, grid_y)
	target_position = global_position

func _update_animation() -> void:
	if is_frightened:
		if frightened_flash_timer > 0:
			animated_sprite.animation = "frightened_flash"
		else:
			animated_sprite.animation = "frightened"
	elif eyes_returning_home:
		animated_sprite.animation = "eyes"
	else:
		# Normal animation based on direction
		if direction == Vector2.RIGHT:
			animated_sprite.animation = "right"
			animated_sprite.flip_h = false
		elif direction == Vector2.LEFT:
			animated_sprite.animation = "left"
			animated_sprite.flip_h = true
		elif direction == Vector2.UP:
			animated_sprite.animation = "up"
		elif direction == Vector2.DOWN:
			animated_sprite.animation = "down"
		else:
			# Idle - show first frame
			animated_sprite.stop()
			animated_sprite.frame = 0

func make_frightened(duration: float) -> void:
	is_frightened = true
	frightened_timer = duration
	frightened_flash_timer = 0.0
	_update_animation()

func _end_frightened() -> void:
	is_frightened = false
	frightened_timer = 0.0
	frightened_flash_timer = 0.0
	_update_animation()

func _on_body_entered(body: Node) -> void:
	# Check for collision with player
	if body.is_in_group("player"):
		if is_frightened:
			# Player eats ghost
			eaten.emit()
			# Return eyes to ghost house
			_return_eyes_home()
		elif not eyes_returning_home:
			# Ghost eats player (handled in game manager)
			pass

func _return_eyes_home() -> void:
	state = State.EYES_RETURNING
	eyes_returning_home = true
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_update_animation()