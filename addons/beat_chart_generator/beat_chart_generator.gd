@tool
extends EditorScript
## Editor script to generate beat chart JSON files from MIDI resources
## Run via File > Run to generate beat charts for all MIDI files in assets/tracks/

const BeatChart: Script = preload("res://scripts/midi/BeatChart.gd")

# MIDI note to direction mapping (must match MIDIEventRouter and NoteSpawner)
const TARGET_MAPPING: Dictionary = {
	60: "left",    # C4
	61: "left",    # C#4
	62: "left",    # D4
	63: "up",      # D#4
	64: "up",      # E4
	65: "up",      # F4
	66: "right",   # F#4
	67: "right",   # G4
	68: "right",   # G#4
	69: "down",    # A4
	70: "down",    # A#4
	71: "down"     # B4
}


func _run() -> void:
	print("=== Beat Chart Generator ===")
	var midi_files: Array[String] = _find_midi_files("res://assets/")
	
	if midi_files.is_empty():
		print("No MIDI files found in assets/ folder")
		return
	
	print("Found %d MIDI file(s)" % midi_files.size())
	
	for midi_path in midi_files:
		_generate_beat_chart_for_midi(midi_path)
	
	print("\n=== Generation Complete ===")


## Recursively find all .mid files in a directory
func _find_midi_files(dir_path: String) -> Array[String]:
	var midi_files: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	
	if dir == null:
		push_error("Failed to open directory: %s" % dir_path)
		return midi_files
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		
		if dir.current_is_dir():
			if not file_name.begins_with("."):  # Skip hidden folders
				midi_files.append_array(_find_midi_files(full_path))
		elif file_name.get_extension().to_lower() in ["mid", "midi"]:
			midi_files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return midi_files


## Generate beat chart JSON for a single MIDI file
func _generate_beat_chart_for_midi(midi_path: String) -> void:
	print("\nProcessing: %s" % midi_path)
	
	# Load MIDI resource
	var midi_resource: Resource = ResourceLoader.load(midi_path)
	if midi_resource == null:
		push_error("  Failed to load MIDI resource")
		return
	
	# Extract tempo map
	var tempo_map: Array[Dictionary] = _extract_tempo_map(midi_resource)
	if tempo_map.is_empty():
		push_error("  Failed to extract tempo map")
		return
	
	# Extract beat events
	var beat_events: Array[Dictionary] = _extract_beat_events(midi_resource, tempo_map)
	
	# Estimate song duration (needed for auto-generated beats fallback)
	var duration_ms: float = 0.0
	if not beat_events.is_empty():
		# Use last beat time if we have beat events
		duration_ms = beat_events[-1]["hit_time_ms"]
	else:
		# Estimate from tempo map if no beats found
		# Use default song length that can be adjusted per track
		duration_ms = 120000.0  # 2 minutes default
		push_warning("  No beat events found. Using default duration for auto-generation fallback.")
	
	# Create beat chart
	var beat_chart: Resource = BeatChart.new()
	beat_chart.beat_events = beat_events
	beat_chart.tempo_map = tempo_map
	beat_chart.metadata = {
		"track_name": midi_path.get_file().get_basename(),
		"source_midi": midi_path,
		"total_beats": beat_events.size(),
		"duration_ms": duration_ms,
		"generated_timestamp": Time.get_datetime_string_from_system(false, true)
	}
	
	# Save to JSON file
	var json_path: String = midi_path.get_basename() + ".beats.json"
	if beat_chart.save_to_file(json_path):
		print("  ✓ Generated: %s" % json_path)
		print("    - %d beat events" % beat_events.size())
		print("    - %d tempo changes" % tempo_map.size())
	else:
		push_error("  Failed to save JSON file")


## Extract tempo map from MIDI resource
func _extract_tempo_map(midi_resource: Resource) -> Array[Dictionary]:
	var tempo_map_data: Array[Dictionary] = []
	
	# Get PPQ (pulses per quarter note)
	var ppq: int = 480  # Default
	if midi_resource.has_method("get_ticks_per_beat"):
		ppq = midi_resource.get_ticks_per_beat()
	elif "ppq" in midi_resource:
		ppq = midi_resource.ppq
	elif "ticks_per_beat" in midi_resource:
		ppq = midi_resource.ticks_per_beat
	
	# Try to get tempo map via method/property (old approach)
	var raw_tempo_map: Array = []
	if midi_resource.has_method("get_tempo_map"):
		var tempo_data = midi_resource.get_tempo_map()
		# Handle Dictionary or Array return
		if tempo_data is Dictionary:
			if "events" in tempo_data:
				raw_tempo_map = tempo_data["events"]
			else:
				raw_tempo_map = tempo_data.values()
		elif tempo_data is Array:
			raw_tempo_map = tempo_data
	elif "tempo_map" in midi_resource:
		var tempo_data = midi_resource.tempo_map
		if tempo_data is Array:
			raw_tempo_map = tempo_data
	
	# If no direct tempo map, extract from track events (MIDI meta event 0x51)
	if raw_tempo_map.is_empty():
		print("  DEBUG: No tempo_map method/property, extracting from track events...")
		var track_count: int = 0
		if midi_resource.has_method("get_track_count"):
			track_count = midi_resource.get_track_count()
		
		if track_count > 0:
			# Usually tempo events are in track 0
			var track_data = midi_resource.tracks[0] if "tracks" in midi_resource else []
			
			if track_data is Dictionary:
				track_data = track_data.values() if not "events" in track_data else track_data["events"]
			
			var absolute_tick: int = 0
			for event in track_data:
				if not event is Dictionary:
					continue
				
				# Accumulate ticks
				var delta_value = event.get("delta", 0.0)
				var delta: int = 0
				if delta_value is float:
					delta = roundi(delta_value)
				elif delta_value is int:
					delta = delta_value
				absolute_tick += delta
				
				# Look for tempo meta events (type="meta", subtype=81)
				var event_type: String = event.get("type", "")
				var subtype = event.get("subtype", 0)
				
				if event_type == "meta" and subtype == 81:
					# Tempo event: data is microseconds per quarter note
					var microseconds_per_qn = event.get("data", 500000)
					var bpm: float = 60000000.0 / float(microseconds_per_qn)
					
					raw_tempo_map.append({
						"tick": absolute_tick,
						"bpm": bpm
					})
					print("  DEBUG: Found tempo event at tick ", absolute_tick, ": ", bpm, " BPM")
	
	if raw_tempo_map.is_empty():
		push_warning("  No tempo map found, using default 120 BPM")
		tempo_map_data.append({
			"time_ms": 0.0,
			"bpm": 120.0,
			"ppq": ppq
		})
		return tempo_map_data
	
	# Convert tempo events to milliseconds
	var accumulated_ms: float = 0.0
	var accumulated_ticks: int = 0
	var current_bpm: float = 120.0
	
	for tempo_event in raw_tempo_map:
		var tick: int = tempo_event.get("tick", 0)
		var bpm: float = tempo_event.get("bpm", 120.0)
		
		# Calculate time elapsed since last tempo change
		if accumulated_ticks > 0 and current_bpm > 0.0:
			var ticks_elapsed: int = tick - accumulated_ticks
			var ms_per_tick: float = (60000.0 / current_bpm) / float(ppq)
			accumulated_ms += ticks_elapsed * ms_per_tick
		
		# Add tempo change entry
		tempo_map_data.append({
			"time_ms": accumulated_ms,
			"bpm": bpm,
			"ppq": ppq
		})
		
		accumulated_ticks = tick
		current_bpm = bpm
	
	return tempo_map_data


## Extract beat events from MIDI resource
func _extract_beat_events(midi_resource: Resource, tempo_map: Array[Dictionary]) -> Array[Dictionary]:
	var beat_events: Array[Dictionary] = []
	
	# Get PPQ
	var ppq: int = tempo_map[0]["ppq"] if not tempo_map.is_empty() else 480
	
	print("  DEBUG: Extracting beat events...")
	print("  DEBUG: MIDI resource type: ", midi_resource.get_class())
	
	# Get track count
	var track_count: int = 0
	if midi_resource.has_method("get_track_count"):
		track_count = midi_resource.get_track_count()
		print("  DEBUG: get_track_count() returned: ", track_count)
	elif "tracks" in midi_resource:
		track_count = midi_resource.tracks.size()
		print("  DEBUG: tracks property size: ", track_count)
	else:
		print("  DEBUG: No track count method or property found!")
	
	if track_count == 0:
		push_warning("  No tracks found in MIDI file")
		return beat_events
	
	print("  DEBUG: Parsing ", track_count, " tracks for note events...")
	
	# Parse all tracks for note-on events
	for track_index in range(track_count):
		var track_events: Array = []
		
		if midi_resource.has_method("get_track_events"):
			var track_data = midi_resource.get_track_events(track_index)
			print("  DEBUG: Track ", track_index, " get_track_events() returned type: ", typeof(track_data))
			
			# Handle Dictionary return (godot_midi plugin returns Dictionary)
			if track_data is Dictionary:
				# Try common dictionary structures
				if "events" in track_data:
					track_events = track_data["events"]
					print("  DEBUG: Track ", track_index, " - extracted ", track_events.size(), " events from dict['events']")
				else:
					# Convert dictionary to array of values (in case it's indexed like {0: event, 1: event, ...})
					track_events = track_data.values()
					print("  DEBUG: Track ", track_index, " - converted dict to array: ", track_events.size(), " entries")
			elif track_data is Array:
				track_events = track_data
				print("  DEBUG: Track ", track_index, " - got Array with ", track_events.size(), " events")
			else:
				print("  DEBUG: Track ", track_index, " - unexpected type!")
		elif "tracks" in midi_resource and track_index < midi_resource.tracks.size():
			var track_data = midi_resource.tracks[track_index]
			print("  DEBUG: Track ", track_index, " tracks property type: ", typeof(track_data))
			
			# Handle Dictionary or Array
			if track_data is Dictionary:
				if "events" in track_data:
					track_events = track_data["events"]
				else:
					track_events = track_data.values()
			elif track_data is Array:
				track_events = track_data
			print("  DEBUG: Track ", track_index, " - final array has ", track_events.size(), " events")
		else:
			print("  DEBUG: Track ", track_index, " - no events found!")
		
		if track_events.is_empty():
			print("  DEBUG: Track ", track_index, " is empty, skipping")
			continue
		
		print("  DEBUG: Track ", track_index, " - scanning ", track_events.size(), " events...")
		
		# Show first event structure to understand format
		if track_events.size() > 0:
			print("  DEBUG: First event structure: ", track_events[0])
		
		# Accumulate delta timing to get absolute ticks
		var absolute_tick: int = 0
		var note_on_count: int = 0
		var mapped_note_count: int = 0
		
		for event_index in range(track_events.size()):
			var event = track_events[event_index]
			if not event is Dictionary:
				if event_index < 3:  # Only log first few
					print("  DEBUG: Track ", track_index, " event ", event_index, " is not a Dictionary: ", typeof(event))
				continue
			
			# Accumulate tick position (delta is float from MIDI plugin, convert to int safely)
			var delta_value = event.get("delta", 0.0)
			var delta: int = 0
			if delta_value is float:
				delta = roundi(delta_value)
			elif delta_value is int:
				delta = delta_value
			absolute_tick += delta
			
			# Show first few events to understand structure
			if event_index < 3:
				print("  DEBUG: Track ", track_index, " Event ", event_index, ": ", event)
			
			# Filter for note-on events (type="note", subtype=9, velocity>0)
			var event_type: String = event.get("type", "")
			
			# Skip non-note events early
			if event_type != "note":
				continue
			
			# Now safe to extract note event fields
			# MIDI plugin stores velocity in "data" field, not "velocity"
			var subtype_value = event.get("subtype", 0)
			var subtype: int = subtype_value if subtype_value is int else roundi(subtype_value)
			
			var velocity_value = event.get("data", 0)
			var velocity: int = velocity_value if velocity_value is int else roundi(velocity_value)
			
			var note_value = event.get("note", -1)
			var note: int = note_value if note_value is int else roundi(note_value)
			
			if event_type == "note" and subtype == 9 and velocity > 0:
				note_on_count += 1
				if note_on_count <= 3:  # Log first few note-on events
					print("  DEBUG: Found note-on: note=", note, " velocity=", velocity, " tick=", absolute_tick)
				
				# Check if note is in our mapping
				if not TARGET_MAPPING.has(note):
					if note_on_count <= 3:
						print("  DEBUG: Note ", note, " not in TARGET_MAPPING (expected 60-71)")
					continue
				
				mapped_note_count += 1
				
				mapped_note_count += 1
				
				# Convert ticks to milliseconds
				var time_ms: float = _ticks_to_ms(absolute_tick, tempo_map, ppq)
				var direction: String = TARGET_MAPPING[note]
				
				beat_events.append({
					"hit_time_ms": time_ms,
					"beat_number": beat_events.size(),
					"midi_note": note,
					"direction": direction,
					"velocity": velocity
				})
		
		print("  DEBUG: Track ", track_index, " - found ", note_on_count, " note-on events, ", mapped_note_count, " mapped to targets")
	
	# Sort by hit time
	beat_events.sort_custom(func(a, b): return a["hit_time_ms"] < b["hit_time_ms"])
	
	# Renumber beats after sorting
	for i in range(beat_events.size()):
		beat_events[i]["beat_number"] = i
	
	print("  DEBUG: Total beat events extracted: ", beat_events.size())
	if beat_events.size() > 0:
		print("  DEBUG: First beat at ", beat_events[0]["hit_time_ms"], "ms, direction: ", beat_events[0]["direction"])
	
	return beat_events


## Convert MIDI ticks to milliseconds using tempo map
func _ticks_to_ms(ticks: int, tempo_map: Array[Dictionary], ppq: int) -> float:
	if tempo_map.is_empty():
		return 0.0
	
	var accumulated_ms: float = 0.0
	var accumulated_ticks: int = 0
	var current_tempo_index: int = 0
	
	# Find which tempo sections this tick falls into
	while current_tempo_index < tempo_map.size():
		var current_tempo: Dictionary = tempo_map[current_tempo_index]
		
		# Check if there's a next tempo change
		var next_tempo_tick: int = -1
		if current_tempo_index + 1 < tempo_map.size():
			var next_tempo: Dictionary = tempo_map[current_tempo_index + 1]
			# Calculate tick position of next tempo change
			var bpm: float = current_tempo["bpm"]
			var ms_per_tick: float = (60000.0 / bpm) / float(ppq)
			var ms_to_next: float = next_tempo["time_ms"] - current_tempo["time_ms"]
			next_tempo_tick = accumulated_ticks + int(ms_to_next / ms_per_tick)
		
		# If target tick is before next tempo change (or there is no next change)
		if next_tempo_tick < 0 or ticks <= next_tempo_tick:
			# Calculate time within current tempo section
			var ticks_in_section: int = ticks - accumulated_ticks
			var bpm: float = current_tempo["bpm"]
			var ms_per_tick: float = (60000.0 / bpm) / float(ppq)
			accumulated_ms += ticks_in_section * ms_per_tick
			break
		else:
			# Move to next tempo section
			var ticks_in_section: int = next_tempo_tick - accumulated_ticks
			var bpm: float = current_tempo["bpm"]
			var ms_per_tick: float = (60000.0 / bpm) / float(ppq)
			accumulated_ms += ticks_in_section * ms_per_tick
			accumulated_ticks = next_tempo_tick
			current_tempo_index += 1
	
	return accumulated_ms
