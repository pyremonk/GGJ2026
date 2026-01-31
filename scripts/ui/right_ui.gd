extends Control

## Right UI panel displaying Veilshifts (mask collection) and Now Playing information.
## Positioned at x=1500 to x=1920 of the screen.

## References to mask icon displays (set via unique names in scene)
@onready var mask_icons: Array[TextureRect] = []
@onready var mask_1_icon: TextureRect = %Mask1Icon
@onready var mask_2_icon: TextureRect = %Mask2Icon
@onready var mask_3_icon: TextureRect = %Mask3Icon
@onready var mask_4_icon: TextureRect = %Mask4Icon

## References to Now Playing display elements
@onready var track_name_label: Label = %TrackNameLabel
@onready var artist_label: Label = %ArtistLabel
@onready var track_progress_bar: ProgressBar = %TrackProgressBar
@onready var time_display_label: Label = %TimeDisplayLabel

## Export properties for customization
@export var mask_fade_duration: float = 0.3  ## Duration of mask collection animation

## Track duration in milliseconds
var track_duration_ms: float = 0.0


func _ready() -> void:
	_initialize_mask_icons()
	_initialize_now_playing_display()


## Initialize mask icon array and set default opacity
func _initialize_mask_icons() -> void:
	# Build array of mask icons
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


## Initialize Now Playing display with placeholder values
func _initialize_now_playing_display() -> void:
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


## Set track information from level config
func set_track_info(track_name: String, artist_name: String, duration_ms: float) -> void:
	track_duration_ms = duration_ms
	
	if track_name_label:
		track_name_label.text = track_name
	
	if artist_label:
		artist_label.text = "By: %s" % artist_name
	
	if track_progress_bar:
		track_progress_bar.max_value = duration_ms


## Update Now Playing display with current playback position
func update_now_playing(current_time_ms: float) -> void:
	# Update progress bar
	if track_progress_bar:
		track_progress_bar.value = current_time_ms
	
	# Update time display
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


## Trigger mask collection animation
func collect_mask(mask_index: int) -> void:
	if mask_index < 0 or mask_index >= mask_icons.size():
		push_warning("RightUI: Invalid mask_index %d" % mask_index)
		return
	
	var icon: TextureRect = mask_icons[mask_index]
	if not icon:
		return
	
	# Animate opacity from 50% to 100%
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "modulate:a", 1.0, mask_fade_duration)


## Reset all masks to uncollected state
func reset_masks() -> void:
	for icon: TextureRect in mask_icons:
		if icon:
			icon.modulate.a = 0.5


## Reset entire display to initial state
func reset_display() -> void:
	reset_masks()
	_initialize_now_playing_display()
