extends Node

## Manages visual effects for the player sprite.
## - Pulses to the beat
## - Flashes red and strobes on missed note hit

signal effect_complete

@export var pulse_scale_amount: float = 1.15
@export var pulse_duration_ms: float = 150.0
@export var beat_pulse_window_ms: float = 50.0  ## Window to trigger pulse around beat time

@export var flash_duration_s: float = 0.5
@export var strobe_cycle_time_s: float = 0.08
@export var strobe_min_alpha: float = 0.7  ## Minimum opacity during strobe (0.7 = 70%)

var _player_sprite: Sprite2D = null
var _original_modulate: Color = Color.WHITE
var _beat_pulse_tween: Tween = null
var _flash_tween: Tween = null
var _is_flashing: bool = false

# References for beat timing
var _note_scheduler: Node = null
var _music_player: Node = null
var _last_quarter_note_time_ms: float = -1000.0  ## Time of last quarter note pulse
var _quarter_note_interval_ms: float = 500.0  ## Duration of a quarter note in ms (updated from BPM)


func _process(_delta: float) -> void:
	"""Check for quarter note timing to trigger pulse"""
	if _music_player == null:
		return
	
	if not _music_player.is_playing():
		return
	
	var current_time_ms: float = _music_player.get_current_time_ms()
	
	# Update quarter note interval from current BPM
	_update_quarter_note_interval()
	
	# Calculate which quarter note we should be on
	var time_since_last_pulse: float = current_time_ms - _last_quarter_note_time_ms
	
	# Check if we've passed a quarter note boundary
	if time_since_last_pulse >= _quarter_note_interval_ms:
		# Calculate how many quarter notes have passed to stay in sync
		var quarters_passed: int = int(time_since_last_pulse / _quarter_note_interval_ms)
		_last_quarter_note_time_ms += quarters_passed * _quarter_note_interval_ms
		pulse_to_beat()


func set_player_sprite(sprite: Sprite2D) -> void:
	"""Set the player sprite to apply effects to"""
	_player_sprite = sprite
	if _player_sprite:
		_original_modulate = _player_sprite.modulate


func pulse_to_beat() -> void:
	"""Pulse the player sprite to the beat"""
	if _player_sprite == null:
		return
	
	if _is_flashing:
		return  # Don't pulse during flash effect
	
	# Calculate pulse duration based on BPM
	var bpm_pulse_duration: float = _calculate_pulse_duration_from_bpm()
	
	# Cancel existing pulse tween if any
	if _beat_pulse_tween and _beat_pulse_tween.is_valid():
		_beat_pulse_tween.kill()
	
	_beat_pulse_tween = create_tween()
	_beat_pulse_tween.set_ease(Tween.EASE_OUT)
	_beat_pulse_tween.set_trans(Tween.TRANS_BACK)  # Bouncy overshoot effect
	
	# Scale up quickly
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(pulse_scale_amount, pulse_scale_amount),
		bpm_pulse_duration * 0.3  # 30% of beat for expansion
	)
	
	# Scale back down with bounce
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(1.0, 1.0),
		bpm_pulse_duration * 0.7  # 70% of beat for contraction
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func flash_on_missed_hit() -> void:
	"""Flash red and strobe opacity when a missed note hits the player"""
	if _player_sprite == null:
		return
	
	if _is_flashing:
		return  # Already flashing
	
	_is_flashing = true
	
	# Cancel beat pulse if active
	if _beat_pulse_tween and _beat_pulse_tween.is_valid():
		_beat_pulse_tween.kill()
	
	# Cancel any existing flash tween
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	
	_flash_tween = create_tween()
	_flash_tween.set_parallel(false)
	
	# Change to red immediately
	_flash_tween.tween_property(_player_sprite, "modulate", Color.RED, 0.05)
	
	# Strobe opacity for half a second
	var num_strobes: int = int(flash_duration_s / (strobe_cycle_time_s * 2.0))
	for i in range(num_strobes):
		_flash_tween.tween_property(
			_player_sprite,
			"modulate:a",
			strobe_min_alpha,
			strobe_cycle_time_s
		)
		_flash_tween.tween_property(
			_player_sprite,
			"modulate:a",
			1.0,
			strobe_cycle_time_s
		)
	
	# Restore original modulate
	_flash_tween.tween_property(_player_sprite, "modulate", _original_modulate, 0.05)
	
	# Mark flash as complete
	_flash_tween.tween_callback(_on_flash_complete)


func _update_quarter_note_interval() -> void:
	"""Update the quarter note interval based on current BPM"""
	if _music_player == null:
		return
	
	# Try to get BPM from tempo map
	if _music_player.has_method("get_tempo_map"):
		var tempo_map: Array = _music_player.get_tempo_map()
		if tempo_map.size() > 0:
			var first_tempo = tempo_map[0]
			var bpm: float = 120.0  # Default BPM
			
			if first_tempo is Dictionary:
				bpm = first_tempo.get("bpm", 120.0)
			elif "bpm" in first_tempo:
				bpm = first_tempo.bpm
			
			# Calculate quarter note duration in milliseconds
			_quarter_note_interval_ms = 60000.0 / bpm


func _calculate_pulse_duration_from_bpm() -> float:
	"""Calculate pulse duration based on current BPM"""
	# Use a fraction of the quarter note for the pulse (about 1/4 of a beat)
	return (_quarter_note_interval_ms / 1000.0) * 0.25


func _on_flash_complete() -> void:
	"""Called when flash effect finishes"""
	_is_flashing = false
	effect_complete.emit()


func reset() -> void:
	"""Reset all effects and restore original state"""
	if _beat_pulse_tween and _beat_pulse_tween.is_valid():
		_beat_pulse_tween.kill()
	
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	
	_is_flashing = false
	
	if _player_sprite:
		_player_sprite.scale = Vector2(1.0, 1.0)
		_player_sprite.modulate = _original_modulate
