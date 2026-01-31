extends Node

## Latency calibration system using metronome beats.
## Measures average input offset to calibrate hit windows.

signal calibration_started
signal calibration_beat(beat_number: int)
signal calibration_complete(offset_ms: float)

@export var metronome_bpm: float = 120.0
@export var num_calibration_beats: int = 8
@export var click_sound_path: String = "res://assets/metronome_click/click1.ogg"

@onready var metronome_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _click_sound: AudioStream = null

var _is_calibrating: bool = false
var _calibration_beat_times: Array[float] = []
var _player_tap_times: Array[float] = []
var _current_beat: int = 0
var _next_beat_time_ms: float = 0.0
var _beat_interval_ms: float = 0.0
var _calibration_start_time_ms: float = 0.0

func _ready() -> void:
	add_child(metronome_player)
	
	# Load click sound
	if FileAccess.file_exists(click_sound_path):
		_click_sound = load(click_sound_path)
		if _click_sound != null:
			metronome_player.stream = _click_sound
		else:
			push_error("LatencyCalibration: Failed to load click sound: " + click_sound_path)
	else:
		push_error("LatencyCalibration: Click sound file not found: " + click_sound_path)

func start_calibration() -> void:
	if _is_calibrating:
		return
	
	_is_calibrating = true
	_calibration_beat_times.clear()
	_player_tap_times.clear()
	_current_beat = 0
	
	_beat_interval_ms = 60000.0 / metronome_bpm
	_calibration_start_time_ms = Time.get_ticks_msec() + 1000.0
	_next_beat_time_ms = _calibration_start_time_ms
	
	calibration_started.emit()

func _process(delta: float) -> void:
	if not _is_calibrating:
		return
	
	var current_time_ms: float = Time.get_ticks_msec()
	
	if current_time_ms >= _next_beat_time_ms and _current_beat < num_calibration_beats:
		_on_metronome_beat()
		_next_beat_time_ms += _beat_interval_ms
		_current_beat += 1

func _on_metronome_beat() -> void:
	# Play click sound
	if _click_sound != null:
		metronome_player.play()
	
	var beat_time_ms: float = Time.get_ticks_msec()
	_calibration_beat_times.append(beat_time_ms)
	calibration_beat.emit(_current_beat)

func _on_player_tap(tap_time_ms: float) -> void:
	if not _is_calibrating:
		return
	
	_player_tap_times.append(tap_time_ms)
	
	if _player_tap_times.size() >= num_calibration_beats:
		finish_calibration()

func finish_calibration() -> float:
	if not _is_calibrating:
		return 0.0
	
	_is_calibrating = false
	
	if _player_tap_times.is_empty() or _calibration_beat_times.is_empty():
		calibration_complete.emit(0.0)
		return 0.0
	
	var total_offset: float = 0.0
	var num_valid_taps: int = 0
	
	for i in range(min(_player_tap_times.size(), _calibration_beat_times.size())):
		var offset: float = _player_tap_times[i] - _calibration_beat_times[i]
		
		if abs(offset) < 500.0:
			total_offset += offset
			num_valid_taps += 1
	
	var average_offset: float = 0.0
	if num_valid_taps > 0:
		average_offset = total_offset / num_valid_taps
	
	calibration_complete.emit(average_offset)
	return average_offset

func cancel_calibration() -> void:
	_is_calibrating = false
	_calibration_beat_times.clear()
	_player_tap_times.clear()
	_current_beat = 0

func is_calibrating() -> bool:
	return _is_calibrating

func get_current_beat() -> int:
	return _current_beat
