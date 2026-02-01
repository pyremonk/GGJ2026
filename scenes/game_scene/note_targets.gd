extends Node2D

## Note targets positioned around the player in cardinal directions
## Visual indicators for where beats should be hit

@onready var target_up: Sprite2D = $TargetUp
@onready var target_down: Sprite2D = $TargetDown
@onready var target_left: Sprite2D = $TargetLeft
@onready var target_right: Sprite2D = $TargetRight

const TARGET_DISTANCE: float = 120.0
const APPROACHING_COLOR: Color = Color(1.0, 0.3, 0.3)  ## Red tint
const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0)  ## White

var _approaching_count: Dictionary = {
	"up": 0,
	"down": 0,
	"left": 0,
	"right": 0
}  ## Track number of notes in judgment window per direction


func _ready() -> void:
	pass


func set_approaching_state(direction: String, is_approaching: bool) -> void:
	"""Set target to approaching state (red tint) when note enters judgment window"""
	var target: Sprite2D = _get_target_by_direction(direction)
	if target == null:
		return
	
	# Update counter
	if is_approaching:
		_approaching_count[direction] += 1
	else:
		_approaching_count[direction] = max(0, _approaching_count[direction] - 1)
	
	# Only change color based on whether any notes are approaching
	var should_be_red: bool = _approaching_count[direction] > 0
	
	if should_be_red and target.modulate != APPROACHING_COLOR:
		# Tween to red color
		var tween: Tween = create_tween()
		tween.tween_property(target, "modulate", APPROACHING_COLOR, 0.1)
	elif not should_be_red and target.modulate != NORMAL_COLOR:
		# Tween back to normal
		var tween: Tween = create_tween()
		tween.tween_property(target, "modulate", NORMAL_COLOR, 0.2)


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
