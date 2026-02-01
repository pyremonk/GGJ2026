extends Node2D

## Note targets positioned around the player in cardinal directions
## Visual indicators for where beats should be hit

@onready var target_up: Sprite2D = $TargetUp
@onready var target_down: Sprite2D = $TargetDown
@onready var target_left: Sprite2D = $TargetLeft
@onready var target_right: Sprite2D = $TargetRight

@onready var feedback_label_up: Label = %FeedbackLabelUp
@onready var feedback_label_down: Label = %FeedbackLabelDown
@onready var feedback_label_left: Label = %FeedbackLabelLeft
@onready var feedback_label_right: Label = %FeedbackLabelRight

const TARGET_DISTANCE: float = 120.0
const RED_COLOR: Color = Color(1.0, 0.3, 0.3)  ## Red - notes within 75%
const ORANGE_COLOR: Color = Color(1.0, 0.6, 0.2)  ## Orange - notes within 50%
const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0)  ## White - no nearby notes

var _notes_at_75_percent: Dictionary = {
	"up": 0,
	"down": 0,
	"left": 0,
	"right": 0
}  ## Track number of notes within 75% progress per direction

var _notes_at_50_percent: Dictionary = {
	"up": 0,
	"down": 0,
	"left": 0,
	"right": 0
}  ## Track number of notes within 50% progress per direction

var _color_tweens: Dictionary = {}  ## Active color tweens per direction
var _scale_tweens: Dictionary = {}  ## Active scale tweens per direction
var _label_tweens: Dictionary = {}  ## Active label tweens per direction


func _ready() -> void:
	# Hide all feedback labels initially
	feedback_label_up.visible = false
	feedback_label_down.visible = false
	feedback_label_left.visible = false
	feedback_label_right.visible = false


func set_proximity_zone(direction: String, zone: String, entering: bool) -> void:
	"""Update proximity zone tracking for a direction (zone: '50%' or '75%')"""
	var target: Sprite2D = _get_target_by_direction(direction)
	if target == null:
		return
	
	# Update counters
	if zone == "75%":
		if entering:
			_notes_at_75_percent[direction] += 1
		else:
			_notes_at_75_percent[direction] = max(0, _notes_at_75_percent[direction] - 1)
	elif zone == "50%":
		if entering:
			_notes_at_50_percent[direction] += 1
		else:
			_notes_at_50_percent[direction] = max(0, _notes_at_50_percent[direction] - 1)
	
	_update_target_color(direction)


func _update_target_color(direction: String) -> void:
	"""Update target color based on proximity priority: red > orange > white"""
	var target: Sprite2D = _get_target_by_direction(direction)
	if target == null:
		return
	
	var desired_color: Color = NORMAL_COLOR
	
	# Priority: red (75%) > orange (50%) > white (default)
	if _notes_at_75_percent[direction] > 0:
		desired_color = RED_COLOR
	elif _notes_at_50_percent[direction] > 0:
		desired_color = ORANGE_COLOR
	
	# Only tween if color actually changed
	if target.modulate != desired_color:
		# Kill existing color tween for this direction
		if _color_tweens.has(direction) and _color_tweens[direction] != null:
			if _color_tweens[direction].is_valid():
				_color_tweens[direction].kill()
		
		var tween: Tween = create_tween()
		_color_tweens[direction] = tween
		tween.tween_property(target, "modulate", desired_color, 0.1)


func highlight_target(direction: String) -> void:
	"""Highlight a specific target (for visual feedback on hits)"""
	var target: Sprite2D = _get_target_by_direction(direction)
	
	if target:
		# Add visual feedback (scale pulse, color change, etc.)
		var tween: Tween = create_tween()
		tween.tween_property(target, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.1)


func pulse_target(direction: String) -> void:
	"""Pulse a specific target when player presses input (slightly subtler than highlight)"""
	var target: Sprite2D = _get_target_by_direction(direction)
	
	if target:
		# Kill existing scale tween for this direction
		if _scale_tweens.has(direction) and _scale_tweens[direction] != null:
			if _scale_tweens[direction].is_valid():
				_scale_tweens[direction].kill()
		
		# Quick scale pulse on input press
		var tween: Tween = create_tween()
		_scale_tweens[direction] = tween
		tween.set_parallel(false)
		tween.tween_property(target, "scale", Vector2(1.6, 1.6), 0.16)
		tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.24)


func get_target_position(direction: String) -> Vector2:
	"""Get global position of a target by direction"""
	var target: Sprite2D = _get_target_by_direction(direction)
	if target:
		return target.global_position
	return global_position


func show_target_feedback(direction: String, feedback_text: String, feedback_color: Color = Color.WHITE) -> void:
	"""Display feedback text at the specified note target"""
	var label: Label = _get_label_by_direction(direction)
	if label == null:
		return
	
	# Kill existing tween for this label
	if _label_tweens.has(direction) and _label_tweens[direction] != null:
		if _label_tweens[direction].is_valid():
			_label_tweens[direction].kill()
	
	# Set label properties
	label.text = feedback_text
	label.modulate = feedback_color
	label.modulate.a = 1.0
	label.scale = Vector2(1.0, 1.0)
	label.visible = true
	
	# Animate: scale up slightly, then fade out
	var tween: Tween = create_tween()
	_label_tweens[direction] = tween
	tween.set_parallel(false)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: label.visible = false)


func _get_target_by_direction(direction: String) -> Sprite2D:
	"""Internal helper to get target sprite by direction string"""
	match direction:
		"up":
			return target_up
		"down":
			return target_down
		"left":
			return target_left
		"right":
			return target_right
	return null


func _get_label_by_direction(direction: String) -> Label:
	"""Internal helper to get feedback label by direction string"""
	match direction:
		"up":
			return feedback_label_up
		"down":
			return feedback_label_down
		"left":
			return feedback_label_left
		"right":
			return feedback_label_right
	return null
