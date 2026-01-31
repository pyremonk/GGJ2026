extends Label

## Displays timing feedback after player input.
## Shows rating and millisecond offset with fade-out animation.

const DISPLAY_DURATION_SEC: float = 1.5
const FADE_START_SEC: float = 0.5

var _display_timer: float = 0.0
var _is_displaying: bool = false

func _ready() -> void:
	modulate = Color.TRANSPARENT
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func show_feedback(offset_ms: float, rating: HitRating.Rating) -> void:
	var rating_name: String = HitRating.get_rating_name(rating)
	var rating_color: Color = HitRating.get_rating_color(rating)
	
	var offset_sign: String = "+" if offset_ms >= 0 else ""
	var feedback_text: String = "%s %s%.0fms" % [rating_name, offset_sign, offset_ms]
	
	text = feedback_text
	modulate = rating_color
	_display_timer = DISPLAY_DURATION_SEC
	_is_displaying = true

func _process(delta: float) -> void:
	if not _is_displaying:
		return
	
	_display_timer -= delta
	
	if _display_timer <= 0.0:
		_is_displaying = false
		modulate = Color.TRANSPARENT
		text = ""
		return
	
	if _display_timer <= FADE_START_SEC:
		var alpha: float = _display_timer / FADE_START_SEC
		modulate.a = alpha
	else:
		modulate.a = 1.0

func hide_feedback() -> void:
	_is_displaying = false
	modulate = Color.TRANSPARENT
	text = ""
