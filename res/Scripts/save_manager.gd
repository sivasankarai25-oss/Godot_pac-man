extends Node

# Save file path
const SAVE_FILE: str = "user://save.cfg"

# Default values
var high_score: int = 0
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.9
var fullscreen: bool = false

func _ready() -> void:
	load()

func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	# Game data
	config.set_value("game", "high_score", high_score)
	
	# Audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Video settings
	config.set_value("video", "fullscreen", fullscreen)
	
	config.save(SAVE_FILE)

func load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_FILE) == OK:
		high_score = config.get_value("game", "high_score", 0)
		master_volume = config.get_value("audio", "master_volume", 0.8)
		music_volume = config.get_value("audio", "music_volume", 0.7)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.9)
		fullscreen = config.get_value("video", "fullscreen", false)
	else:
		# If no save file, use defaults and save them
		save()

# Getters and setters (optional, but useful for encapsulation)
func get_high_score() -> int:
	return high_score

func set_high_score(score: int) -> void:
	high_score = score
	save()  # Save immediately when high score changes

func get_master_volume() -> float:
	return master_volume

func set_master_volume(volume: float) -> void:
	master_volume = volume
	save()

func get_music_volume() -> float:
	return music_volume

func set_music_volume(volume: float) -> void:
	music_volume = volume
	save()

func get_sfx_volume() -> float:
	return sfx_volume

func set_sfx_volume(volume: float) -> void:
	sfx_volume = volume
	save()

func get_fullscreen() -> bool:
	return fullscreen

func set_fullscreen(fullscreen: bool) -> void:
	self.fullscreen = fullscreen
	save()
	# Apply the fullscreen setting immediately
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)