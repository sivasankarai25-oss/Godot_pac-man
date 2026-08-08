extends CanvasLayer
class_name UIManager
## Drives the HUD and overlay screens (section 10 of the spec). Listens to
## GameManager signals so it never needs to be polled or manually synced.

@onready var score_label: Label = $HUD/TopBar/ScoreLabel
@onready var high_score_label: Label = $HUD/TopBar/HighScoreLabel
@onready var level_label: Label = $HUD/TopBar/LevelLabel
@onready var lives_container: HBoxContainer = $HUD/BottomBar/LivesContainer
@onready var power_timer_bar: ProgressBar = $HUD/BottomBar/PowerTimerBar

@onready var pause_screen: Control = $PauseScreen
@onready var game_over_screen: Control = $GameOverScreen
@onready var level_complete_screen: Control = $LevelCompleteScreen
@onready var ready_screen: Control = $ReadyScreen

@onready var final_score_label: Label = $GameOverScreen/Panel/VBox/FinalScoreLabel

@onready var pause_button: Button = $HUD/PauseButton
@onready var restart_screen_button: Button = $HUD/RestartScreenButton
@onready var resume_button: Button = $PauseScreen/Panel/ResumeButton
@onready var pause_menu_button: Button = $PauseScreen/Panel/MenuButton
@onready var game_over_restart_button: Button = $GameOverScreen/Panel/VBox/RestartButton
@onready var game_over_menu_button: Button = $GameOverScreen/Panel/VBox/MenuButton

const LIFE_ICON := preload("res://assets/Pacman/Pacman_01.png")

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.power_mode_timer_updated.connect(_on_power_timer_updated)

	pause_button.pressed.connect(_on_pause_pressed)
	restart_screen_button.pressed.connect(_on_restart_pressed)
	resume_button.pressed.connect(_on_pause_pressed)
	pause_menu_button.pressed.connect(_on_menu_pressed)
	game_over_restart_button.pressed.connect(_on_restart_pressed)
	game_over_menu_button.pressed.connect(_on_menu_pressed)

	_on_score_changed(GameManager.score)
	_on_high_score_changed(GameManager.high_score)
	_on_lives_changed(GameManager.lives)
	_on_level_changed(GameManager.level)
	power_timer_bar.visible = false
	_hide_all_overlays()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_pressed()
	elif event.is_action_pressed("restart"):
		_on_restart_pressed()

func _on_pause_pressed() -> void:
	if GameManager.current_state in [GameManager.State.PLAYING, GameManager.State.POWER_MODE, GameManager.State.PAUSED]:
		GameManager.toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	var controller := get_tree().current_scene
	if controller and controller.has_method("restart_game"):
		controller.restart_game()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _hide_all_overlays() -> void:
	pause_screen.visible = false
	game_over_screen.visible = false
	level_complete_screen.visible = false
	ready_screen.visible = false

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %d" % new_score

func _on_high_score_changed(new_high_score: int) -> void:
	high_score_label.text = "HIGH: %d" % new_high_score

func _on_lives_changed(new_lives: int) -> void:
	for child in lives_container.get_children():
		child.queue_free()
	for i in range(max(new_lives, 0)):
		var icon := TextureRect.new()
		icon.texture = LIFE_ICON
		icon.custom_minimum_size = Vector2(20, 20)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lives_container.add_child(icon)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "LEVEL: %d" % new_level

func _on_power_timer_updated(time_left: float, duration: float) -> void:
	power_timer_bar.visible = time_left > 0.0
	power_timer_bar.max_value = duration
	power_timer_bar.value = time_left

func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	_hide_all_overlays()
	match new_state:
		GameManager.State.PAUSED:
			pause_screen.visible = true
		GameManager.State.GAME_OVER:
			final_score_label.text = "FINAL SCORE: %d" % GameManager.score
			game_over_screen.visible = true
		GameManager.State.LEVEL_COMPLETE:
			level_complete_screen.visible = true
		GameManager.State.READY:
			ready_screen.visible = true
		GameManager.State.POWER_MODE:
			pass # timer bar driven by power_mode_timer_updated
		_:
			pass
