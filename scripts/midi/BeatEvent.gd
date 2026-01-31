class_name BeatEvent
extends Resource

## Data transfer object representing a single beat event in the rhythm game.
## Used to track when beats should occur and whether they've been hit.

var hit_time_ms: float = 0.0
var beat_number: int = 0
var was_hit: bool = false

func _init(p_hit_time_ms: float = 0.0, p_beat_number: int = 0) -> void:
	hit_time_ms = p_hit_time_ms
	beat_number = p_beat_number
	was_hit = false
