extends Control

## Left UI panel displaying score, combo, and Resonance system
## Connects to Referee and UIStateManager signals for real-time updates

@onready var score_value: Label = %ScoreValue
@onready var combo_value: Label = %ComboValue
@onready var resonance_bar: ProgressBar = %ResonanceBar
@onready var resonance_stats: Label = %ResonanceStats
@onready var resonance_accuracy: Label = %ResonanceAccuracy

var current_score: int = 0
var current_combo: int = 0

@export var low_resonance_threshold: float = 33.0
@export var medium_resonance_threshold: float = 66.0


func _ready() -> void:
	_update_displays()


func set_score(score: int) -> void:
	"""Update score display"""
	current_score = score
	score_value.text = str(score)
	_animate_label(score_value)


func set_combo(combo: int) -> void:
	"""Update combo display"""
	current_combo = combo
	combo_value.text = str(combo) + "x"
	_animate_label(combo_value)


func update_resonance(percentage: float, hits: int, total: int, accuracy: float) -> void:
	"""Update resonance display with all statistics"""
	if resonance_bar:
		resonance_bar.value = clampf(percentage, 0.0, 100.0)
		_update_resonance_color(percentage)
	
	if resonance_stats:
		resonance_stats.text = "%d / %d" % [hits, total]
	
	if resonance_accuracy:
		resonance_accuracy.text = "%.0f%%" % accuracy


func _update_displays() -> void:
	"""Initialize all displays"""
	score_value.text = str(current_score)
	combo_value.text = str(current_combo) + "x"
	if resonance_bar:
		resonance_bar.value = 100.0
	if resonance_stats:
		resonance_stats.text = "0 / 0"
	if resonance_accuracy:
		resonance_accuracy.text = "100%"


func _update_resonance_color(percentage: float) -> void:
	"""Update resonance bar color based on percentage"""
	if not resonance_bar:
		return
	
	var bar_color: Color = Color.WHITE
	
	if percentage < low_resonance_threshold:
		bar_color = Color(1.0, 0.2, 0.2)  # Red
	elif percentage < medium_resonance_threshold:
		bar_color = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		bar_color = Color(0.2, 1.0, 0.2)  # Green
	
	resonance_bar.modulate = bar_color


func _animate_label(label: Label) -> void:
	"""Pulse animation for value updates"""
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)


func reset() -> void:
	"""Reset all values to default"""
	current_score = 0
	current_combo = 0
	_update_displays()
