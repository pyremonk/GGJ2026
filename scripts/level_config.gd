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

## Path to the MIDI file for this level (relative to res://)
@export_file("*.mid") var midi_file_path: String = ""

## Path to the audio file for this level (relative to res://)
@export_file("*.ogg", "*.mp3", "*.wav") var audio_file_path: String = ""

## Path to the next level scene (empty string if this is the final level)
@export_file("*.tscn") var next_level_path: String = ""

## Percentage of total notes that can be missed before level failure (0.0 - 1.0)
## Default: 0.25 (25% of notes missed = failure)
@export_range(0.0, 1.0, 0.01) var miss_threshold_percentage: float = 0.25

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
	if midi_file_path.is_empty():
		push_warning("LevelConfig: midi_file_path is empty")
		return false
	if audio_file_path.is_empty():
		push_warning("LevelConfig: audio_file_path is empty")
		return false
	return true


## Returns a formatted string representation for debugging
func to_string() -> String:
	return "LevelConfig[%s] - Track: '%s' by %s" % [level_name, track_name, artist_name]
