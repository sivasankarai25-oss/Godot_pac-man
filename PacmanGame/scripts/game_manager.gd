extends Node
## Autoload singleton (see project.godot [autoload]). Owns the game state
## machine, score, lives, and level -- the single source of truth other
## scripts read from and signal into. Section 11 of the spec.

enum State {
	MENU,
	READY,
	PLAYING,
	PAUSED,
	POWER_MODE,
	LEVEL_COMPLETE,
	GAME_OVER,
}

signal state_changed(new_state: State, old_state: State)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal level_changed(new_level: int)
signal high_score_changed(new_high_score: int)
signal power_mode_timer_updated(time_left: float, duration: float)

var current_state: State = State.MENU
var score: int = 0
var lives: int = Constants.STARTING_LIVES
var level: int = 1
var high_score: int = 0
var pending_ai_mode: bool = false # set by MainMenu before loading Game.tscn

var _ghost_eaten_chain_index: int = 0 # resets each time frightened mode (re)starts
var _pre_pause_state: State = State.PLAYING

func _ready() -> void:
	_load_high_score()

func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	var old := current_state
	current_state = new_state
	state_changed.emit(new_state, old)

func start_new_game() -> void:
	score = 0
	lives = Constants.STARTING_LIVES
	level = 1
	_ghost_eaten_chain_index = 0
	score_changed.emit(score)
	lives_changed.emit(lives)
	level_changed.emit(level)
	change_state(State.READY)

func begin_playing() -> void:
	change_state(State.PLAYING)

func toggle_pause() -> void:
	if current_state == State.PAUSED:
		change_state(_pre_pause_state)
		get_tree().paused = false
	elif current_state == State.PLAYING or current_state == State.POWER_MODE:
		_pre_pause_state = current_state
		change_state(State.PAUSED)
		get_tree().paused = true

func enter_power_mode() -> void:
	_ghost_eaten_chain_index = 0
	change_state(State.POWER_MODE)

func exit_power_mode() -> void:
	if current_state == State.POWER_MODE:
		change_state(State.PLAYING)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)

func score_pellet() -> void:
	add_score(Constants.SCORE_PELLET)

func score_power_pellet() -> void:
	add_score(Constants.SCORE_POWER_PELLET)

func score_cherry() -> void:
	add_score(Constants.SCORE_CHERRY_BASE)

## Returns the score awarded, following the increasing-bonus chain per spec section 13.
func score_ghost_eaten() -> int:
	var idx: int = min(_ghost_eaten_chain_index, Constants.SCORE_GHOST_CHAIN.size() - 1)
	var amount: int = Constants.SCORE_GHOST_CHAIN[idx]
	_ghost_eaten_chain_index += 1
	add_score(amount)
	return amount

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		_save_high_score()
		change_state(State.GAME_OVER)
	else:
		change_state(State.READY)

func complete_level() -> void:
	add_score(Constants.SCORE_LEVEL_COMPLETE)
	change_state(State.LEVEL_COMPLETE)

func advance_to_next_level() -> void:
	level += 1
	level_changed.emit(level)
	change_state(State.READY)

func return_to_menu() -> void:
	_save_high_score()
	get_tree().paused = false
	change_state(State.MENU)

## Difficulty scaling that stays capped so higher levels remain fair (spec 14).
func get_speed_multiplier() -> float:
	var mult: float = 1.0 + (level - 1) * Constants.SPEED_INCREASE_PER_LEVEL
	return min(mult, Constants.MAX_LEVEL_SPEED_MULTIPLIER)

func get_frightened_duration() -> float:
	var duration: float = Constants.FRIGHTENED_DURATION - (level - 1) * Constants.FRIGHTENED_DURATION_DECREASE_PER_LEVEL
	return max(duration, Constants.FRIGHTENED_DURATION_MIN)

func _load_high_score() -> void:
	var config := ConfigFile.new()
	var err := config.load(Constants.SAVE_PATH)
	if err == OK:
		high_score = config.get_value("scores", "high_score", 0)
	high_score_changed.emit(high_score)

func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.load(Constants.SAVE_PATH) # ignore error, we're overwriting anyway
	config.set_value("scores", "high_score", high_score)
	config.save(Constants.SAVE_PATH)
