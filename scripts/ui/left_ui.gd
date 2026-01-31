extends Control

## Left UI panel displaying Score, Combo, and Resonance information.
## Positioned at x=0 to x=420 of the screen.

## References to UI elements (set via unique names in scene)
@onready var score_value_label: Label = %ScoreValue
@onready var combo_value_label: Label = %ComboValue
@onready var resonance_bar: ProgressBar = %ResonanceBar
@onready var resonance_stats_label: Label = %ResonanceStats
@onready var resonance_accuracy_label: Label = %ResonanceAccuracy

## Optional theme/style overrides
@export var low_resonance_threshold: float = 33.0  ## Red warning below this percentage
@export var medium_resonance_threshold: float = 66.0  ## Yellow warning below this percentage


func _ready() -> void:
	_initialize_display()


## Initialize all display elements with default values
func _initialize_display() -> void:
	if score_value_label:
		score_value_label.text = "0"
	
	if combo_value_label:
		combo_value_label.text = "0"
	
	if resonance_bar:
		resonance_bar.min_value = 0.0
		resonance_bar.max_value = 100.0
		resonance_bar.value = 100.0
	
	if resonance_stats_label:
		resonance_stats_label.text = "0 / 0"
	
	if resonance_accuracy_label:
		resonance_accuracy_label.text = "100%"


## Update score display
func update_score(score: int) -> void:
	if score_value_label:
		score_value_label.text = str(score)


## Update combo display
func update_combo(combo: int) -> void:
	if combo_value_label:
		combo_value_label.text = str(combo)


## Update resonance display with all statistics
func update_resonance(percentage: float, hits: int, total: int, accuracy: float) -> void:
	if resonance_bar:
		resonance_bar.value = clampf(percentage, 0.0, 100.0)
		_update_resonance_color(percentage)
	
	if resonance_stats_label:
		resonance_stats_label.text = "%d / %d" % [hits, total]
	
	if resonance_accuracy_label:
		resonance_accuracy_label.text = "%.0f%%" % accuracy


## Update resonance bar color based on percentage (optional visual feedback)
func _update_resonance_color(percentage: float) -> void:
	if not resonance_bar:
		return
	
	# Color coding: Green → Yellow → Red as health depletes
	var bar_color: Color = Color.WHITE
	
	if percentage < low_resonance_threshold:
		bar_color = Color(1.0, 0.2, 0.2)  # Red
	elif percentage < medium_resonance_threshold:
		bar_color = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		bar_color = Color(0.2, 1.0, 0.2)  # Green
	
	# Apply color tint to progress bar
	resonance_bar.modulate = bar_color


## Reset all displays to initial state
func reset_display() -> void:
	_initialize_display()
