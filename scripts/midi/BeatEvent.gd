class_name BeatEvent
extends Resource

## Data transfer object representing a single beat event in the rhythm game.
## Used to track when beats should occur and whether they've been hit.

var hit_time_ms: float = 0.0
var beat_number: int = 0
var was_hit: bool = false
var midi_note: int = -1  ## MIDI note value (60-71 for C4-B4). -1 for auto-generated beats.
var direction: String = ""  ## Direction of note target: "up", "down", "left", or "right"
var velocity: int = 0  ## MIDI velocity (0-127). Used for veilshift detection.

func _init(p_hit_time_ms: float = 0.0, p_beat_number: int = 0, p_midi_note: int = -1, p_direction: String = "", p_velocity: int = 0) -> void:
	hit_time_ms = p_hit_time_ms
	beat_number = p_beat_number
	was_hit = false
	midi_note = p_midi_note
	direction = p_direction
	velocity = p_velocity
