extends Node

## Manages synchronized playback of audio and MIDI files.
## Provides timing information and emits signals for playback state changes.

signal playback_started
signal playback_stopped

@export var audio_stream: AudioStream
@export var midi_file_path: String = ""
@export var default_bpm: float = 120.0
@export var audio_delay_ms: float = 2000.0  ## Delay audio to give UI time to animate beats

@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _midi_resource: Resource = null
var _is_playing: bool = false
var _playback_start_time_ms: float = 0.0
var _audio_start_time_ms: float = 0.0
var _audio_delay_timer: Timer = null

func _ready() -> void:
	add_child(audio_player)
	audio_player.finished.connect(_on_audio_finished)
	
	_audio_delay_timer = Timer.new()
	_audio_delay_timer.one_shot = true
	_audio_delay_timer.timeout.connect(_start_delayed_audio)
	add_child(_audio_delay_timer)

func load_files(p_audio_stream: AudioStream, p_midi_path: String) -> bool:
	audio_stream = p_audio_stream
	midi_file_path = p_midi_path
	
	if audio_stream == null:
		push_error("MusicPlayer: No audio stream provided")
		return false
	
	if midi_file_path.is_empty():
		push_error("MusicPlayer: No MIDI file path provided")
		return false
	
	if not FileAccess.file_exists(midi_file_path):
		push_error("MusicPlayer: MIDI file not found: " + midi_file_path)
		return false
	
	_midi_resource = load(midi_file_path)
	if _midi_resource == null:
		push_error("MusicPlayer: Failed to load MIDI file: " + midi_file_path)
		return false
	
	audio_player.stream = audio_stream
	
	return true

func start_playback() -> void:
	if audio_player.stream == null:
		push_error("MusicPlayer: Cannot start playback - no audio stream loaded")
		return
	
	if _midi_resource == null:
		push_error("MusicPlayer: Cannot start playback - no MIDI resource loaded")
		return
	
	_is_playing = true
	_playback_start_time_ms = Time.get_ticks_msec()
	_audio_start_time_ms = _playback_start_time_ms + audio_delay_ms
	
	# Start audio after delay to give beats time to animate
	if audio_delay_ms > 0:
		_audio_delay_timer.start(audio_delay_ms / 1000.0)
	else:
		audio_player.play()
	
	playback_started.emit()

func _start_delayed_audio() -> void:
	if _is_playing:
		audio_player.play()

func stop_playback() -> void:
	if not _is_playing:
		return
	
	_is_playing = false
	audio_player.stop()
	playback_stopped.emit()

func get_current_time_ms() -> float:
	if not _is_playing:
		return 0.0
	
	var current_real_time_ms: float = Time.get_ticks_msec()
	
	# CRITICAL: Start timing at negative offset to create pre-roll period
	# This allows notes to spawn and animate BEFORE beat 0
	# Audio is delayed by audio_delay_ms, so timeline starts at -audio_delay_ms
	# This aligns song time 0 with when audio actually plays, not when playback starts
	var song_time_ms: float = current_real_time_ms - _playback_start_time_ms - audio_delay_ms
	
	# Add audio buffer latency compensation for sample-accurate timing
	var audio_latency_ms: float = (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) * 1000.0
	song_time_ms += audio_latency_ms
	
	return song_time_ms

func get_tempo_map() -> Array:
	if _midi_resource == null:
		push_error("MusicPlayer: No MIDI resource loaded")
		return _create_default_tempo_map()
	
	# Try various possible property/method names for tempo map
	if "tempo_map" in _midi_resource:
		return _midi_resource.tempo_map
	elif "get_tempo_map" in _midi_resource:
		return _midi_resource.get_tempo_map()
	elif "tempos" in _midi_resource:
		return _midi_resource.tempos
	elif "tempo_events" in _midi_resource:
		return _midi_resource.tempo_events
	else:
		# MidiResource doesn't expose tempo map, create default
		print("MusicPlayer: Using default tempo map (BPM: %.1f)" % default_bpm)
		return _create_default_tempo_map()

func _create_default_tempo_map() -> Array:
	# Create a simple single-tempo map
	return [{
		"tick": 0,
		"bpm": default_bpm,
		"microseconds_per_quarter_note": 60000000.0 / default_bpm
	}]

func get_midi_resource() -> Resource:
	return _midi_resource

func is_playing() -> bool:
	return _is_playing

func _on_audio_finished() -> void:
	stop_playback()
