extends Node

## Listens for player input and emits timing information.
## Uses song-relative timing from MusicPlayer.
## Uses _process() with input polling to avoid UI input conflicts.

signal input_pressed(action_name: String, input_time_ms: float)

var _music_player: Node = null

func set_music_player(music_player: Node) -> void:
	_music_player = music_player

func _process(_delta: float) -> void:
	if _music_player == null:
		return
	
	var input_time_ms: float = _music_player.get_current_time_ms()
	
	# Check all four directional actions using direct polling
	# This avoids conflicts with UI input handling
	if Input.is_action_just_pressed("move_up"):
		input_pressed.emit("action_up", input_time_ms)
	
	if Input.is_action_just_pressed("move_down"):
		input_pressed.emit("action_down", input_time_ms)
	
	if Input.is_action_just_pressed("move_left"):
		input_pressed.emit("action_left", input_time_ms)
	
	if Input.is_action_just_pressed("move_right"):
		input_pressed.emit("action_right", input_time_ms)
