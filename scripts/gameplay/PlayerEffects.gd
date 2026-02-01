extends Node

## Manages visual effects for the player sprite.
## - Pulses to the beat
## - Flashes red and strobes on missed note hit

signal effect_complete

@export var pulse_scale_amount: float = 1.15
@export var pulse_duration_ms: float = 150.0
@export var beat_pulse_window_ms: float = 50.0  ## Window to trigger pulse around beat time

@export var flash_duration_s: float = 0.5
@export var strobe_cycle_time_s: float = 0.05

var _player_sprite: Sprite2D = null
var _original_modulate: Color = Color.WHITE
var _beat_pulse_tween: Tween = null
var _flash_tween: Tween = null
var _is_flashing: bool = false

# References for beat timing
var _note_scheduler: Node = null
var _music_player: Node = null
var _last_pulsed_beat: int = -1


func _process(_delta: float) -> void:
	"""Check for beat timing to trigger pulse"""
	if _note_scheduler == null or _music_player == null:
		return
	
	if not _music_player.is_playing():
		return
	
	var current_time_ms: float = _music_player.get_current_time_ms()
	var next_beat: BeatEvent = _note_scheduler.get_next_beat()
	
	if next_beat == null:
		return
	
	# Check if we're close to the beat time and haven't pulsed for this beat yet
	var time_to_beat: float = next_beat.hit_time_ms - current_time_ms
	
	if abs(time_to_beat) <= beat_pulse_window_ms and next_beat.beat_number != _last_pulsed_beat:
		_last_pulsed_beat = next_beat.beat_number
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
	
	# Cancel existing pulse tween if any
	if _beat_pulse_tween and _beat_pulse_tween.is_valid():
		_beat_pulse_tween.kill()
	
	_beat_pulse_tween = create_tween()
	_beat_pulse_tween.set_ease(Tween.EASE_OUT)
	_beat_pulse_tween.set_trans(Tween.TRANS_ELASTIC)
	
	# Scale up
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(pulse_scale_amount, pulse_scale_amount),
		pulse_duration_ms / 1000.0
	)
	
	# Scale back down
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(1.0, 1.0),
		pulse_duration_ms / 1000.0
	)


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
	
	# Strobe opacity for half a second (50% to 100% opacity)
	var num_strobes: int = int(flash_duration_s / (strobe_cycle_time_s * 2.0))
	for i in range(num_strobes):
		_flash_tween.tween_property(
			_player_sprite,
			"modulate:a",
			0.5,
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
