extends CanvasLayer

# Signals
signal restart_game
signal toggle_pause
signal show_settings
signal toggle_mute

# References to UI elements
@onready var score_label: Label = $"MarginContainer/HBoxContainer/ScoreLabel"
@onready var high_score_label: Label = $"MarginContainer/HBoxContainer/HighScoreLabel"
@onready var lives_label: Label = $"MarginContainer/HBoxContainer/LivesLabel"
@onready var level_label: Label = $"MarginContainer/HBoxContainer/LevelLabel"
@onready var ready_label: Label = $"MarginContainer/ReadyLabel"
@onready var game_over_label: Label = $"MarginContainer/GameOverLabel"
@onready var victory_label: Label = $"MarginContainer/VictoryLabel"

# Game state
var score: int = 0
var high_score: int = 0
var lives: int = 3
var level: int = 1

func _ready() -> void:
	# Load high score from save system (we'll implement save_manager later)
	high_score = _load_high_score()
	
	# Update the display
	_update_display()

func _update_display() -> void:
	score_label.text = String(score).pad_left(6, '0')
	high_score_label.text = "HIGH " + String(high_score).pad_left(6, '0')
	lives_label.text = "LIVES: " + String(lives).pad_left(2, '0')
	level_label.text = "LEVEL: " + String(level).pad_left(2, '0')

func set_score(new_score: int) -> void:
	score = new_score
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	_update_display()

func set_lives(new_lives: int) -> void:
	lives = new_lives
	_update_display()

func set_level(new_level: int) -> void:
	level = new_level
	_update_display()

func show_ready() -> void:
	ready_label.visible = true
	# Optional: play a ready sound
	# We'll hide it after a short delay via a timer or from the game manager

func hide_ready() -> void:
	ready_label.visible = false

func show_game_over() -> void:
	game_over_label.visible = true

func hide_game_over() -> void:
	game_over_label.visible = false

func show_victory() -> void:
	victory_label.visible = true

func hide_victory() -> void:
	victory_label.visible = false

# Save and load high score (using ConfigFile for simplicity)
func _save_high_score(score: int) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("high_score", "score", score)
	config.save("user://high_score.cfg")

func _load_high_score() -> int:
	var config: ConfigFile = ConfigFile.new()
	var result: Error = config.load("user://high_score.cfg")
	if result == OK:
		return config.get_value("high_score", "score", 0)
	return 0

# UI button callbacks (we'll connect these from the HUD scene if we add buttons)
# For now, we'll just emit signals that the game manager can connect to
func _on_pause_button_pressed() -> void:
	toggle_pause.emit()

func _on_restart_button_pressed() -> void:
	restart_game.emit()

func _on_settings_button_pressed() -> void:
	show_settings.emit()

func _on_mute_button_pressed() -> void:
	toggle_mute.emit()