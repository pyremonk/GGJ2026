@tool
extends EditorPlugin
## Editor plugin that automatically generates beat chart JSON when MIDI files are imported

const BeatChartGenerator: Script = preload("res://addons/beat_chart_generator/beat_chart_generator.gd")

var _file_system_dock: FileSystemDock = null
var _editor_interface: EditorInterface = null


func _enter_tree() -> void:
	_editor_interface = get_editor_interface()
	
	# Connect to filesystem signals
	var filesystem: EditorFileSystem = _editor_interface.get_resource_filesystem()
	if filesystem:
		filesystem.resources_reimported.connect(_on_resources_reimported)
	
	print("BeatChartGenerator plugin activated")


func _exit_tree() -> void:
	var filesystem: EditorFileSystem = _editor_interface.get_resource_filesystem()
	if filesystem and filesystem.resources_reimported.is_connected(_on_resources_reimported):
		filesystem.resources_reimported.disconnect(_on_resources_reimported)
	
	print("BeatChartGenerator plugin deactivated")


## Called when resources are reimported (including MIDI files)
func _on_resources_reimported(resources: PackedStringArray) -> void:
	var midi_files: Array[String] = []
	
	# Filter for MIDI files
	for resource_path in resources:
		var extension: String = resource_path.get_extension().to_lower()
		if extension in ["mid", "midi"]:
			midi_files.append(resource_path)
	
	# Generate beat charts for any reimported MIDI files
	if not midi_files.is_empty():
		print("\n=== Auto-generating beat charts for %d MIDI file(s) ===" % midi_files.size())
		for midi_path in midi_files:
			_generate_beat_chart(midi_path)
		print("=== Auto-generation complete ===\n")


## Generate beat chart for a single MIDI file
func _generate_beat_chart(midi_path: String) -> void:
	# Use the beat chart generator script
	var generator: EditorScript = BeatChartGenerator.new()
	
	# Call the generation method directly
	# Note: We need to inline the generation logic since EditorScript._run() 
	# is meant to be called by the editor, not programmatically
	
	print("Processing: %s" % midi_path)
	
	var midi_resource: Resource = ResourceLoader.load(midi_path)
	if midi_resource == null:
		push_error("  Failed to load MIDI resource")
		return
	
	# Extract data using generator methods
	var tempo_map: Array = generator._extract_tempo_map(midi_resource)
	if tempo_map.is_empty():
		push_error("  Failed to extract tempo map")
		return
	
	var beat_events: Array = generator._extract_beat_events(midi_resource, tempo_map)
	
	# Create beat chart
	var BeatChart: Script = load("res://scripts/midi/BeatChart.gd")
	var beat_chart: Resource = BeatChart.new()
	beat_chart.beat_events = beat_events
	beat_chart.tempo_map = tempo_map
	beat_chart.metadata = {
		"track_name": midi_path.get_file().get_basename(),
		"source_midi": midi_path,
		"total_beats": beat_events.size(),
		"duration_ms": beat_events[-1]["hit_time_ms"] if not beat_events.is_empty() else 0.0,
		"generated_timestamp": Time.get_datetime_string_from_system(false, true)
	}
	
	# Save to JSON
	var json_path: String = midi_path.get_basename() + ".beats.json"
	if beat_chart.save_to_file(json_path):
		print("  ✓ Generated: %s" % json_path)
		print("    - %d beat events" % beat_events.size())
		print("    - %d tempo changes" % tempo_map.size())
		
		# Trigger filesystem scan to show new file in editor
		_editor_interface.get_resource_filesystem().scan()
	else:
		push_error("  Failed to save JSON file")
