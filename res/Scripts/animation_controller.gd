extends Node

# Animation controller for managing game-wide animations and effects
# This could handle screen shakes, flashes, transitions, etc.

# Signal for screen shake
signal screen_shake(intensity, duration)

# Signal for flash effect
signal flash_effect(color, duration)

# Signal for popup text (e.g., score when eating ghosts)
signal popup_text(text, position, color, duration)

func _ready() -> void:
	# Initialize any animation players or effect systems
	pass

func trigger_screen_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	screen_shake.emit(intensity, duration)

func trigger_flash_effect(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	flash_effect.emit(color, duration)

func show_popup_text(text: String, position: Vector2, color: Color = Color.WHITE, duration: float = 1.0) -> void:
	popup_text.emit(text, position, color, duration)

# Specific game event animations
func on_pellet_eaten() -> void:
	# Small flash or sound could go here
	pass

func on_power_pellet_eaten() -> void:
	# Screen flash or shake
	trigger_flash_effect(Color.BLUE, 0.2)

func on_ghost_eaten() -> void:
	# Popup with score value would be handled by the caller passing the score
	pass

func on_pacman_death() -> void:
	# Screen shake and possibly a death animation
	trigger_screen_shake(20.0, 0.5)

func on_level_complete() -> void:
	# Celebration flash or sound
	trigger_flash_effect(Color.YELLOW, 0.5)

func on_game_over() -> void:
	# Screen shake and flash
	trigger_screen_shake(15.0, 1.0)
	trigger_flash_effect(Color.RED, 0.5)

func on_victory() -> void:
	# Victory flash
	trigger_flash_effect(Color.GREEN, 1.0)