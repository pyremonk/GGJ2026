extends Node

## Schedules and tracks beat events during gameplay.
## Emits signals when beats approach or are missed.

signal upcoming_beat(beat: BeatEvent)
signal beat_missed(beat: BeatEvent)

@export var lookahead_ms: float = 5000.0

var _beat_events: Array[BeatEvent] = []
var _current_beat_index: int = 0
var _upcoming_beat_index: int = 0
var _is_initialized: bool = false

func initialize(beat_events: Array[BeatEvent]) -> void:
	_beat_events = beat_events.duplicate()
	_current_beat_index = 0
	_upcoming_beat_index = 0
	_is_initialized = true

func update(current_time_ms: float) -> void:
	if not _is_initialized:
		return
	
	if _beat_events.is_empty():
		return
	
	while _upcoming_beat_index < _beat_events.size():
		var beat: BeatEvent = _beat_events[_upcoming_beat_index]
		var time_until_beat: float = beat.hit_time_ms - current_time_ms
		
		if time_until_beat <= lookahead_ms:
			upcoming_beat.emit(beat)
			_upcoming_beat_index += 1
		else:
			break
	
	while _current_beat_index < _beat_events.size():
		var beat: BeatEvent = _beat_events[_current_beat_index]
		var time_since_beat: float = current_time_ms - beat.hit_time_ms
		
		if time_since_beat > HitRating.GOOD_WINDOW_MS:
			if not beat.was_hit:
				beat_missed.emit(beat)
			_current_beat_index += 1
		else:
			break

func get_next_beat() -> BeatEvent:
	if not _is_initialized or _beat_events.is_empty():
		return null
	
	if _current_beat_index >= _beat_events.size():
		return null
	
	return _beat_events[_current_beat_index]

func mark_beat_hit(beat: BeatEvent) -> void:
	if beat != null:
		beat.was_hit = true

func reset() -> void:
	_beat_events.clear()
	_current_beat_index = 0
	_upcoming_beat_index = 0
	_is_initialized = false

func get_total_beats() -> int:
	return _beat_events.size()

func get_current_beat_index() -> int:
	return _current_beat_index
