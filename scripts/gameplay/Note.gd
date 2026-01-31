class_name Note
extends Sprite2D

## Visual note that spawns and travels toward a target position.
## Moves linearly from spawn point to target, arriving exactly at the specified time.

signal arrived_at_target(note: Note)
signal entering_judgment_window(note: Note)

var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var arrival_time_ms: float = 0.0
var spawn_time_ms: float = 0.0
var movement_direction: String = ""  ## "up", "down", "left", "right"
var midi_note: int = -1
var beat_number: int = 0

var _is_traveling: bool = false
var _travel_duration_ms: float = 0.0
var _has_entered_judgment_window: bool = false
var _judgment_window_threshold: float = 0.3  ## Trigger at 30% of travel remaining

func initialize(p_spawn_pos: Vector2, p_target_pos: Vector2, p_arrival_time_ms: float, p_spawn_time_ms: float, p_midi_note: int, p_beat_number: int, p_direction: String) -> void:
	spawn_position = p_spawn_pos
	target_position = p_target_pos
	arrival_time_ms = p_arrival_time_ms
	spawn_time_ms = p_spawn_time_ms
	midi_note = p_midi_note
	beat_number = p_beat_number
	movement_direction = p_direction
	
	_travel_duration_ms = arrival_time_ms - spawn_time_ms
	
	position = spawn_position
	_is_traveling = true

func _process(_delta: float) -> void:
	if not _is_traveling:
		return
	
	# Get current song time from the first MusicPlayer in the tree
	var music_player: Node = get_tree().get_first_node_in_group("music_player")
	if music_player == null:
		return
	
	var current_time_ms: float = music_player.get_current_time_ms()
	
	# Calculate progress (0.0 to 1.0+)
	var elapsed_ms: float = current_time_ms - spawn_time_ms
	var progress: float = elapsed_ms / _travel_duration_ms if _travel_duration_ms > 0.0 else 1.0
	
	# Trigger judgment window entering at threshold
	if not _has_entered_judgment_window and progress >= (1.0 - _judgment_window_threshold):
		_has_entered_judgment_window = true
		entering_judgment_window.emit(self)
	
	if progress >= 1.0:
		# Reached or passed target
		position = target_position
		_is_traveling = false
		arrived_at_target.emit(self)
		return
	
	# Linear interpolation from spawn to target
	position = spawn_position.lerp(target_position, progress)

func destroy() -> void:
	queue_free()
