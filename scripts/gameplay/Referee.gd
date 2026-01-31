extends Node

## Central coordinator for rhythm game state.
## Tracks score, combo, and gameplay statistics.

signal score_changed(score: int)
signal combo_changed(combo: int)
signal statistics_updated(stats: Dictionary)

const PERFECT_SCORE: int = 100
const GREAT_SCORE: int = 75
const GOOD_SCORE: int = 50
const MISS_SCORE: int = 0

var _score: int = 0
var _combo: int = 0
var _max_combo: int = 0
var _perfect_count: int = 0
var _great_count: int = 0
var _good_count: int = 0
var _miss_count: int = 0

func _ready() -> void:
	reset()

func _on_judgment_made(beat: BeatEvent, offset_ms: float, rating: HitRating.Rating) -> void:
	match rating:
		HitRating.Rating.PERFECT:
			_perfect_count += 1
			_score += PERFECT_SCORE
			_combo += 1
		HitRating.Rating.GREAT:
			_great_count += 1
			_score += GREAT_SCORE
			_combo += 1
		HitRating.Rating.GOOD:
			_good_count += 1
			_score += GOOD_SCORE
			_combo += 1
		HitRating.Rating.MISS:
			_miss_count += 1
			_combo = 0
	
	if _combo > _max_combo:
		_max_combo = _combo
	
	score_changed.emit(_score)
	combo_changed.emit(_combo)
	
	var stats: Dictionary = {
		"score": _score,
		"combo": _combo,
		"max_combo": _max_combo,
		"perfect": _perfect_count,
		"great": _great_count,
		"good": _good_count,
		"miss": _miss_count
	}
	statistics_updated.emit(stats)

func get_score() -> int:
	return _score

func get_combo() -> int:
	return _combo

func get_max_combo() -> int:
	return _max_combo

func get_statistics() -> Dictionary:
	return {
		"score": _score,
		"combo": _combo,
		"max_combo": _max_combo,
		"perfect": _perfect_count,
		"great": _great_count,
		"good": _good_count,
		"miss": _miss_count
	}

func reset() -> void:
	_score = 0
	_combo = 0
	_max_combo = 0
	_perfect_count = 0
	_great_count = 0
	_good_count = 0
	_miss_count = 0
	
	score_changed.emit(_score)
	combo_changed.emit(_combo)
