extends Node
## Manages background menu music playback across scenes
##
## Handles starting, stopping, and fading menu music. Tracks playback position
## to resume from the same point after level tracks end.

## The active menu music player (reparented by ProjectMusicController)
var _menu_music_player: AudioStreamPlayer = null

## Stored playback position when music is stopped
var _stored_position: float = 0.0

## Whether menu music should be playing
var _should_be_playing: bool = false


## Register the menu music AudioStreamPlayer with this manager
func register_menu_music_player(player: AudioStreamPlayer) -> void:
	if player == null:
		push_error("MenuMusicManager: Cannot register null player")
		return
	
	_menu_music_player = player
	_should_be_playing = player.playing


## Start playing menu music from the beginning
func play_menu_music() -> void:
	if _menu_music_player == null:
		push_warning("MenuMusicManager: No menu music player registered")
		return
	
	_stored_position = 0.0
	_should_be_playing = true
	_menu_music_player.play()


## Stop menu music and store current playback position
func stop_menu_music() -> void:
	if _menu_music_player == null:
		return
	
	if _menu_music_player.playing:
		_stored_position = _menu_music_player.get_playback_position()
	
	_should_be_playing = false
	_menu_music_player.stop()


## Fade out menu music quickly then stop
func fade_out_menu_music(duration: float = 0.5) -> void:
	if _menu_music_player == null:
		return
	
	if not _menu_music_player.playing:
		return
	
	_should_be_playing = false
	
	# Fade out to silence
	var tween: Tween = create_tween()
	tween.tween_property(_menu_music_player, "volume_db", -80.0, duration)
	await tween.finished
	
	# Store position and stop
	_stored_position = _menu_music_player.get_playback_position()
	_menu_music_player.stop()
	
	# Reset volume for next playback
	_menu_music_player.volume_db = 0.0


## Fade in menu music from stored position
func fade_in_menu_music(duration: float = 0.2) -> void:
	if _menu_music_player == null:
		push_warning("MenuMusicManager: No menu music player registered")
		return
	
	_should_be_playing = true
	
	# Resume from stored position
	_menu_music_player.play(_stored_position)
	
	# Fade in from silence
	_menu_music_player.volume_db = -80.0
	
	var tween: Tween = create_tween()
	tween.tween_property(_menu_music_player, "volume_db", 0.0, duration)


## Get whether menu music is currently playing
func is_playing() -> bool:
	return _menu_music_player != null and _menu_music_player.playing


## Get the current playback position
func get_playback_position() -> float:
	if _menu_music_player == null:
		return 0.0
	
	if _menu_music_player.playing:
		return _menu_music_player.get_playback_position()
	
	return _stored_position
