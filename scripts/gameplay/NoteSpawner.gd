extends Node

## Spawns visual notes based on MIDI events from the NoteScheduler.
## Maps MIDI note values (60-71) to spawn points and targets, instantiates Note scenes.

signal note_spawned(note: Note)

@export var note_scene: PackedScene
@export var spawn_points_container: Node2D
@export var note_targets: Node
@export var active_notes_container: Node2D
@export var note_scheduler: Node
@export var music_player: Node

## How far ahead to spawn notes before they should arrive (in ms)
@export var spawn_lookahead_ms: float = 2000.0

## MIDI note names for reference (C4 = middle C)
const MIDI_NOTE_NAMES: Dictionary = {
	60: "C4",
	61: "CSharp4",
	62: "D4",
	63: "DSharp4",
	64: "E4",
	65: "F4",
	66: "FSharp4",
	67: "G4",
	68: "GSharp4",
	69: "A4",
	70: "ASharp4",
	71: "B4"
}

## Spawn positions for each MIDI note (1920x1080 base resolution)
const SPAWN_POSITIONS: Dictionary = {
	60: Vector2(347, 473),   # C4 - lower left
	61: Vector2(337, 383),   # C#4 - middle left
	62: Vector2(347, 287),   # D4 - upper left
	63: Vector2(597, 33),    # D#4 - top center-left
	64: Vector2(689, 13),    # E4 - top center
	65: Vector2(783, 33),    # F4 - top center-right
	66: Vector2(1033, 287),  # F#4 - upper right
	67: Vector2(1043, 411),  # G4 - middle right
	68: Vector2(1033, 497),  # G#4 - lower right
	69: Vector2(783, 723),   # A4 - bottom center-right
	70: Vector2(689, 677),   # A#4 - bottom center
	71: Vector2(597, 723)    # B4 - bottom center-left
}

## Maps MIDI notes to target directions and positions
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

var _active_notes: Array[Note] = []
var _beat_to_note_map: Dictionary = {}  ## Maps BeatEvent to Note for hit detection
var _failed_notes: Array[Note] = []  ## Notes that were hit too early and can't be hit again

func _ready() -> void:
	pass  # Signal connection handled by gameplay_base

func _on_upcoming_beat(beat: BeatEvent) -> void:
	# Only spawn visual notes for beats with MIDI note data
	if beat.midi_note < 0:
		return
	
	# Validate MIDI note is in expected range
	if beat.midi_note < 60 or beat.midi_note > 71:
		push_warning("NoteSpawner: MIDI note %d out of range (60-71)" % beat.midi_note)
		return
	
	spawn_note(beat)

func spawn_note(beat: BeatEvent) -> void:
	if note_scene == null:
		push_error("NoteSpawner: note_scene not assigned")
		return
	
	if active_notes_container == null:
		push_error("NoteSpawner: active_notes_container not assigned")
		return
	
	# Get spawn position from scene SpawnPoints node
	var spawn_pos: Vector2 = Vector2(960, 540)  # Default fallback
	var note_name: String = MIDI_NOTE_NAMES.get(beat.midi_note, "")
	if not note_name.is_empty() and spawn_points_container:
		var spawn_point: Node2D = spawn_points_container.get_node_or_null(note_name)
		if spawn_point:
			spawn_pos = spawn_point.global_position
		else:
			push_warning("NoteSpawner: Spawn point '%s' not found, using fallback" % note_name)
	
	# Get target direction for this MIDI note
	var target_direction: String = TARGET_MAPPING.get(beat.midi_note, "down")
	
	# Get target position from note_targets node
	var target_pos: Vector2 = Vector2(960, 540)  # Default to center
	if note_targets and note_targets.has_method("get_target_position"):
		target_pos = note_targets.get_target_position(target_direction)
	
	# Calculate spawn time based on lookahead
	var current_time_ms: float = 0.0
	if music_player and music_player.has_method("get_current_time_ms"):
		current_time_ms = music_player.get_current_time_ms()
	
	var spawn_time_ms: float = current_time_ms
	var arrival_time_ms: float = beat.hit_time_ms
	
	# Instantiate note
	var note: Note = note_scene.instantiate()
	active_notes_container.add_child(note)
	
	# Initialize note with movement parameters
	note.initialize(
		spawn_pos,
		target_pos,
		arrival_time_ms,
		spawn_time_ms,
		beat.midi_note,
		beat.beat_number,
		target_direction
	)
	
	# Connect note signals
	note.entered_50_percent_zone.connect(_on_note_entered_50_percent_zone)
	note.entered_75_percent_zone.connect(_on_note_entered_75_percent_zone)
	note.approaching_target.connect(_on_note_approaching_target)
	note.arrived_at_target.connect(_on_note_arrived_at_target)
	
	_active_notes.append(note)
	_beat_to_note_map[beat] = note  # Map beat to note for hit detection
	note_spawned.emit(note)
	
	print("NoteSpawner: Spawned note %d (%s) at (%.0f, %.0f) -> (%.0f, %.0f), arrival in %.0fms" % [
		beat.midi_note,
		MIDI_NOTE_NAMES.get(beat.midi_note, "Unknown"),
		spawn_pos.x, spawn_pos.y,
		target_pos.x, target_pos.y,
		arrival_time_ms - spawn_time_ms
	])

func _on_note_entered_50_percent_zone(note: Note) -> void:
	# Note entered 50% proximity zone
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "50%", true)


func _on_note_entered_75_percent_zone(note: Note) -> void:
	# Note entered 75% proximity zone (closer to target)
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "75%", true)


func _on_note_approaching_target(note: Note) -> void:
	# Note is getting close - highlight target with scale pulse
	if note_targets and note_targets.has_method("highlight_target"):
		note_targets.highlight_target(note.movement_direction)


func _on_note_arrived_at_target(note: Note) -> void:
	# Note has reached its target position
	# Clear both proximity zones for this note
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "75%", false)
		note_targets.set_proximity_zone(note.movement_direction, "50%", false)
	
	# The Judge should handle timing judgment
	# For now, just mark as arrived (miss handling will be added later)
	print("NoteSpawner: Note %d arrived at target" % note.midi_note)
	
	# Remove from tracking after a brief delay to allow for late hits
	await get_tree().create_timer(0.5).timeout
	
	if note and is_instance_valid(note):
		_active_notes.erase(note)
		# Remove from beat map
		for beat in _beat_to_note_map.keys():
			if _beat_to_note_map[beat] == note:
				_beat_to_note_map.erase(beat)
				break
		note.destroy()


func on_note_hit(beat: BeatEvent, rating: int) -> void:
	"""Called when a note is successfully hit by the player"""
	var note: Note = _beat_to_note_map.get(beat, null)
	if note == null or not is_instance_valid(note):
		return
	
	# Check if note was already marked as failed
	if note in _failed_notes:
		return
	
	# Clear proximity zones immediately
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "75%", false)
		note_targets.set_proximity_zone(note.movement_direction, "50%", false)
	
	# Trigger hit effect on note
	note.on_hit(rating)
	
	# Remove from tracking
	_active_notes.erase(note)
	_beat_to_note_map.erase(beat)


func on_note_missed(beat: BeatEvent) -> void:
	"""Called when a note is missed (reached target without being hit)"""
	var note: Note = _beat_to_note_map.get(beat, null)
	if note == null or not is_instance_valid(note):
		return
	
	# Clear proximity zones
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "75%", false)
		note_targets.set_proximity_zone(note.movement_direction, "50%", false)
	
	# Trigger miss effect on note
	note.on_missed()
	
	# Remove from tracking
	_active_notes.erase(note)
	_beat_to_note_map.erase(beat)


func on_early_input(beat: BeatEvent) -> void:
	"""Called when player inputs too early for a note"""
	var note: Note = _beat_to_note_map.get(beat, null)
	if note == null or not is_instance_valid(note):
		return
	
	# Mark as failed so it can't be hit again
	_failed_notes.append(note)
	
	# Clear proximity zones
	if note_targets and note_targets.has_method("set_proximity_zone"):
		note_targets.set_proximity_zone(note.movement_direction, "75%", false)
		note_targets.set_proximity_zone(note.movement_direction, "50%", false)
	
	# Trigger early hit effect
	note.on_early_hit()
	
	# Remove from tracking
	_active_notes.erase(note)
	_failed_notes.erase(note)  # Will be destroyed, remove from failed list
	_beat_to_note_map.erase(beat)

func clear_all_notes() -> void:
	for note in _active_notes:
		if is_instance_valid(note):
			note.destroy()
	_active_notes.clear()
	_beat_to_note_map.clear()
	_failed_notes.clear()
