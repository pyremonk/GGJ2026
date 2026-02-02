class_name Note
extends Sprite2D

## Visual note that spawns and travels toward a target position.
## Moves linearly from spawn point to target, arriving exactly at the specified time.

signal arrived_at_target(note: Note)
signal entered_50_percent_zone(note: Note)
signal entered_75_percent_zone(note: Note)
signal approaching_target(note: Note)  ## For highlight pulse animation

## Veilshift velocity mapping (velocity -> mask data)
const VEILSHIFT_VELOCITIES: Dictionary = {
	69: {"mask_id": 1, "texture_path": "res://assets/masks/Player-Mask-1.png"},
	79: {"mask_id": 2, "texture_path": "res://assets/masks/Player-Mask-2.png"},
	89: {"mask_id": 3, "texture_path": "res://assets/masks/Player-Mask-3.png"},
	99: {"mask_id": 4, "texture_path": "res://assets/masks/Player-Mask-4.png"}
}

## MIDI note to sprite mapping (for normal notes, not veilshifts)
const NOTE_SPRITE_MAPPING: Dictionary = {
	60: "res://assets/notes/Note-Left.png",   # C4
	61: "res://assets/notes/Note-Left.png",   # C#4
	62: "res://assets/notes/Note-Left.png",   # D4
	63: "res://assets/notes/Note-Up.png",     # D#4
	64: "res://assets/notes/Note-Up.png",     # E4
	65: "res://assets/notes/Note-Up.png",     # F4
	66: "res://assets/notes/Note-Right.png",  # F#4
	67: "res://assets/notes/Note-Right.png",  # G4
	68: "res://assets/notes/Note-Right.png",  # G#4
	69: "res://assets/notes/Note-Down.png",   # A4
	70: "res://assets/notes/Note-Down.png",   # A#4
	71: "res://assets/notes/Note-Down.png"    # B4
}

var spawn_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var arrival_time_ms: float = 0.0
var spawn_time_ms: float = 0.0
var movement_direction: String = ""  ## "up", "down", "left", "right"
var midi_note: int = -1
var beat_number: int = 0
var velocity: int = 0
var is_veilshift: bool = false
var veilshift_mask_id: int = 0  ## 0 = normal note, 1-4 = veilshift mask

var _is_traveling: bool = false
var _travel_duration_ms: float = 0.0
var _has_entered_50_percent: bool = false
var _has_entered_75_percent: bool = false
var _has_approached_target: bool = false
var _is_destroyed: bool = false  ## Prevents double-processing (hit + miss, etc.)

var _hit_sound: AudioStream
var _miss_sound: AudioStream

func _ready() -> void:
	# Pre-load sound files
	_hit_sound = load("res://assets/sfx/note_hit_sounds/Hit.ogg")
	_miss_sound = load("res://assets/sfx/note_hit_sounds/Miss.ogg")

func initialize(p_spawn_pos: Vector2, p_target_pos: Vector2, p_arrival_time_ms: float, p_spawn_time_ms: float, p_midi_note: int, p_beat_number: int, p_direction: String, p_velocity: int = 0) -> void:
	spawn_position = p_spawn_pos
	target_position = p_target_pos
	arrival_time_ms = p_arrival_time_ms
	spawn_time_ms = p_spawn_time_ms
	midi_note = p_midi_note
	beat_number = p_beat_number
	movement_direction = p_direction
	velocity = p_velocity
	
	# Check if this is a veilshift note (veilshift logic overrides sprite mapping)
	if velocity in VEILSHIFT_VELOCITIES:
		is_veilshift = true
		var veilshift_data: Dictionary = VEILSHIFT_VELOCITIES[velocity]
		veilshift_mask_id = veilshift_data["mask_id"]
		var veilshift_texture: Texture2D = load(veilshift_data["texture_path"])
		if veilshift_texture:
			texture = veilshift_texture
			print("Note: Veilshift note (velocity=%d, mask_id=%d) loaded sprite" % [velocity, veilshift_mask_id])
		else:
			push_error("Note: Failed to load veilshift texture: %s" % veilshift_data["texture_path"])
	else:
		# Normal note - use sprite based on MIDI note value
		if midi_note in NOTE_SPRITE_MAPPING:
			var note_texture_path: String = NOTE_SPRITE_MAPPING[midi_note]
			var note_texture: Texture2D = load(note_texture_path)
			if note_texture:
				texture = note_texture
				print("Note: Normal note (midi=%d) loaded sprite: %s" % [midi_note, note_texture_path])
			else:
				push_error("Note: Failed to load note texture: %s" % note_texture_path)
		else:
			push_warning("Note: No sprite mapping for MIDI note %d" % midi_note)
	
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
	
	# Play hit sound (create one-shot player that survives note destruction)
	_play_one_shot_sound(_hit_sound)
	
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
	
	# Play miss sound (create one-shot player that survives note destruction)
	_play_one_shot_sound(_miss_sound)
	
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


func _play_one_shot_sound(sound: AudioStream) -> void:
	"""Create a one-shot audio player that auto-frees after playing"""
	if not sound:
		return
	
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = sound
	player.bus = "SFX"
	
	# Add to the scene tree root so it persists when this note is freed
	get_tree().root.add_child(player)
	
	# Auto-free when finished
	player.finished.connect(func(): player.queue_free())
	
	# Play the sound
	player.play()


func destroy() -> void:
	queue_free()
