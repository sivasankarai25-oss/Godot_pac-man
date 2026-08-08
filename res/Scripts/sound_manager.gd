extends Node

# Audio buses
const MASTER_BUS: str = "Master"
const MUSIC_BUS: str = "Music"
const SFX_BUS: str = "SFX"

# Audio streams (we'll load them dynamically or assume they are in res://Assets/Audio/)
# For now, we'll use placeholders and the user must assign them in the inspector.

@export var music_intro: AudioStream
@export var music_game: AudioStream
@export var music_intermission: AudioStream

@export var sfx_pellet: AudioStream
@export var sfx_power_pellet: AudioStream
@export var sfx_ghost_eat: AudioStream
@export var sfx_death: AudioStream
@export var sfx_game_over: AudioStream
@export var sfx_victory: AudioStream
@export var sfx_eat_fruit: AudioStream  # Bonus fruit, if we add later

# AudioStreamPlayers
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Volume settings (0.0 to 1.0)
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9

func _ready() -> void:
	# Set up audio buses
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(sfx_volume))
	
	# Start intro music
	play_music(music_intro)

func play_music(stream: AudioStream) -> void:
	if stream and music_player:
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_sfx(stream: AudioStream) -> void:
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.play()

# Volume control functions
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(music_volume))

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(sfx_volume))

func mute_master(muted: bool) -> void:
	var volume: float = 0.0 if muted else master_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(volume))

func mute_music(muted: bool) -> void:
	var volume: float = 0.0 if muted else music_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(volume))

func mute_sfx(muted: bool) -> void:
	var volume: float = 0.0 if muted else sfx_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(volume))

func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log10(linear)