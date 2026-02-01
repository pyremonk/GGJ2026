extends Node

## Parses MIDI data and generates beat events for gameplay.
## Supports hybrid approach: authored notes from MIDI track or auto-generated from tempo.

signal beat_event(beat: BeatEvent)

@export var beat_subdivision: int = 4
@export var target_track_index: int = 1

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

var _midi_resource: Resource = null
var _tempo_map: Array = []
var _beat_events: Array[BeatEvent] = []
var _beats_generated: bool = false

func load_midi_data(midi_resource: Resource, tempo_map: Array) -> void:
	if midi_resource == null:
		push_error("MIDIEventRouter: Cannot load null MIDI resource")
		return
	
	_midi_resource = midi_resource
	_tempo_map = tempo_map
	_beats_generated = false

func generate_beat_events() -> Array[BeatEvent]:
	if _midi_resource == null:
		push_error("MIDIEventRouter: No MIDI resource loaded")
		return []
	
	if _beats_generated:
		return _beat_events
	
	print("MIDIEventRouter: Checking for authored beats in track ", target_track_index)
	var has_notes: bool = _check_track_has_notes(target_track_index)
	print("  Track has notes: ", has_notes)
	
	if has_notes:
		print("MIDIEventRouter: Using authored notes from MIDI track")
		_beat_events = _generate_beats_from_notes()
	else:
		print("MIDIEventRouter: Using auto-generated beats from tempo")
		_beat_events = _generate_beats_from_tempo()
	
	_beats_generated = true
	return _beat_events

func _check_track_has_notes(track_index: int) -> bool:
	if _midi_resource == null:
		return false
	
	if "tracks" in _midi_resource:
		var tracks = _midi_resource.tracks
		if tracks is Array and track_index < tracks.size():
			var track = tracks[track_index]
			if track is Array:
				return track.size() > 0
			elif "events" in track:
				var events = track.events
				if events is Array:
					return events.size() > 0
	
	if "get_track_count" in _midi_resource:
		var track_count: int = _midi_resource.get_track_count()
		if track_index >= track_count:
			return false
		
		if "get_track_events" in _midi_resource:
			var events = _midi_resource.get_track_events(track_index)
			if events is Array:
				return events.size() > 0
	
	return false

func _generate_beats_from_notes() -> Array[BeatEvent]:
	var beats: Array[BeatEvent] = []
	
	if _midi_resource == null:
		return beats
	
	print("MIDIEventRouter: Parsing notes from track ", target_track_index)
	
	var track_events: Array = []
	
	if "tracks" in _midi_resource:
		var tracks = _midi_resource.tracks
		print("  Found 'tracks' property, size: ", tracks.size() if tracks is Array else "not an array")
		if tracks is Array and target_track_index < tracks.size():
			var track = tracks[target_track_index]
			if track is Array:
				track_events = track
				print("  Track is Array, events: ", track_events.size())
			elif "events" in track:
				track_events = track.events
				print("  Track has 'events' property, events: ", track_events.size())
	elif "get_track_events" in _midi_resource:
		track_events = _midi_resource.get_track_events(target_track_index)
		print("  Used get_track_events(), events: ", track_events.size())
	
	print("  Total events to process: ", track_events.size())
	
	var beat_number: int = 0
	var accumulated_ticks: float = 0.0
	var last_note_on_tick: float = -1000.0  # Track last accepted note to avoid duplicates
	
	for event in track_events:
		if event == null:
			continue
		
		if not event is Dictionary:
			continue
		
		# Accumulate delta time to get absolute position
		var delta: float = event.get("delta", 0.0)
		accumulated_ticks += delta
		
		# Check if this is a note-on event
		var event_type: String = event.get("type", "")
		var subtype_value = event.get("subtype", -1)
		var velocity_value = event.get("data", 0)
		var note_value = event.get("note", -1)  # MIDI note pitch
		
		var subtype: int = int(subtype_value) if subtype_value is String else subtype_value
		var velocity: int = int(velocity_value) if velocity_value is String else velocity_value
		var note_pitch: int = int(note_value) if note_value is String else note_value
		
		# Debug: Print all note events
		if event_type == "note":
			print("  Note event: subtype=%d, velocity=%d, note=%d, delta=%.0f, accum_ticks=%.0f" % [subtype, velocity, note_pitch, delta, accumulated_ticks])
		
		# Note-on: type="note" AND subtype=9 AND velocity > 0
		var is_note_on: bool = (event_type == "note" and subtype == 9 and velocity > 0)
		
		if is_note_on:
			# Skip duplicate notes at the same tick (within 10 ticks tolerance)
			if abs(accumulated_ticks - last_note_on_tick) < 10:
				print("    -> Note-on SKIPPED (duplicate at same tick)")
				continue
			
			var time_ms: float = _ticks_to_ms(int(accumulated_ticks))
			print("    -> Note-on ACCEPTED at tick %.0f (%.0fms), note=%d, velocity=%d" % [accumulated_ticks, time_ms, note_pitch, velocity])
			var direction: String = TARGET_MAPPING.get(note_pitch, "down")
			var beat: BeatEvent = BeatEvent.new(time_ms, beat_number, note_pitch, direction, velocity)
			beats.append(beat)
			beat_number += 1
			last_note_on_tick = accumulated_ticks
	
	print("  Found %d note-on events" % beats.size())
	
	return beats

func _generate_beats_from_tempo() -> Array[BeatEvent]:
	var beats: Array[BeatEvent] = []
	
	if _tempo_map.is_empty():
		push_error("MIDIEventRouter: Cannot generate beats - tempo map is empty")
		return beats
	
	print("MIDIEventRouter: Generating beats from tempo map")
	print("  Tempo map size: ", _tempo_map.size())
	print("  Beat subdivision: ", beat_subdivision)
	
	var ppq: int = 480
	if "ppq" in _midi_resource:
		ppq = _midi_resource.ppq
	elif "ticks_per_beat" in _midi_resource:
		ppq = _midi_resource.ticks_per_beat
	elif "get_ppq" in _midi_resource:
		ppq = _midi_resource.get_ppq()
	
	var song_length_ms: float = _estimate_song_length_ms()
	
	var current_time_ms: float = 0.0
	var beat_number: int = 0
	var tempo_index: int = 0
	
	var current_tempo_bpm: float = 120.0
	var next_tempo_change_ms: float = song_length_ms + 1.0
	
	if _tempo_map.size() > 0:
		var first_tempo = _tempo_map[0]
		if first_tempo is Dictionary:
			current_tempo_bpm = first_tempo.get("bpm", 120.0)
		elif "bpm" in first_tempo:
			current_tempo_bpm = first_tempo.bpm
		
		if _tempo_map.size() > 1:
			var second_tempo = _tempo_map[1]
			var second_tick: int = 0
			if second_tempo is Dictionary:
				second_tick = second_tempo.get("tick", 0)
			elif "tick" in second_tempo:
				second_tick = second_tempo.tick
			next_tempo_change_ms = _ticks_to_ms(second_tick)
			tempo_index = 1
	
	var ms_per_quarter_note: float = 60000.0 / current_tempo_bpm
	var ms_per_beat: float = ms_per_quarter_note * (4.0 / beat_subdivision)
	
	print("  Song length: %.1f ms" % song_length_ms)
	print("  First tempo BPM: %.1f" % current_tempo_bpm)
	print("  MS per beat: %.2f ms" % ms_per_beat)
	
	while current_time_ms < song_length_ms:
		if current_time_ms >= next_tempo_change_ms and tempo_index < _tempo_map.size():
			var tempo_event = _tempo_map[tempo_index]
			if tempo_event is Dictionary:
				current_tempo_bpm = tempo_event.get("bpm", current_tempo_bpm)
			elif "bpm" in tempo_event:
				current_tempo_bpm = tempo_event.bpm
			
			ms_per_quarter_note = 60000.0 / current_tempo_bpm
			ms_per_beat = ms_per_quarter_note * (4.0 / beat_subdivision)
			
			tempo_index += 1
			if tempo_index < _tempo_map.size():
				var next_tempo = _tempo_map[tempo_index]
				var next_tick: int = 0
				if next_tempo is Dictionary:
					next_tick = next_tempo.get("tick", 0)
				elif "tick" in next_tempo:
					next_tick = next_tempo.tick
				next_tempo_change_ms = _ticks_to_ms(next_tick)
			else:
				next_tempo_change_ms = song_length_ms + 1.0
		
		# Auto-generated beats default to "down" direction for rhythm test (S key)
		var beat: BeatEvent = BeatEvent.new(current_time_ms, beat_number, -1, "down")
		beats.append(beat)
		
		current_time_ms += ms_per_beat
		beat_number += 1
	
	print("  Generated %d beats" % beats.size())
	
	return beats

func _ticks_to_ms(ticks: int) -> float:
	if _midi_resource == null:
		return 0.0
	
	if "ticks_to_ms" in _midi_resource:
		return _midi_resource.ticks_to_ms(ticks)
	
	var ppq: int = 480
	if "ppq" in _midi_resource:
		ppq = _midi_resource.ppq
	elif "ticks_per_beat" in _midi_resource:
		ppq = _midi_resource.ticks_per_beat
	
	if _tempo_map.is_empty():
		var default_bpm: float = 120.0
		var ms_per_quarter_note: float = 60000.0 / default_bpm
		return (ticks / float(ppq)) * ms_per_quarter_note
	
	var accumulated_time_ms: float = 0.0
	var accumulated_ticks: int = 0
	
	for i in range(_tempo_map.size()):
		var tempo_event = _tempo_map[i]
		var tempo_tick: int = 0
		var tempo_bpm: float = 120.0
		
		if tempo_event is Dictionary:
			tempo_tick = tempo_event.get("tick", 0)
			tempo_bpm = tempo_event.get("bpm", 120.0)
		elif "tick" in tempo_event and "bpm" in tempo_event:
			tempo_tick = tempo_event.tick
			tempo_bpm = tempo_event.bpm
		
		if tempo_tick > ticks:
			var ticks_in_this_section: int = ticks - accumulated_ticks
			var ms_per_quarter_note: float = 60000.0 / tempo_bpm
			var ms_per_tick: float = ms_per_quarter_note / ppq
			accumulated_time_ms += ticks_in_this_section * ms_per_tick
			break
		
		if i < _tempo_map.size() - 1:
			var next_tempo = _tempo_map[i + 1]
			var next_tick: int = 0
			if next_tempo is Dictionary:
				next_tick = next_tempo.get("tick", 0)
			elif "tick" in next_tempo:
				next_tick = next_tempo.tick
			
			var ticks_in_this_section: int = min(next_tick, ticks) - tempo_tick
			var ms_per_quarter_note: float = 60000.0 / tempo_bpm
			var ms_per_tick: float = ms_per_quarter_note / ppq
			accumulated_time_ms += ticks_in_this_section * ms_per_tick
			accumulated_ticks = next_tick
		else:
			var ticks_in_this_section: int = ticks - tempo_tick
			var ms_per_quarter_note: float = 60000.0 / tempo_bpm
			var ms_per_tick: float = ms_per_quarter_note / ppq
			accumulated_time_ms += ticks_in_this_section * ms_per_tick
	
	return accumulated_time_ms

func _estimate_song_length_ms() -> float:
	const DEFAULT_LENGTH_MS: float = 120000.0
	
	if _midi_resource == null:
		return DEFAULT_LENGTH_MS
	
	if "length_ms" in _midi_resource:
		return _midi_resource.length_ms
	elif "get_length_ms" in _midi_resource:
		return _midi_resource.get_length_ms()
	
	return DEFAULT_LENGTH_MS

func emit_all_beat_events() -> void:
	for beat in _beat_events:
		beat_event.emit(beat)
