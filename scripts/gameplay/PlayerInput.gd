extends Node

## Listens for player input and emits timing information.
## Uses song-relative timing from MusicPlayer.

signal input_pressed(action_name: String, input_time_ms: float)

var _music_player: Node = null

func set_music_player(music_player: Node) -> void:
	_music_player = music_player

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	
	if _music_player == null:
		push_error("PlayerInput: MusicPlayer not set")
		return
	
	var input_time_ms: float = _music_player.get_current_time_ms()
	var action_fired: bool = false
	
	# Check all four directional actions
	if Input.is_action_just_pressed("move_up"):
		input_pressed.emit("action_up", input_time_ms)
		action_fired = true
	
	if Input.is_action_just_pressed("move_down"):
		input_pressed.emit("action_down", input_time_ms)
		action_fired = true
	
	if Input.is_action_just_pressed("move_left"):
		input_pressed.emit("action_left", input_time_ms)
		action_fired = true
	
	if Input.is_action_just_pressed("move_right"):
		input_pressed.emit("action_right", input_time_ms)
		action_fired = true
	
	if action_fired:
		get_viewport().set_input_as_handled()
