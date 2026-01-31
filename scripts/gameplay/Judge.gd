extends Node

## Judges player input timing against beat events.
## Applies latency compensation and assigns hit ratings.

signal judgment_made(beat: BeatEvent, offset_ms: float, rating: HitRating.Rating)

@export var latency_offset_ms: float = 0.0

var _note_scheduler: Node = null

func _ready() -> void:
	_note_scheduler = get_parent().get_node_or_null("NoteScheduler")
	if _note_scheduler == null:
		push_error("Judge: Could not find NoteScheduler node")

func judge_input(input_time_ms: float, target_beat: BeatEvent) -> void:
	if target_beat == null:
		return
	
	# Validate time domain consistency - catch absolute timestamps masquerading as relative
	assert(target_beat.hit_time_ms < 1000000.0, "Judge: Beat timestamp appears to be absolute system time, not song-relative")
	assert(input_time_ms < 1000000.0, "Judge: Input timestamp appears to be absolute system time, not song-relative")
	
	var adjusted_input_time: float = input_time_ms + latency_offset_ms
	var offset_ms: float = adjusted_input_time - target_beat.hit_time_ms
	var rating: HitRating.Rating = HitRating.get_rating_from_offset(offset_ms)
	
	if rating != HitRating.Rating.MISS:
		target_beat.was_hit = true
		if _note_scheduler != null:
			_note_scheduler.mark_beat_hit(target_beat)
	
	judgment_made.emit(target_beat, offset_ms, rating)

func set_latency_offset(offset_ms: float) -> void:
	latency_offset_ms = offset_ms

func get_latency_offset() -> float:
	return latency_offset_ms
