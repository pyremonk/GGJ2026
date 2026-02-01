class_name LevelConfig
extends Resource

## Configuration for a gameplay level including UI metadata and game parameters.
## This resource defines all metadata needed to set up and display a level properly.

## Display name of the level
@export var level_name: String = ""

## Name of the music track (displayed in Now Playing UI)
@export var track_name: String = ""

## Artist or creator of the track (displayed in Now Playing UI)
@export var artist_name: String = ""

## MIDI resource for this level (imported .mid file)
## Drag the .mid file from FileSystem into this field in the Inspector
@export var midi_resource: Resource = null

## Path to the audio file for this level (relative to res://)
@export_file("*.ogg", "*.mp3", "*.wav") var audio_file_path: String = ""

## Path to the next level scene (empty string if this is the final level)
@export_file("*.tscn") var next_level_path: String = ""

## Percentage of total notes that can be missed before level failure (0.0 - 1.0)
## Default: 0.25 (25% of notes missed = failure)
@export_range(0.0, 1.0, 0.01) var miss_threshold_percentage: float = 0.25

## Grace period: minimum notes that must be played before resonance depletion can occur
## Prevents instant failure from missing the first few notes
## Default: 8 notes
@export_range(0, 50, 1) var grace_period_notes: int = 8

## Timing Configuration
## Default BPM for this level (used as fallback if MIDI tempo map is unavailable)
@export_range(30.0, 300.0, 1.0) var default_bpm: float = 90.0

## Audio delay in milliseconds (compensates for system latency)
@export_range(0.0, 5000.0, 1.0) var audio_delay_ms: float = 2667.0

## Lookahead window for scheduling beats in milliseconds
@export_range(0.0, 5000.0, 1.0) var lookahead_ms: float = 2667.0

## Spawn lookahead for visual note spawning in milliseconds
@export_range(0.0, 5000.0, 1.0) var spawn_lookahead_ms: float = 2667.0

## Mask unlock conditions (to be defined in separate spec)
## Each dictionary should contain condition data for unlocking masks
@export var mask_unlock_conditions: Array[Dictionary] = []


## Validates that required fields are populated
func is_valid() -> bool:
	if level_name.is_empty():
		push_warning("LevelConfig: level_name is empty")
		return false
	if track_name.is_empty():
		push_warning("LevelConfig: track_name is empty")
		return false
	if midi_resource == null:
		push_warning("LevelConfig: midi_resource is null")
		return false
	if audio_file_path.is_empty():
		push_warning("LevelConfig: audio_file_path is empty")
		return false
	return true


## Returns a formatted string representation for debugging
func get_debug_string() -> String:
	return "LevelConfig[%s] - Track: '%s' by %s" % [level_name, track_name, artist_name]
