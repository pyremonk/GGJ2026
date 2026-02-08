@tool
extends EditorScript

## Debug script to test MIDI file parsing
## Run via File > Run

func _run() -> void:
	print("=== MIDI Debug Test ===")
	
	var midi_path: String = "res://assets/testing_track/Testing_Track.mid"
	print("Loading: ", midi_path)
	
	# Load MIDI resource
	var midi_resource: Resource = ResourceLoader.load(midi_path)
	if midi_resource == null:
		push_error("Failed to load MIDI resource")
		return
	
	print("MIDI resource loaded successfully!")
	print("Type: ", midi_resource.get_class())
	
	# Try different API methods to introspect the MIDI resource
	print("\n=== Resource Methods ===")
	var methods: Array = midi_resource.get_method_list()
	for method in methods:
		if not method.name.begins_with("_"):
			print("  - ", method.name)
	
	print("\n=== Resource Properties ===")
	var properties: Array = midi_resource.get_property_list()
	for prop in properties:
		if prop.usage & PROPERTY_USAGE_STORAGE:
			var prop_name: String = prop.name
			var prop_value = midi_resource.get(prop_name)
			print("  - %s = %s" % [prop_name, str(prop_value)])
	
	# Test common MIDI API methods
	print("\n=== Testing MIDI API Methods ===")
	
	# Try get_track_count
	if midi_resource.has_method("get_track_count"):
		var track_count: int = midi_resource.get_track_count()
		print("  track_count: ", track_count)
		
		# Try get_track_events for each track
		for i in range(track_count):
			if midi_resource.has_method("get_track_events"):
				var events: Array = midi_resource.get_track_events(i)
				print("  Track %d events: %d" % [i, events.size()])
				
				# Show first few events
				for j in range(min(5, events.size())):
					print("    Event %d: %s" % [j, str(events[j])])
	
	# Try get_tempo_map
	if midi_resource.has_method("get_tempo_map"):
		var tempo_map: Array = midi_resource.get_tempo_map()
		print("  tempo_map entries: ", tempo_map.size())
		for entry in tempo_map:
			print("    ", entry)
	
	# Try get_ticks_per_beat
	if midi_resource.has_method("get_ticks_per_beat"):
		var ppq: int = midi_resource.get_ticks_per_beat()
		print("  ticks_per_beat (PPQ): ", ppq)
	
	# Try property access
	if "tracks" in midi_resource:
		var tracks = midi_resource.tracks
		print("  tracks property: ", typeof(tracks), " size: ", tracks.size() if tracks is Array else "N/A")
	
	if "ppq" in midi_resource:
		print("  ppq property: ", midi_resource.ppq)
	
	if "ticks_per_beat" in midi_resource:
		print("  ticks_per_beat property: ", midi_resource.ticks_per_beat)
	
	if "tempo_map" in midi_resource:
		var tempo_map = midi_resource.tempo_map
		print("  tempo_map property: ", typeof(tempo_map), " size: ", tempo_map.size() if tempo_map is Array else "N/A")
	
	print("\n=== Test Complete ===")
