extends Node

## Loads pre-generated beat chart data from JSON files for gameplay.
## Supports hybrid approach: authored notes from beat chart or auto-generated from tempo.

signal beat_event(beat: BeatEvent)

@export var beat_subdivision: int = 4
@export var default_bpm: float = 120.0

## Maps MIDI notes to directions (direction = spawn side = input key = feedback location)
## Note movement direction is purely visual - gameplay uses spawn side for all logic
const TARGET_MAPPING: Dictionary = {
	60: "left",    # C4 - spawns LEFT, player presses LEFT
	61: "left",    # C#4 - spawns LEFT, player presses LEFT
	62: "left",    # D4 - spawns LEFT, player presses LEFT
	63: "up",      # D#4 - spawns TOP, player presses UP
	64: "up",      # E4 - spawns TOP, player presses UP
	65: "up",      # F4 - spawns TOP, player presses UP
	66: "right",   # F#4 - spawns RIGHT, player presses RIGHT
	67: "right",   # G4 - spawns RIGHT, player presses RIGHT
	68: "right",   # G#4 - spawns RIGHT, player presses RIGHT
	69: "down",    # A4 - spawns BOTTOM, player presses DOWN
	70: "down",    # A#4 - spawns BOTTOM, player presses DOWN
	71: "down"     # B4 - spawns BOTTOM, player presses DOWN
}

var _beat_chart: BeatChart = null
var _beat_events: Array[BeatEvent] = []
var _beats_generated: bool = false

func load_beat_chart(beat_chart_path: String) -> void:
	if beat_chart_path.is_empty():
		push_error("MIDIEventRouter: Beat chart path is empty")
		return
	
	_beat_chart = BeatChart.load_from_file(beat_chart_path)
	if _beat_chart == null:
		push_error("MIDIEventRouter: Failed to load beat chart from: %s" % beat_chart_path)
		return
	
	print("MIDIEventRouter: Loaded beat chart from %s" % beat_chart_path)
	print("  Total beats: %d" % _beat_chart.beat_events.size())
	print("  Tempo changes: %d" % _beat_chart.tempo_map.size())
	
	_beats_generated = false

func generate_beat_events() -> Array[BeatEvent]:
	if _beat_chart == null:
		push_error("MIDIEventRouter: No beat chart loaded")
		return []
	
	if _beats_generated:
		return _beat_events
	
	# Check if beat chart has authored notes
	var has_notes: bool = not _beat_chart.beat_events.is_empty()
	
	if has_notes:
		print("MIDIEventRouter: Using authored notes from beat chart")
		_beat_events = _load_beats_from_chart()
	else:
		print("MIDIEventRouter: Using auto-generated beats from tempo")
		_beat_events = _generate_beats_from_tempo()
	
	_beats_generated = true
	return _beat_events

func _load_beats_from_chart() -> Array[BeatEvent]:
	var beats: Array[BeatEvent] = []
	
	if _beat_chart == null or _beat_chart.beat_events.is_empty():
		return beats
	
	print("MIDIEventRouter: Loading %d beats from chart" % _beat_chart.beat_events.size())
	
	# Convert dictionary data to BeatEvent objects
	for event_data in _beat_chart.beat_events:
		if not event_data is Dictionary:
			continue
		
		var hit_time_ms: float = event_data.get("hit_time_ms", 0.0)
		var beat_number: int = event_data.get("beat_number", 0)
		var midi_note: int = event_data.get("midi_note", -1)
		var direction: String = event_data.get("direction", "down")
		var velocity: int = event_data.get("velocity", 64)
		
		var beat: BeatEvent = BeatEvent.new(hit_time_ms, beat_number, midi_note, direction, velocity)
		beats.append(beat)
	
	print("  Loaded %d beat events" % beats.size())
	return beats

func _generate_beats_from_tempo() -> Array[BeatEvent]:
	var beats: Array[BeatEvent] = []
	
	var tempo_map: Array[Dictionary] = []
	if _beat_chart and not _beat_chart.tempo_map.is_empty():
		tempo_map = _beat_chart.tempo_map
	else:
		# Create default tempo if no tempo map available
		tempo_map.append({
			"time_ms": 0.0,
			"bpm": default_bpm,
			"ppq": 480
		})
	
	if tempo_map.is_empty():
		push_error("MIDIEventRouter: Cannot generate beats - no tempo data available")
		return beats
	
	print("MIDIEventRouter: Generating beats from tempo map")
	print("  Tempo map size: ", tempo_map.size())
	print("  Beat subdivision: ", beat_subdivision)
	
	var song_length_ms: float = _estimate_song_length_ms()
	var current_time_ms: float = 0.0
	var beat_number: int = 0
	var tempo_index: int = 0
	
	var current_tempo_bpm: float = tempo_map[0].get("bpm", default_bpm)
	var next_tempo_change_ms: float = song_length_ms + 1.0
	
	if tempo_map.size() > 1:
		next_tempo_change_ms = tempo_map[1].get("time_ms", song_length_ms + 1.0)
		tempo_index = 1
	
	var ms_per_quarter_note: float = 60000.0 / current_tempo_bpm
	var ms_per_beat: float = ms_per_quarter_note * (4.0 / beat_subdivision)
	
	print("  Song length: %.1f ms" % song_length_ms)
	print("  First tempo BPM: %.1f" % current_tempo_bpm)
	print("  MS per beat: %.2f ms" % ms_per_beat)
	
	while current_time_ms < song_length_ms:
		# Check for tempo changes
		if current_time_ms >= next_tempo_change_ms and tempo_index < tempo_map.size():
			var tempo_event: Dictionary = tempo_map[tempo_index]
			current_tempo_bpm = tempo_event.get("bpm", current_tempo_bpm)
			
			ms_per_quarter_note = 60000.0 / current_tempo_bpm
			ms_per_beat = ms_per_quarter_note * (4.0 / beat_subdivision)
			
			tempo_index += 1
			if tempo_index < tempo_map.size():
				next_tempo_change_ms = tempo_map[tempo_index].get("time_ms", song_length_ms + 1.0)
			else:
				next_tempo_change_ms = song_length_ms + 1.0
		
		# Auto-generated beats default to "down" direction for rhythm test (S key)
		var beat: BeatEvent = BeatEvent.new(current_time_ms, beat_number, -1, "down")
		beats.append(beat)
		
		current_time_ms += ms_per_beat
		beat_number += 1
	
	print("  Generated %d beats" % beats.size())
	
	return beats

func _estimate_song_length_ms() -> float:
	const DEFAULT_LENGTH_MS: float = 120000.0
	
	if _beat_chart == null:
		return DEFAULT_LENGTH_MS
	
	# Try to get from metadata (ignore if 0)
	if _beat_chart.metadata.has("duration_ms"):
		var duration: float = _beat_chart.metadata.get("duration_ms", 0.0)
		if duration > 0.0:
			return duration
	
	# Try to get from last beat event
	if not _beat_chart.beat_events.is_empty():
		var last_beat: Dictionary = _beat_chart.beat_events[-1]
		var last_time: float = last_beat.get("hit_time_ms", 0.0)
		if last_time > 0.0:
			return last_time + 5000.0  # Add 5 seconds buffer
	
	# Fallback to default
	return DEFAULT_LENGTH_MS

func emit_all_beat_events() -> void:
	for beat in _beat_events:
		beat_event.emit(beat)
