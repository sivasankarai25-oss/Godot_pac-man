extends Node
# Autoload-free static config. Accessed as Constants.X from any script
# because it's a class_name, not an autoload -- avoids clashing with
# GameManager's autoload singleton while still being globally reachable.
class_name Constants

# --- Grid / geometry ---
const TILE_SIZE: int = 32
const MAZE_COLS: int = 28
const MAZE_ROWS: int = 31

# --- Speeds (tiles per second) ---
const PACMAN_SPEED: float = 6.0
const GHOST_SPEED: float = 5.5
const GHOST_FRIGHTENED_SPEED: float = 3.5
const GHOST_EATEN_SPEED: float = 9.0

# --- Scoring (single source of truth, per spec section 13) ---
const SCORE_PELLET: int = 10
const SCORE_POWER_PELLET: int = 50
const SCORE_CHERRY_BASE: int = 100
const SCORE_GHOST_CHAIN: Array[int] = [200, 400, 800, 1600] # increasing bonus per ghost eaten in one power phase
const SCORE_LEVEL_COMPLETE: int = 1000

# --- Lives / levels ---
const STARTING_LIVES: int = 3
const MAX_LEVEL_SPEED_MULTIPLIER: float = 1.4 # cap so higher levels don't become unfair
const SPEED_INCREASE_PER_LEVEL: float = 0.03

# --- Power-up (frightened mode) ---
const FRIGHTENED_DURATION: float = 7.0
const FRIGHTENED_WARNING_TIME: float = 2.0 # last N seconds ghosts flash white
const FRIGHTENED_DURATION_MIN: float = 3.0 # floor so high levels stay fair
const FRIGHTENED_DURATION_DECREASE_PER_LEVEL: float = 0.4

# --- Ghost house ---
const GHOST_RELEASE_INTERVAL: float = 4.0 # seconds between ghosts leaving house at round start

# --- Save data ---
const SAVE_PATH: String = "user://pacman_savedata.cfg"
