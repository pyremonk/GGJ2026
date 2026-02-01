extends Node2D

## Note targets positioned around the player in cardinal directions
## Visual indicators for where beats should be hit

@onready var target_up: Sprite2D = $TargetUp
@onready var target_down: Sprite2D = $TargetDown
@onready var target_left: Sprite2D = $TargetLeft
@onready var target_right: Sprite2D = $TargetRight

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


func _ready() -> void:
	pass


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
		var tween: Tween = create_tween()
		tween.tween_property(target, "modulate", desired_color, 0.1)


func highlight_target(direction: String) -> void:
	"""Highlight a specific target (for visual feedback on hits)"""
	var target: Sprite2D = _get_target_by_direction(direction)
	
	if target:
		# Add visual feedback (scale pulse, color change, etc.)
		var tween: Tween = create_tween()
		tween.tween_property(target, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.1)


func get_target_position(direction: String) -> Vector2:
	"""Get global position of a target by direction"""
	var target: Sprite2D = _get_target_by_direction(direction)
	if target:
		return target.global_position
	return global_position


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
