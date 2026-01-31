class_name HitRating
extends RefCounted

## Hit rating system for judging player input timing accuracy.
## Provides rating enums, hit window thresholds, and utility functions.

enum Rating {
	PERFECT,
	GREAT,
	GOOD,
	MISS
}

const PERFECT_WINDOW_MS: float = 50.0
const GREAT_WINDOW_MS: float = 100.0
const GOOD_WINDOW_MS: float = 150.0

static func get_rating_from_offset(offset_ms: float) -> Rating:
	var abs_offset: float = abs(offset_ms)
	if abs_offset <= PERFECT_WINDOW_MS:
		return Rating.PERFECT
	elif abs_offset <= GREAT_WINDOW_MS:
		return Rating.GREAT
	elif abs_offset <= GOOD_WINDOW_MS:
		return Rating.GOOD
	else:
		return Rating.MISS

static func get_rating_name(rating: Rating) -> String:
	match rating:
		Rating.PERFECT:
			return "PERFECT"
		Rating.GREAT:
			return "GREAT"
		Rating.GOOD:
			return "GOOD"
		Rating.MISS:
			return "MISS"
		_:
			return "UNKNOWN"

static func get_rating_color(rating: Rating) -> Color:
	match rating:
		Rating.PERFECT:
			return Color.GOLD
		Rating.GREAT:
			return Color.GREEN
		Rating.GOOD:
			return Color.YELLOW
		Rating.MISS:
			return Color.RED
		_:
			return Color.WHITE
