extends Node
## Autoload singleton. Centralizes SFX playback through a small pool of
## AudioStreamPlayer nodes so multiple sounds can overlap without cutting
## each other off (e.g. chomp + eat-ghost in the same frame).

const SOUNDS := {
	"chomp": preload("res://assets/Sounds/pacman_chomp.wav"),
	"death": preload("res://assets/Sounds/pacman_death.wav"),
	"eat_ghost": preload("res://assets/Sounds/pacman_eatghost.wav"),
	"power_pellet": preload("res://assets/Sounds/pacman_power_pellet.wav"),
}

const POOL_SIZE: int = 6

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(sound_name: String) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: unknown sound '%s'" % sound_name)
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = SOUNDS[sound_name]
	player.play()

func stop_all() -> void:
	for p in _players:
		p.stop()
