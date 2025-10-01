extends Node

## Audio Manager - Centralized Audio System
##
## Manages all audio playback including sound effects and background music.
## Provides volume control and audio bus management.
## Loaded as an autoload singleton.

# ==================== Audio Bus Names ====================

const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

# ==================== Signals ====================

signal music_finished()
signal sfx_finished(sfx_name: String)

# ==================== State ====================

# Audio players
var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8  # Maximum simultaneous sound effects

# Current playback state
var current_music: AudioStream = null
var current_music_name: String = ""
var is_music_playing: bool = false

# Volume settings (0.0 to 1.0)
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# Audio cache (for quick access)
var loaded_music: Dictionary = {}  # name -> AudioStream
var loaded_sfx: Dictionary = {}    # name -> AudioStream

# ==================== Lifecycle ====================

func _ready() -> void:
	"""Initialize the audio manager."""
	_setup_audio_buses()
	_create_audio_players()
	_load_default_audio()

	print("[AudioManager] Ready - Music: %d tracks, SFX: %d sounds" % [loaded_music.size(), loaded_sfx.size()])


# ==================== Setup Methods ====================

func _setup_audio_buses() -> void:
	"""Configure audio buses for volume control."""
	# Set initial volumes
	_set_bus_volume(BUS_MASTER, master_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, sfx_volume)


func _create_audio_players() -> void:
	"""Create audio player nodes."""
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# SFX players pool
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer%d" % i
		sfx_player.bus = BUS_SFX
		add_child(sfx_player)
		sfx_players.append(sfx_player)


func _load_default_audio() -> void:
	"""
	Load default audio files.
	TODO: Replace with actual audio files when available.
	For now, this prepares the structure for future audio assets.
	"""
	# Music tracks (to be added later)
	# loaded_music["main_menu"] = load("res://audio/music/main_menu.ogg")
	# loaded_music["battle"] = load("res://audio/music/battle.ogg")
	# loaded_music["victory"] = load("res://audio/music/victory.ogg")

	# Sound effects (to be added later)
	# loaded_sfx["button_press"] = load("res://audio/sfx/button_press.wav")
	# loaded_sfx["move_normal"] = load("res://audio/sfx/move_normal.wav")
	# loaded_sfx["move_super_effective"] = load("res://audio/sfx/move_super_effective.wav")
	# loaded_sfx["pokemon_faint"] = load("res://audio/sfx/faint.wav")
	pass


# ==================== Public Methods - Music ====================

func play_music(music_name: String, fade_in: bool = true, loop: bool = true) -> void:
	"""
	Play background music.

	@param music_name: Name of the music track
	@param fade_in: Whether to fade in the music
	@param loop: Whether to loop the music
	"""
	# Check if music exists
	if not loaded_music.has(music_name):
		push_warning("[AudioManager] Music not found: %s" % music_name)
		return

	# Don't restart if already playing
	if current_music_name == music_name and is_music_playing:
		return

	# Stop current music
	if is_music_playing:
		stop_music(fade_in)  # Use same fade setting for stop
		if fade_in:
			await get_tree().create_timer(0.5).timeout

	# Play new music
	current_music = loaded_music[music_name]
	current_music_name = music_name

	music_player.stream = current_music
	music_player.volume_db = linear_to_db(music_volume) if not fade_in else -80.0
	music_player.play()

	is_music_playing = true

	# Fade in
	if fade_in:
		_fade_music_volume(-80.0, linear_to_db(music_volume), 0.5)

	print("[AudioManager] Playing music: %s (loop: %s)" % [music_name, loop])


func stop_music(fade_out: bool = true) -> void:
	"""
	Stop background music.

	@param fade_out: Whether to fade out the music
	"""
	if not is_music_playing:
		return

	if fade_out:
		await _fade_music_volume(music_player.volume_db, -80.0, 0.5)

	music_player.stop()
	is_music_playing = false
	current_music_name = ""

	print("[AudioManager] Music stopped")


func pause_music() -> void:
	"""Pause the current music."""
	if is_music_playing:
		music_player.stream_paused = true


func resume_music() -> void:
	"""Resume paused music."""
	if is_music_playing:
		music_player.stream_paused = false


# ==================== Public Methods - Sound Effects ====================

func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	"""
	Play a sound effect.

	@param sfx_name: Name of the sound effect
	@param volume_scale: Volume multiplier (0.0 to 1.0)
	"""
	# Check if SFX exists
	if not loaded_sfx.has(sfx_name):
		push_warning("[AudioManager] SFX not found: %s" % sfx_name)
		return

	# Find available player
	var player = _get_available_sfx_player()
	if not player:
		push_warning("[AudioManager] All SFX players busy, dropping sound: %s" % sfx_name)
		return

	# Play sound
	player.stream = loaded_sfx[sfx_name]
	player.volume_db = linear_to_db(sfx_volume * volume_scale)
	player.play()

	print("[AudioManager] Playing SFX: %s" % sfx_name)


func play_sfx_oneshot(sfx_name: String, volume_scale: float = 1.0) -> void:
	"""
	Play a sound effect that won't be interrupted.
	Same as play_sfx but with different semantic meaning.

	@param sfx_name: Name of the sound effect
	@param volume_scale: Volume multiplier (0.0 to 1.0)
	"""
	play_sfx(sfx_name, volume_scale)


func stop_all_sfx() -> void:
	"""Stop all playing sound effects."""
	for player in sfx_players:
		if player.playing:
			player.stop()


# ==================== Public Methods - Volume Control ====================

func set_master_volume(volume: float) -> void:
	"""
	Set master volume.

	@param volume: Volume level (0.0 to 1.0)
	"""
	master_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume(BUS_MASTER, master_volume)


func set_music_volume(volume: float) -> void:
	"""
	Set music volume.

	@param volume: Volume level (0.0 to 1.0)
	"""
	music_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume(BUS_MUSIC, music_volume)

	# Update current music if playing
	if is_music_playing:
		music_player.volume_db = linear_to_db(music_volume)


func set_sfx_volume(volume: float) -> void:
	"""
	Set sound effects volume.

	@param volume: Volume level (0.0 to 1.0)
	"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_set_bus_volume(BUS_SFX, sfx_volume)


func get_master_volume() -> float:
	"""Get master volume (0.0 to 1.0)."""
	return master_volume


func get_music_volume() -> float:
	"""Get music volume (0.0 to 1.0)."""
	return music_volume


func get_sfx_volume() -> float:
	"""Get SFX volume (0.0 to 1.0)."""
	return sfx_volume


# ==================== Public Methods - Audio Loading ====================

func load_music(music_name: String, file_path: String) -> bool:
	"""
	Load a music track.

	@param music_name: Identifier for the music
	@param file_path: Path to audio file
	@return: True if loaded successfully
	"""
	if not FileAccess.file_exists(file_path):
		push_error("[AudioManager] Music file not found: %s" % file_path)
		return false

	var audio_stream = load(file_path)
	if not audio_stream:
		push_error("[AudioManager] Failed to load music: %s" % file_path)
		return false

	loaded_music[music_name] = audio_stream
	print("[AudioManager] Loaded music: %s" % music_name)
	return true


func load_sfx(sfx_name: String, file_path: String) -> bool:
	"""
	Load a sound effect.

	@param sfx_name: Identifier for the SFX
	@param file_path: Path to audio file
	@return: True if loaded successfully
	"""
	if not FileAccess.file_exists(file_path):
		push_error("[AudioManager] SFX file not found: %s" % file_path)
		return false

	var audio_stream = load(file_path)
	if not audio_stream:
		push_error("[AudioManager] Failed to load SFX: %s" % file_path)
		return false

	loaded_sfx[sfx_name] = audio_stream
	print("[AudioManager] Loaded SFX: %s" % sfx_name)
	return true


# ==================== Private Methods - Helpers ====================

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Find an available SFX player."""
	for player in sfx_players:
		if not player.playing:
			return player
	return null


func _set_bus_volume(bus_name: String, volume: float) -> void:
	"""Set volume for an audio bus."""
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		var volume_db = linear_to_db(volume) if volume > 0.0 else -80.0
		AudioServer.set_bus_volume_db(bus_index, volume_db)


func _fade_music_volume(from_db: float, to_db: float, duration: float) -> void:
	"""Fade music volume over time."""
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", to_db, duration).from(from_db)
	await tween.finished


# ==================== Event Handlers ====================

func _on_music_finished() -> void:
	"""Handle music playback finished."""
	is_music_playing = false
	music_finished.emit()
	print("[AudioManager] Music finished: %s" % current_music_name)


# ==================== Debug Methods ====================

func get_audio_stats() -> Dictionary:
	"""Get audio system statistics."""
	var active_sfx = 0
	for player in sfx_players:
		if player.playing:
			active_sfx += 1

	return {
		"music_playing": is_music_playing,
		"current_music": current_music_name,
		"active_sfx": active_sfx,
		"max_sfx": max_sfx_players,
		"loaded_music": loaded_music.size(),
		"loaded_sfx": loaded_sfx.size(),
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
