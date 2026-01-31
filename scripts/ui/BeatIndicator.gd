extends Control

## Visual indicator showing a moving bar that reaches a target on the beat.
## Provides visual feedback for rhythm timing.

signal beat_visual_complete

@export var travel_duration_ms: float = 1000.0
@export var target_position: Vector2 = Vector2(400, 300)
@export var bar_color: Color = Color.WHITE
@export var target_color: Color = Color.GOLD

var _bar_start_position: Vector2 = Vector2.ZERO
var _bar_current_position: Vector2 = Vector2.ZERO
var _target_hit_time_ms: float = 0.0
var _animation_start_time_ms: float = 0.0
var _is_animating: bool = false

func _ready() -> void:
	_bar_start_position = Vector2(size.x * 0.1, size.y * 0.5)
	target_position = Vector2(size.x * 0.5, size.y * 0.5)
	_bar_current_position = _bar_start_position
	queue_redraw()

func start_beat_animation(hit_time_ms: float, current_time_ms: float) -> void:
	_target_hit_time_ms = hit_time_ms
	_animation_start_time_ms = current_time_ms
	_is_animating = true
	_bar_current_position = _bar_start_position

func update_animation(current_time_ms: float) -> void:
	if not _is_animating:
		return
	
	var elapsed_ms: float = current_time_ms - _animation_start_time_ms
	var time_until_hit: float = _target_hit_time_ms - current_time_ms
	
	if time_until_hit <= 0:
		_bar_current_position = target_position
		_is_animating = false
		beat_visual_complete.emit()
	else:
		var total_travel_time: float = _target_hit_time_ms - _animation_start_time_ms
		var progress: float = elapsed_ms / total_travel_time
		progress = clampf(progress, 0.0, 1.0)
		
		_bar_current_position = _bar_start_position.lerp(target_position, progress)
	
	queue_redraw()

func _draw() -> void:
	const TARGET_RADIUS: float = 20.0
	const BAR_WIDTH: float = 10.0
	const BAR_HEIGHT: float = 40.0
	
	draw_circle(target_position, TARGET_RADIUS, target_color)
	draw_circle(target_position, TARGET_RADIUS - 3.0, Color.BLACK)
	
	var bar_rect: Rect2 = Rect2(
		_bar_current_position.x - BAR_WIDTH * 0.5,
		_bar_current_position.y - BAR_HEIGHT * 0.5,
		BAR_WIDTH,
		BAR_HEIGHT
	)
	draw_rect(bar_rect, bar_color)

func reset() -> void:
	_is_animating = false
	_bar_current_position = _bar_start_position
	queue_redraw()
