extends Control
class_name MainMenu
## Main Menu screen (section 10 of the spec). Start Game / AI Demo toggle /
## high score display.

@onready var start_button: Button = $VBox/StartButton
@onready var ai_toggle_button: CheckButton = $VBox/AIToggle
@onready var high_score_label: Label = $VBox/HighScoreLabel

var _ai_mode: bool = false

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	ai_toggle_button.toggled.connect(_on_ai_toggled)
	high_score_label.text = "HIGH SCORE: %d" % GameManager.high_score
	GameManager.high_score_changed.connect(func(v): high_score_label.text = "HIGH SCORE: %d" % v)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_start"):
		_on_start_pressed()

func _on_ai_toggled(pressed: bool) -> void:
	_ai_mode = pressed

func _on_start_pressed() -> void:
	GameManager.pending_ai_mode = _ai_mode
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
