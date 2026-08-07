extends Node

# Ghost AI controller - manages state transitions for all ghosts
# This would typically be attached to a GameManager or similar node

# State durations (in seconds)
const SCATTER_TIME: float = 7.0
const CHASE_TIME: float = 20.0
const FRIGHTENED_TIME: float = 6.0  # Base time, can be modified by level

# Current state
var current_state: String = "scatter"
var state_timer: float = 0.0

# References to all ghosts
var ghosts: Array = []

func _ready() -> void:
	# Find all ghost nodes in the scene
	var game_scene: Node = get_tree().get_current_scene()
	if game_scene:
		ghosts = game_scene.get_group("ghosts")
	
	# Start with scatter state
	_change_state("scatter")

func _process(delta: float) -> void:
	# Update state timer
	state_timer += delta
	
	# Check for state transitions (only during scatter/chase)
	if current_state == "scatter" and state_timer >= SCATTER_TIME:
		_change_state("chase")
	elif current_state == "chase" and state_timer >= CHASE_TIME:
		_change_state("scatter")
	
	# Note: Frightened state is handled individually by each ghost when power pellet is eaten

func _change_state(new_state: String) -> void:
	current_state = new_state
	state_timer = 0.0
	
	# Tell all ghosts to change state
	for ghost in ghosts:
		if ghost:
			ghost.call("_set_ai_state", new_state)

# Called when power pellet is eaten
func make_all_ghosts_frightened(duration: float) -> void:
	current_state = "frightened"
	state_timer = 0.0
	
	for ghost in ghosts:
		if ghost:
			ghost.call("make_frightened", duration)

# Called when frightened state ends normally
func _on_frightened_ended() -> void:
	# Return to previous state (chase if we were in chase, etc.)
	# For simplicity, we'll go back to chase
	_change_state("chase")