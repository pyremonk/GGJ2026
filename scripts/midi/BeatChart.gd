class_name BeatChart
extends Resource
## Pre-generated beat chart data exported from MIDI files
## Used at runtime to avoid MIDI plugin dependency for WebGL export

## Array of beat event dictionaries with keys:
## - hit_time_ms: float (absolute song time when beat should be hit)
## - beat_number: int (sequential index)
## - midi_note: int (60-71 for authored notes, -1 for auto-generated)
## - direction: String ("up", "down", "left", "right")
## - velocity: int (MIDI velocity 0-127)
@export var beat_events: Array[Dictionary] = []

## Array of tempo change dictionaries with keys:
## - time_ms: float (absolute song time of tempo change)
## - bpm: float (beats per minute)
## - ppq: int (pulses per quarter note / ticks per beat)
@export var tempo_map: Array[Dictionary] = []

## Additional metadata:
## - track_name: String
## - duration_ms: float (total song length)
## - total_beats: int (number of beat events)
## - generated_timestamp: String (ISO format)
@export var metadata: Dictionary = {}


## Convert beat chart to JSON string
func to_json() -> String:
	var data: Dictionary = {
		"beat_events": beat_events,
		"tempo_map": tempo_map,
		"metadata": metadata
	}
	return JSON.stringify(data, "\t")


## Load beat chart from JSON string
static func from_json(json_string: String) -> BeatChart:
	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_string)
	
	if parse_result != OK:
		push_error("BeatChart: Failed to parse JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	
	var data: Variant = json.data
	if not data is Dictionary:
		push_error("BeatChart: JSON root must be a dictionary")
		return null
	
	var beat_chart: BeatChart = BeatChart.new()
	
	# Load beat events
	if data.has("beat_events") and data["beat_events"] is Array:
		for event_data in data["beat_events"]:
			if event_data is Dictionary:
				beat_chart.beat_events.append(event_data)
	
	# Load tempo map
	if data.has("tempo_map") and data["tempo_map"] is Array:
		for tempo_data in data["tempo_map"]:
			if tempo_data is Dictionary:
				beat_chart.tempo_map.append(tempo_data)
	
	# Load metadata
	if data.has("metadata") and data["metadata"] is Dictionary:
		beat_chart.metadata = data["metadata"]
	
	return beat_chart


## Load beat chart from JSON file
static func load_from_file(file_path: String) -> BeatChart:
	if not FileAccess.file_exists(file_path):
		push_error("BeatChart: File not found: %s" % file_path)
		return null
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("BeatChart: Failed to open file: %s (Error: %d)" % [file_path, FileAccess.get_open_error()])
		return null
	
	var json_string: String = file.get_as_text()
	file.close()
	
	return from_json(json_string)


## Save beat chart to JSON file
func save_to_file(file_path: String) -> bool:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("BeatChart: Failed to create file: %s (Error: %d)" % [file_path, FileAccess.get_open_error()])
		return false
	
	file.store_string(to_json())
	file.close()
	return true
