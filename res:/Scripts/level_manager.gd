extends Node

# Level configuration
const LEVELS: Array = [
	{
		"name": "Level 1",
		"ghost_speed": 1.0,
		"frightened_duration": 6.0,
		"pellet_score": 10,
		"power_pellet_score": 50,
		"ghost_eat_scores": [200, 400, 800, 1600]
	},
	{
		"name": "Level 2",
		"ghost_speed": 1.1,
		"frightened_duration": 5.5,
		"pellet_score": 10,
		"power_pellet_score": 50,
		"ghost_eat_scores": [200, 400, 800, 1600]
	},
	{
		"name": "Level 3",
		"ghost_speed": 1.2,
		"frightened_duration": 5.0,
		"pellet_score": 10,
		"power_pellet_score": 50,
		"ghost_eat_scores": [200, 400, 800, 1600]
	},
	{
		"name": "Level 4+",
		"ghost_speed": 1.3,
		"frightened_duration": 4.0,
		"pellet_score": 10,
		"power_pellet_score": 50,
		"ghost_eat_scores": [200, 400, 800, 1600]
	}
]

# Current level data
var current_level_data: Dictionary

func _ready() -> void:
	# Initialize to level 1
	set_level(1)

func set_level(level_number: int) -> void:
	# Clamp level number to our defined levels
	var index: int = clamp(level_number - 1, 0, LEVELS.size() - 1)
	current_level_data = LEVELS[index].duplicate()
	
	# Add level number to the data for reference
	current_level_data["level_number"] = level_number
	
	# Apply settings to game (this would be called by game.gd)
	# For now, we just store the data
	
func get_ghost_speed_multiplier() -> float:
	return current_level_data.get("ghost_speed", 1.0)

func get_frightened_duration() -> float:
	return current_level_data.get("frightened_duration", 6.0)

func get_pellet_score() -> int:
	return current_level_data.get("pellet_score", 10)

func get_power_pellet_score() -> int:
	return current_level_data.get("power_pellet_score", 50)

func get_ghost_eat_scores() -> Array:
	return current_level_data.get("ghost_eat_scores", [200, 400, 800, 1600])

func get_level_name() -> String:
	return current_level_data.get("name", "Level Unknown")

func get_level_number() -> int:
	return current_level_data.get("level_number", 1)