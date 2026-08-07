extends CharacterBody2D

# Movement speed (pixels per second)
@export var speed: float = 200.0

# Grid size (should match your tilemap cell size)
const GRID_SIZE: int = 16

# Input buffer
var buffered_input: Vector2 = Vector2.ZERO

# Current direction of movement
var direction: Vector2 = Vector2.ZERO

# Target position (the grid cell we are moving towards)
var target_position: Vector2

# Reference to the AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Start at the center of the tile
	snap_to_grid()
	target_position = global_position
	
	# Set initial animation
	animated_sprite.play("right")

func _physics_process(delta: float) -> void:
	handle_input()
	move_and_collide()
	update_animation()

func handle_input() -> void:
	# Buffer input
	var input_vector: Vector2 = Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("dright"):
		input_vector = Vector2.RIGHT
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("dleft"):
		input_vector = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("dup"):
		input_vector = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ddown"):
		input_vector = Vector2.DOWN
	
	if input_vector != Vector2.ZERO:
		buffered_input = input_vector

func move_and_collide() -> void:
	# If we have no direction and no buffered input, stop
	if direction == Vector2.ZERO and buffered_input == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	
	# If we have no current direction, try to use buffered input
	if direction == Vector2.ZERO:
		if can_move(buffered_input):
			direction = buffered_input
			buffered_input = Vector2.ZERO
	
	# If we have a direction, try to move in that direction
	if direction != Vector2.ZERO:
		if can_move(direction):
			# Move in the current direction
			velocity = direction * speed
			
			# Check if we've reached the target grid cell
			if is_close_to_target():
				snap_to_grid()
				# After snapping, check for new buffered input
				if buffered_input != Vector2.ZERO and can_move(buffered_input):
					direction = buffered_input
					buffered_input = Vector2.ZERO
				elif not can_move(direction):
					# If we can't continue in the current direction, stop and try buffered input
					direction = Vector2.ZERO
					if buffered_input != Vector2.ZERO and can_move(buffered_input):
						direction = buffered_input
						buffered_input = Vector2.ZERO
		else:
			# Can't move in current direction, try buffered input
			if buffered_input != Vector2.ZERO and can_move(buffered_input):
				direction = buffered_input
				buffered_input = Vector2.ZERO
			else:
				# Can't move anywhere, stop
				direction = Vector2.ZERO
				velocity = Vector2.ZERO

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

func is_close_to_target() -> bool:
	return global_position.distance_to(target_position) < 5.0

func snap_to_grid() -> void:
	# Snap current position to the nearest grid cell
	var grid_x: int = round(global_position.x / GRID_SIZE) * GRID_SIZE
	var grid_y: int = round(global_position.y / GRID_SIZE) * GRID_SIZE
	global_position = Vector2(grid_x, grid_y)
	target_position = global_position

func update_animation() -> void:
	if direction == Vector2.RIGHT:
		animated_sprite.animation = "right"
		animated_sprite.flip_h = false
	elif direction == Vector2.LEFT:
		animated_sprite.animation = "left"
		animated_sprite.flip_h = true  # Assuming left animation is just flipped right
	elif direction == Vector2.UP:
		animated_sprite.animation = "up"
	elif direction == Vector2.DOWN:
		animated_sprite.animation = "down"
	else:
		# Idle - stop animation
		animated_sprite.stop()
		# Show the first frame of the current direction's animation
		if animated_sprite.animation != "":
			animated_sprite.frame = 0

# Signals
signal pellet_collected
signal power_pellet_collected
signal ghost_collided(ghost_type)

func _on_body_entered(body: Node) -> void:
	# Check for pellets
	if body.is_in_group("pellet"):
		body.queue_free()
		pellet_collected.emit()
	elif body.is_in_group("power_pellet"):
		body.queue_free()
		power_pellet_collected.emit()
	# Check for ghosts
	elif body.is_in_group("ghost"):
		# We'll handle ghost collision in the game manager for now
		pass