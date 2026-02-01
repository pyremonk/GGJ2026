extends Control

## Right UI panel displaying Veilshifts (mask collection) and Now Playing information
## Positioned at x=1500 to x=1920 of the screen

@onready var mask_icons: Array[TextureRect] = []
@onready var mask_1_icon: TextureRect = %Mask1Icon
@onready var mask_2_icon: TextureRect = %Mask2Icon
@onready var mask_3_icon: TextureRect = %Mask3Icon
@onready var mask_4_icon: TextureRect = %Mask4Icon

@onready var track_name_label: Label = %TrackNameLabel
@onready var artist_label: Label = %ArtistLabel
@onready var track_progress_bar: ProgressBar = %TrackProgressBar
@onready var time_display_label: Label = %TimeDisplayLabel
@onready var pause_resume_button: Button = %PauseResumeButton

@export var mask_fade_duration: float = 0.3

var track_duration_ms: float = 0.0


func _ready() -> void:
	_initialize_mask_icons()
	_initialize_now_playing_display()
	_connect_pause_button()
	_connect_music_player_signals()


func _connect_music_player_signals() -> void:
	"""Connect to MusicPlayer signals to sync pause button state"""
	var music_player: Node = _find_music_player()
	if music_player:
		if music_player.has_signal("playback_started"):
			music_player.playback_started.connect(_on_music_playback_started)
		if music_player.has_signal("playback_stopped"):
			music_player.playback_stopped.connect(_on_music_playback_stopped)
		if music_player.has_signal("playback_paused"):
			music_player.playback_paused.connect(_on_music_playback_paused)
		if music_player.has_signal("playback_resumed"):
			music_player.playback_resumed.connect(_on_music_playback_resumed)


func _find_music_player() -> Node:
	"""Find MusicPlayer node in the scene tree"""
	var gameplay_base: Node = get_tree().root.find_child("GameplayBase", true, false)
	if not gameplay_base:
		return null
	
	return gameplay_base.find_child("MusicPlayer", true, false)


func _connect_pause_button() -> void:
	"""Connect pause/resume button signal"""
	if pause_resume_button:
		pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)


func _initialize_mask_icons() -> void:
	"""Initialize mask icon array and set default opacity"""
	if mask_1_icon:
		mask_icons.append(mask_1_icon)
	if mask_2_icon:
		mask_icons.append(mask_2_icon)
	if mask_3_icon:
		mask_icons.append(mask_3_icon)
	if mask_4_icon:
		mask_icons.append(mask_4_icon)
	
	# Set all masks to 50% opacity (uncollected state)
	for icon: TextureRect in mask_icons:
		if icon:
			icon.modulate.a = 0.5


func _initialize_now_playing_display() -> void:
	"""Initialize Now Playing display with placeholder values"""
	if track_name_label:
		track_name_label.text = "Track Name"
	
	if artist_label:
		artist_label.text = "By: Artist"
	
	if track_progress_bar:
		track_progress_bar.min_value = 0.0
		track_progress_bar.max_value = 100.0
		track_progress_bar.value = 0.0
	
	if time_display_label:
		time_display_label.text = "0:00 / 0:00"


func set_track_info(track_name: String, artist_name: String, duration_ms: float) -> void:
	"""Set track information from level config"""
	track_duration_ms = duration_ms
	
	if track_name_label:
		track_name_label.text = track_name
	
	if artist_label:
		artist_label.text = "By: %s" % artist_name
	
	if track_progress_bar:
		track_progress_bar.max_value = duration_ms


func update_now_playing(current_time_ms: float) -> void:
	"""Update Now Playing display with current playback position"""
	if track_progress_bar:
		track_progress_bar.value = current_time_ms
	
	if time_display_label:
		var current_minutes: int = int(current_time_ms / 60000.0)
		var current_seconds: int = int((fmod(current_time_ms, 60000.0)) / 1000.0)
		var total_minutes: int = int(track_duration_ms / 60000.0)
		var total_seconds: int = int((fmod(track_duration_ms, 60000.0)) / 1000.0)
		
		time_display_label.text = "%d:%02d / %d:%02d" % [
			current_minutes,
			current_seconds,
			total_minutes,
			total_seconds
		]


func collect_mask(mask_index: int) -> void:
	"""Trigger mask collection animation"""
	if mask_index < 0 or mask_index >= mask_icons.size():
		push_warning("RightPanel: Invalid mask_index %d" % mask_index)
		return
	
	var icon: TextureRect = mask_icons[mask_index]
	if not icon:
		return
	
	# Animate opacity from 50% to 100%
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "modulate:a", 1.0, mask_fade_duration)


func reset_masks() -> void:
	"""Reset all masks to uncollected state"""
	for icon: TextureRect in mask_icons:
		if icon:
			icon.modulate.a = 0.5


func reset_display() -> void:
	"""Reset entire display to initial state"""
	reset_masks()
	_initialize_now_playing_display()


func _animate_label(label: Label) -> void:
	"""Pulse animation for value updates"""
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)


func _on_pause_resume_button_pressed() -> void:
	"""Toggle pause state and update button text"""
	var music_player: Node = _find_music_player()
	if not music_player:
		return
	
	# Toggle music pause/resume
	if music_player.has_method("is_paused") and music_player.is_paused():
		if music_player.has_method("resume_playback"):
			music_player.resume_playback()
	else:
		if music_player.has_method("pause_playback"):
			music_player.pause_playback()
	
	# Also toggle tree pause state
	get_tree().paused = not get_tree().paused
	_update_pause_button_text()


func _on_music_playback_started() -> void:
	"""Handle music playback started signal"""
	set_pause_button_enabled(true)
	_update_pause_button_text()


func _on_music_playback_stopped() -> void:
	"""Handle music playback stopped signal"""
	set_pause_button_enabled(false)
	if pause_resume_button:
		pause_resume_button.text = "Pause"


func _on_music_playback_paused() -> void:
	"""Handle music playback paused signal"""
	_update_pause_button_text()


func _on_music_playback_resumed() -> void:
	"""Handle music playback resumed signal"""
	_update_pause_button_text()


func _update_pause_button_text() -> void:
	"""Update button text based on current pause state"""
	if not pause_resume_button:
		return
	
	if get_tree().paused:
		pause_resume_button.text = "Resume"
	else:
		pause_resume_button.text = "Pause"


func set_pause_button_enabled(enabled: bool) -> void:
	"""Enable or disable the pause button (e.g., when track is not playing)"""
	if pause_resume_button:
		pause_resume_button.disabled = not enabled

