extends Node

## Listens for player input and emits timing information.
## Uses song-relative timing from MusicPlayer.

signal input_pressed(action_name: String, input_time_ms: float)

var _music_player: Node = null

func set_music_player(music_player: Node) -> void:
	_music_player = music_player

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_RIGHT and event.pressed and not event.is_echo():
			if _music_player == null:
				push_error("PlayerInput: MusicPlayer not set")
				return
			
			var input_time_ms: float = _music_player.get_current_time_ms()
			input_pressed.emit("rhythm_tap", input_time_ms)
			get_viewport().set_input_as_handled()
