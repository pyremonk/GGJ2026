extends Node

## Manages synchronized playback of audio files.
## Provides timing information and emits signals for playback state changes.

signal playback_started
signal playback_stopped
signal playback_paused
signal playback_resumed

@export var audio_stream: AudioStream
@export var default_bpm: float = 120.0
@export var audio_delay_ms: float = 2000.0  ## Delay audio to give UI time to animate beats

@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _is_playing: bool = false
var _is_paused: bool = false
var _playback_start_time_ms: float = 0.0
var _audio_start_time_ms: float = 0.0
var _pause_time_ms: float = 0.0
var _paused_song_position_ms: float = 0.0
var _audio_delay_timer: Timer = null

func _ready() -> void:
	add_child(audio_player)
	audio_player.finished.connect(_on_audio_finished)
	
	_audio_delay_timer = Timer.new()
	_audio_delay_timer.one_shot = true
	_audio_delay_timer.timeout.connect(_start_delayed_audio)
	add_child(_audio_delay_timer)

func load_files(p_audio_stream: AudioStream) -> bool:
	audio_stream = p_audio_stream
	
	if audio_stream == null:
		push_error("MusicPlayer: No audio stream provided")
		return false
	
	audio_player.stream = audio_stream
	
	return true

func start_playback() -> void:
	if audio_player.stream == null:
		push_error("MusicPlayer: Cannot start playback - no audio stream loaded")
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

func pause_playback() -> void:
	if not _is_playing or _is_paused:
		return
	
	_is_paused = true
	_pause_time_ms = Time.get_ticks_msec()
	_paused_song_position_ms = get_current_time_ms()
	audio_player.stream_paused = true
	playback_paused.emit()


func resume_playback() -> void:
	if not _is_playing or not _is_paused:
		return
	
	var pause_duration_ms: float = Time.get_ticks_msec() - _pause_time_ms
	_playback_start_time_ms += pause_duration_ms
	_audio_start_time_ms += pause_duration_ms
	
	_is_paused = false
	audio_player.stream_paused = false
	playback_resumed.emit()


func stop_playback() -> void:
	if not _is_playing:
		return
	
	_is_playing = false
	_is_paused = false
	audio_player.stop()
	playback_stopped.emit()

func get_current_time_ms() -> float:
	if not _is_playing:
		return 0.0
	
	if _is_paused:
		return _paused_song_position_ms
	
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



func is_playing() -> bool:
	return _is_playing


func is_paused() -> bool:
	return _is_paused

func _on_audio_finished() -> void:
	stop_playback()
