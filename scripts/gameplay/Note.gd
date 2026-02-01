class_name Note
extends Sprite2D

## Visual note that spawns and travels toward a target position.
## Moves linearly from spawn point to target, arriving exactly at the specified time.

signal arrived_at_target(note: Note)
signal entered_50_percent_zone(note: Note)
signal entered_75_percent_zone(note: Note)
signal approaching_target(note: Note)  ## For highlight pulse animation

var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var arrival_time_ms: float = 0.0
var spawn_time_ms: float = 0.0
var movement_direction: String = ""  ## "up", "down", "left", "right"
var midi_note: int = -1
var beat_number: int = 0

var _is_traveling: bool = false
var _travel_duration_ms: float = 0.0
var _has_entered_50_percent: bool = false
var _has_entered_75_percent: bool = false
var _has_approached_target: bool = false
var _approach_threshold: float = 0.5  ## Trigger at 50% progress for highlight pulse
var _is_destroyed: bool = false  ## Prevents double-processing (hit + miss, etc.)

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
	
	print("Note: Initialized note %d at (%.0f, %.0f), traveling to (%.0f, %.0f) over %.0fms" % [
		p_midi_note,
		spawn_position.x, spawn_position.y,
		target_position.x, target_position.y,
		_travel_duration_ms
	])

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
	
	# Trigger at 50% progress (halfway to target)
	if not _has_entered_50_percent and progress >= 0.5:
		_has_entered_50_percent = true
		entered_50_percent_zone.emit(self)
	
	# Trigger approaching target at 50% progress for highlight pulse
	if not _has_approached_target and progress >= 0.5:
		_has_approached_target = true
		approaching_target.emit(self)
	
	# Trigger at 75% progress (last quarter of travel)
	if not _has_entered_75_percent and progress >= 0.75:
		_has_entered_75_percent = true
		entered_75_percent_zone.emit(self)
	
	if progress >= 1.0:
		# Reached or passed target
		position = target_position
		_is_traveling = false
		arrived_at_target.emit(self)
		return
	
	# Linear interpolation from spawn to target
	position = spawn_position.lerp(target_position, progress)


func on_hit(rating: int) -> void:
	"""Called when note is successfully hit - stop movement and play hit effect"""
	if _is_destroyed:
		return  # Already processed
	
	_is_destroyed = true
	_is_traveling = false
	
	# Play hit effect based on rating
	var effect_color: Color = HitRating.get_rating_color(rating)
	
	# Create hit animation - quick color change, scale, then fade out
	var tween: Tween = create_tween()
	
	# Instantly change to rating color and scale up (0.05s)
	tween.set_parallel(true)
	tween.tween_property(self, "self_modulate", effect_color, 0.05)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.05)
	
	# Hold for a moment (0.15s)
	tween.chain().tween_interval(0.15)
	
	# Then fade out while keeping the color (0.15s)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	
	# Destroy after animation
	tween.chain().tween_callback(destroy)


func on_missed() -> void:
	"""Called when note reaches target without being hit - rush at player"""
	if _is_destroyed:
		return  # Already processed
	
	_is_destroyed = true
	_is_traveling = false
	
	# Get player position (center of gameplay area)
	var player_pos: Vector2 = Vector2(960, 540)
	var gameplay_area: Node2D = get_tree().get_first_node_in_group("gameplay_area")
	if gameplay_area:
		player_pos = gameplay_area.global_position
	
	# Turn red and rush at player while shrinking
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Change to red immediately
	tween.tween_property(self, "self_modulate", Color.RED, 0.05)
	
	# Rush to player position
	tween.tween_property(self, "global_position", player_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Shrink while moving
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Destroy after animation
	tween.chain().tween_callback(destroy)


func on_early_hit() -> void:
	"""Called when player hits too early - rush at player and shrink"""
	if _is_destroyed:
		return  # Already processed
	
	_is_destroyed = true
	_is_traveling = false
	
	# Get player position (center of gameplay area)
	var player_pos: Vector2 = Vector2(960, 540)
	var gameplay_area: Node2D = get_tree().get_first_node_in_group("gameplay_area")
	if gameplay_area:
		player_pos = gameplay_area.global_position
	
	# Turn red and rush at player while shrinking
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Change to red immediately
	tween.tween_property(self, "self_modulate", Color.RED, 0.05)
	
	# Rush to player position
	tween.tween_property(self, "global_position", player_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Shrink while moving
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Destroy after animation
	tween.chain().tween_callback(destroy)


func destroy() -> void:
	queue_free()
