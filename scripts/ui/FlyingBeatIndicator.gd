extends Control

## Self-contained flying beat indicator that animates and destroys itself.
## Spawned for each beat, travels to target, then auto-destructs.

signal beat_visual_complete

@export var travel_duration_ms: float = 1000.0
@export var target_position: Vector2 = Vector2(400, 300)
@export var bar_color: Color = Color.WHITE
@export var target_color: Color = Color.GOLD

var _bar_start_position: Vector2 = Vector2.ZERO
var _bar_current_position: Vector2 = Vector2.ZERO
var _target_hit_time_ms: float = 0.0
var _animation_start_time_ms: float = 0.0
var _music_player: Node = null

func _ready() -> void:
	# Position relative to parent
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	_bar_start_position = Vector2(size.x * 0.1, size.y * 0.5)
	_bar_current_position = _bar_start_position
	queue_redraw()

func initialize(hit_time_ms: float, current_time_ms: float, music_player: Node) -> void:
	_target_hit_time_ms = hit_time_ms
	_animation_start_time_ms = current_time_ms
	_music_player = music_player

func _process(delta: float) -> void:
	if _music_player == null:
		queue_free()
		return
	
	var current_time_ms: float = _music_player.get_current_time_ms()
	var elapsed_ms: float = current_time_ms - _animation_start_time_ms
	var time_until_hit: float = _target_hit_time_ms - current_time_ms
	
	if time_until_hit <= 0:
		_bar_current_position = target_position
		beat_visual_complete.emit()
		queue_free()
		return
	
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
