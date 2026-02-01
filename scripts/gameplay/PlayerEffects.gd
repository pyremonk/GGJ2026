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

# References
var _note_targets: Node2D = null





func set_player_sprite(sprite: Sprite2D) -> void:
	"""Set the player sprite to apply effects to"""
	_player_sprite = sprite
	if _player_sprite:
		_original_modulate = _player_sprite.modulate


func set_note_targets(targets: Node2D) -> void:
	"""Set the note targets for pulsing on input"""
	_note_targets = targets


func pulse_on_input(action_name: String) -> void:
	"""Pulse player sprite and corresponding note target on input"""
	pulse_to_beat()
	
	# Pulse the corresponding note target
	if _note_targets and _note_targets.has_method("highlight_target"):
		var direction: String = _action_to_direction(action_name)
		if not direction.is_empty():
			_note_targets.highlight_target(direction)


func _action_to_direction(action_name: String) -> String:
	"""Convert action name to direction string"""
	match action_name:
		"action_up":
			return "up"
		"action_down":
			return "down"
		"action_left":
			return "left"
		"action_right":
			return "right"
		_:
			return ""


func pulse_to_beat() -> void:
	"""Pulse the player sprite"""
	if _player_sprite == null:
		return
	
	if _is_flashing:
		return  # Don't pulse during flash effect
	
	# Cancel existing pulse tween if any
	if _beat_pulse_tween and _beat_pulse_tween.is_valid():
		_beat_pulse_tween.kill()
	
	var pulse_duration: float = pulse_duration_ms / 1000.0
	
	_beat_pulse_tween = create_tween()
	_beat_pulse_tween.set_ease(Tween.EASE_OUT)
	_beat_pulse_tween.set_trans(Tween.TRANS_BACK)  # Bouncy overshoot effect
	
	# Scale up quickly
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(pulse_scale_amount, pulse_scale_amount),
		pulse_duration * 0.3  # 30% of pulse for expansion
	)
	
	# Scale back down with bounce
	_beat_pulse_tween.tween_property(
		_player_sprite,
		"scale",
		Vector2(1.0, 1.0),
		pulse_duration * 0.7  # 70% of pulse for contraction
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
