extends Node

# Game states
enum State { MAIN_MENU, GAME, PAUSE, GAME_OVER, VICTORY }

# Current state
var state: State = State.MAIN_MENU

# Reference to the current scene
var current_scene: Node

# Signals
signal state_changed(new_state)

func _ready() -> void:
	# Start in main menu
	change_state(State.MAIN_MENU)

func change_state(new_state: State) -> void:
	# Exit current state
	if current_scene:
		current_scene.queue_free()
	
	state = new_state
	
	# Enter new state
	match state:
		State.MAIN_MENU:
			current_scene = load_main_menu()
		State.GAME:
			current_scene = load_game()
		State.PAUSE:
			current_scene = load_pause_menu()
		State.GAME_OVER:
			current_scene = load_game_over()
		State.VICTORY:
			current_scene = load_victory()
	
	# Add new scene to the tree
	if current_scene:
		add_child(current_scene)
	
	# Emit signal
	state_changed.emit(state)

func load_main_menu() -> Node:
	var scene = preload("res://Scenes/MainMenu.tscn").instantiate()
	# Connect buttons
	var start_button = scene.get_node("VBoxContainer/StartButton")
	var settings_button = scene.get_node("VBoxContainer/SettingsButton")
	var credits_button = scene.get_node("VBoxContainer/CreditsButton")
	var quit_button = scene.get_node("VBoxContainer/QuitButton")
	
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	return scene

func load_game() -> Node:
	var scene = preload("res://Scenes/Game.tscn").instantiate()
	# TODO: Initialize game
	return scene

func load_pause_menu() -> Node:
	var scene = preload("res://Scenes/PauseMenu.tscn").instantiate()
	# TODO: Connect pause menu buttons
	return scene

func load_game_over() -> Node:
	var scene = preload("res://Scenes/GameOver.tscn").instantiate()
	# TODO: Connect game over buttons
	return scene

func load_victory() -> Node:
	var scene = preload("res://Scenes/Victory.tscn").instantiate()
	# TODO: Connect victory buttons
	return scene

# Button callbacks
func _on_start_button_pressed() -> void:
	change_state(State.GAME)

func _on_settings_button_pressed() -> void:
	# TODO: Open settings
	pass

func _on_credits_button_pressed() -> void:
	# TODO: Show credits
	pass

func _on_quit_button_pressed() -> void:
	get_tree().quit()