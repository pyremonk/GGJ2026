extends Node2D

## Base gameplay scene with 3-column layout and z-layering for rhythm game
## Implements screen layout per specs/screen-layout.spec.md

# Signals for level outcomes
signal level_won(next_level_path: String)
signal level_lost

# References to key nodes
@onready var spawn_points: Node2D = %SpawnPoints
@onready var gameplay_area: Node2D = %GameplayArea
@onready var player: Sprite2D = %Player
@onready var note_targets: Node2D = %NoteTargets
@onready var active_objects: Node2D = %ActiveObjects
@onready var left_ui: Control = %LeftUI
@onready var right_ui: Control = %RightUI

# Rhythm system components
@onready var music_player: Node = %MusicPlayer
@onready var midi_event_router: Node = %MIDIEventRouter
@onready var note_scheduler: Node = %NoteScheduler
@onready var player_input: Node = %PlayerInput
@onready var judge: Node = %Judge
@onready var referee: Node = %Referee
@onready var note_spawner: Node = %NoteSpawner
@onready var ui_state_manager: Node = %UIStateManager
@onready var player_effects: Node = %PlayerEffects

const BASE_RESOLUTION: Vector2 = Vector2(1920, 1080)

# Veilshift velocity to mask_id mapping (0-indexed for UI)
const VEILSHIFT_VELOCITY_TO_MASK: Dictionary = {
	69: 0,  # Player-Mask-1 -> mask_index 0
	79: 1,  # Player-Mask-2 -> mask_index 1
	89: 2,  # Player-Mask-3 -> mask_index 2
	99: 3   # Player-Mask-4 -> mask_index 3
}

# Test MIDI/Audio files
@export_file("*.mid") var test_midi_file: String = "res://assets/testing_track/Testing_Track.mid"
@export_file("*.ogg") var test_audio_file: String = "res://assets/testing_track/Testing_Track.ogg"

# Level configuration
@export var level_config: LevelConfig = null
@export_file("*.tscn") var next_level_path: String = ""

const MISS_THRESHOLD_PERCENT: float = 0.25  # 25% miss rate = failure

var _total_beats: int = 0
var _track_finished: bool = false


func _ready() -> void:
	_setup_viewport_scaling()
	_setup_rhythm_system()
	_connect_referee_signals()
	_connect_music_player_signals()
	
	# Add gameplay_area to group for note early-hit effect
	if gameplay_area:
		gameplay_area.add_to_group("gameplay_area")
	
	# Set up player effects
	if player_effects and player:
		player_effects.set_player_sprite(player)
		player_effects.set_note_targets(note_targets)
		# Connect veilshift signal to UI
		if player_effects.has_signal("veilshift_collected"):
			player_effects.veilshift_collected.connect(_on_veilshift_collected)
		# Reset player sprite and effects
		player_effects.reset()
	
	# Reset UI masks to default state
	if right_ui and right_ui.has_method("reset_masks"):
		right_ui.reset_masks()
	
	# Auto-start for testing
	call_deferred("_start_test_level")


func _setup_viewport_scaling() -> void:
	"""Configure viewport to maintain relative positioning on resize"""
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _on_viewport_resized() -> void:
	"""Recalculate positions when viewport size changes"""
	# All child nodes will scale automatically with CanvasLayer scaling
	# Individual positioning adjustments can be made here if needed
	pass


func _setup_rhythm_system() -> void:
	"""Wire up all rhythm system components"""
	# Apply timing parameters from level_config if available
	if level_config != null:
		if music_player:
			music_player.default_bpm = level_config.default_bpm
			music_player.audio_delay_ms = level_config.audio_delay_ms
		if note_scheduler:
			note_scheduler.lookahead_ms = level_config.lookahead_ms
		if note_spawner:
			note_spawner.spawn_lookahead_ms = level_config.spawn_lookahead_ms
		print("GameplayBase: Applied level_config timing parameters:")
		print("  BPM: %.1f, Audio Delay: %.0fms, Lookahead: %.0fms, Spawn Lookahead: %.0fms" % [
			level_config.default_bpm,
			level_config.audio_delay_ms,
			level_config.lookahead_ms,
			level_config.spawn_lookahead_ms
		])
	
	# Connect NoteSpawner to scene nodes
	note_spawner.spawn_points_container = spawn_points
	note_spawner.note_targets = note_targets
	note_spawner.active_notes_container = active_objects
	note_spawner.note_scheduler = note_scheduler
	note_spawner.music_player = music_player
	
	# Connect NoteScheduler to NoteSpawner
	if note_scheduler.has_signal("upcoming_beat"):
		note_scheduler.upcoming_beat.connect(note_spawner._on_upcoming_beat)
	
	# Connect PlayerInput to MusicPlayer for timing
	player_input.set_music_player(music_player)
	
	# Connect PlayerInput to Judge for input processing
	if player_input.has_signal("input_pressed"):
		player_input.input_pressed.connect(_on_player_input)
		# Also connect to PlayerEffects for visual feedback
		if player_effects:
			player_input.input_pressed.connect(_on_player_input_for_effects)
	
	# Connect Judge judgment_made signal to Referee
	if judge.has_signal("judgment_made"):
		judge.judgment_made.connect(referee._on_judgment_made)
		# Also connect to note spawner for hit effects
		judge.judgment_made.connect(_on_judgment_for_note_hit)
	
	# Connect early input rejection signal
	if judge.has_signal("early_input_rejected"):
		judge.early_input_rejected.connect(_on_early_input_rejected)
	
	# Connect NoteScheduler beat_missed signal
	if note_scheduler.has_signal("beat_missed"):
		note_scheduler.beat_missed.connect(_on_beat_missed)


func _on_player_input_for_effects(action_name: String, _input_time_ms: float) -> void:
	"""Trigger visual effects on player input"""
	if player_effects:
		player_effects.pulse_on_input(action_name)
	
	# Pulse the corresponding note target
	var direction: String = _action_to_direction(action_name)
	if not direction.is_empty() and note_targets:
		note_targets.pulse_target(direction)


func _start_test_level() -> void:
	"""Load and start MIDI/audio from level_config or test files"""
	var midi_resource: Resource = null
	var audio_file: String = ""
	
	# Prioritize level_config over test files
	if level_config != null:
		midi_resource = level_config.midi_resource
		audio_file = level_config.audio_file_path
		print("GameplayBase: Loading from level_config...")
		print("  Level: ", level_config.level_name)
		print("  Track: ", level_config.track_name)
		print("  Artist: ", level_config.artist_name)
	else:
		# For test files, load the MIDI as a resource
		if not test_midi_file.is_empty():
			midi_resource = load(test_midi_file)
		audio_file = test_audio_file
		print("GameplayBase: Loading test level...")
	
	if midi_resource == null or audio_file.is_empty():
		push_warning("No MIDI/audio files configured. Set level_config or test files.")
		return
	
	print("  MIDI: ", midi_resource)
	print("  Audio: ", audio_file)
	
	# Load audio stream
	var audio_stream: AudioStream = load(audio_file)
	if audio_stream == null:
		push_error("Failed to load audio: " + audio_file)
		return
	
	# Load files
	var success: bool = music_player.load_files(audio_stream, midi_resource)
	if not success:
		push_error("Failed to load MIDI/audio files")
		return
	
	# Generate beat events
	var loaded_midi_resource: Resource = music_player.get_midi_resource()
	var tempo_map: Array = music_player.get_tempo_map()
	
	if loaded_midi_resource and tempo_map:
		midi_event_router.load_midi_data(loaded_midi_resource, tempo_map)
		var beat_events: Array = midi_event_router.generate_beat_events()
		_total_beats = beat_events.size()
		
		note_scheduler.initialize(beat_events)
		
		print("GameplayBase: Loaded %d beat events" % beat_events.size())
		
		# Initialize UIStateManager with total note count
		if ui_state_manager:
			ui_state_manager.initialize(beat_events.size(), level_config)
		
# Initialize Right UI with track info
	if right_ui:
		var track_name: String = "Track Name"
		var artist_name: String = "Artist"
		var duration_ms: float = 0.0
		
		if level_config:
			track_name = level_config.track_name
			artist_name = level_config.artist_name
		
		# Get audio duration in milliseconds
		if audio_stream and audio_stream is AudioStreamOggVorbis:
			duration_ms = audio_stream.get_length() * 1000.0
		elif audio_stream:
			# Fallback for other stream types
			duration_ms = audio_stream.get_length() * 1000.0
		
		right_ui.set_track_info(track_name, artist_name, duration_ms)
	
	# Start playback after a short delay
	await get_tree().create_timer(1.0).timeout
	music_player.start_playback()
	print("GameplayBase: Playback started!")
	
	# Fade out menu music quickly when level track starts (1s fade)
	MenuMusicManager.fade_out_menu_music(1.0)


func _process(_delta: float) -> void:
	"""Update Now Playing display and rhythm system every frame"""
	# Update NoteScheduler with current time
	if music_player and music_player.is_playing() and note_scheduler:
		note_scheduler.update(music_player.get_current_time_ms())
	
	if music_player and music_player.is_playing() and right_ui:
		right_ui.update_now_playing(music_player.get_current_time_ms())


func _connect_referee_signals() -> void:
	"""Connect Referee and UIStateManager signals to UI panels for real-time updates"""
	if referee == null:
		push_warning("Referee not found. UI will not update automatically.")
		return
	
	# Connect to left panel
	if referee.has_signal("score_changed"):
		referee.score_changed.connect(_on_score_changed)
	if referee.has_signal("combo_changed"):
		referee.combo_changed.connect(_on_combo_changed)
	
	# Connect Judge to UIStateManager
	if judge.has_signal("judgment_made"):
		judge.judgment_made.connect(_on_judgment_for_ui_state)
	
	# Connect UIStateManager to UI panels
	if ui_state_manager:
		ui_state_manager.resonance_updated.connect(left_ui.update_resonance)
		ui_state_manager.mask_collected.connect(right_ui.collect_mask)
		ui_state_manager.resonance_depleted.connect(_on_resonance_depleted)


func _connect_music_player_signals() -> void:
	"""Connect MusicPlayer signals for track completion detection"""
	if music_player and music_player.has_signal("playback_stopped"):
		music_player.playback_stopped.connect(_on_track_finished)


func _on_score_changed(score: int) -> void:
	"""Update left panel score display"""
	left_ui.set_score(score)


func _on_combo_changed(combo: int) -> void:
	"""Update left panel combo display"""
	left_ui.set_combo(combo)


func _on_player_input(action_name: String, input_time_ms: float) -> void:
	"""Handle player input and forward to Judge for timing evaluation"""
	if not music_player.is_playing():
		return
	
	var next_beat: BeatEvent = note_scheduler.get_next_beat()
	if next_beat != null:
		judge.judge_input(input_time_ms, next_beat, action_name)


func _on_judgment_for_ui_state(beat: BeatEvent, _offset_ms: float, rating: int) -> void:
	"""Forward judgment to UIStateManager for resonance tracking and show feedback"""
	# Show feedback in left panel
	if left_ui and left_ui.has_method("show_feedback"):
		left_ui.show_feedback(rating)
	
	# Show feedback at note target position
	if note_targets and note_targets.has_method("show_target_feedback"):
		var rating_text: String = HitRating.get_rating_name(rating)
		var rating_color: Color = HitRating.get_rating_color(rating)
		note_targets.show_target_feedback(beat.direction, rating_text, rating_color)
	
	# Update UIStateManager for resonance tracking
	if ui_state_manager:
		var combo: int = 0
		var score: int = 0
		if referee:
			var stats: Dictionary = referee.get_statistics()
			combo = stats.get("combo", 0)
			score = stats.get("score", 0)
		ui_state_manager.update_judgment(rating, combo, score)


func _on_judgment_for_note_hit(beat: BeatEvent, _offset_ms: float, rating: int) -> void:
	"""Forward successful hits to note spawner for visual feedback and check for veilshifts"""
	if rating != HitRating.Rating.MISS and note_spawner:
		note_spawner.on_note_hit(beat, rating)
	
	# Check if this was a veilshift note that was successfully hit
	if rating != HitRating.Rating.MISS and beat.velocity in VEILSHIFT_VELOCITY_TO_MASK:
		var mask_index: int = VEILSHIFT_VELOCITY_TO_MASK[beat.velocity]
		var mask_id: int = mask_index + 1  # Convert to 1-indexed for PlayerEffects
		
		print("GameplayBase: Veilshift hit! velocity=%d, mask_id=%d" % [beat.velocity, mask_id])
		
		# Transform player sprite
		if player_effects:
			player_effects.transform_veilshift(mask_id)
		# Note: PlayerEffects will emit veilshift_collected signal which triggers UI update


func _on_beat_missed(beat: BeatEvent) -> void:
	"""Handle missed beats - trigger visual feedback and update UI state"""
	# Notify Referee of the miss (this resets combo to 0)
	if referee:
		referee._on_judgment_made(beat, 0.0, HitRating.Rating.MISS)
	
	if note_spawner:
		note_spawner.on_note_missed(beat)
	
	# Show MISS feedback at note target
	if note_targets and note_targets.has_method("show_target_feedback"):
		note_targets.show_target_feedback(beat.direction, "MISS", HitRating.get_rating_color(HitRating.Rating.MISS))
	
	# Trigger flash effect when missed note hits player
	if player_effects:
		player_effects.flash_on_missed_hit()
	
	# Update UIStateManager with miss
	if ui_state_manager:
		var combo: int = 0
		var score: int = 0
		if referee:
			var stats: Dictionary = referee.get_statistics()
			combo = stats.get("combo", 0)
			score = stats.get("score", 0)
		ui_state_manager.update_judgment(HitRating.Rating.MISS, combo, score)


func _on_early_input_rejected(beat: BeatEvent, _offset_ms: float) -> void:
	"""Handle early input - trigger penalty visual"""
	if note_spawner:
		note_spawner.on_early_input(beat)


func _on_veilshift_collected(mask_id: int) -> void:
	"""Handle veilshift collection - update UI mask indicators"""
	var mask_index: int = mask_id - 1  # Convert from 1-indexed to 0-indexed
	
	if ui_state_manager and ui_state_manager.has_method("collect_mask"):
		ui_state_manager.collect_mask(mask_index)
		print("GameplayBase: Veilshift collected, UI updated (mask_index=%d)" % mask_index)


func _on_track_finished() -> void:
	"""Handle track completion - check win/loss conditions"""
	if _track_finished:
		return  # Already processed
	
	_track_finished = true
	
	print("GameplayBase: Track finished. Checking completion status...")
	
	if referee == null or _total_beats == 0:
		push_warning("Cannot determine level outcome - missing Referee or beat count")
		return
	
	var stats: Dictionary = referee.get_statistics()
	var miss_count: int = stats.get("miss", 0)
	var miss_rate: float = float(miss_count) / float(_total_beats)
	
	print("  Total beats: %d" % _total_beats)
	print("  Misses: %d" % miss_count)
	print("  Miss rate: %.1f%%" % (miss_rate * 100.0))
	print("  Threshold: %.1f%%" % (MISS_THRESHOLD_PERCENT * 100.0))
	
	if miss_rate < MISS_THRESHOLD_PERCENT:
		print("  Result: VICTORY!")
		level_won.emit(next_level_path)
	else:
		print("  Result: DEFEAT (too many misses)")
		level_lost.emit()


func _on_resonance_depleted() -> void:
	"""Handle level failure due to resonance depletion"""
	if _track_finished:
		return  # Already processed track completion
	
	_track_finished = true  # Prevent duplicate emissions
	
	print("GameplayBase: Resonance depleted - Level Failed!")
	music_player.stop_playback()
	level_lost.emit()


func get_spawn_point(note_name: String) -> Node2D:
	"""Get spawn point by note name (e.g., 'C4', 'D#4')"""
	var spawn_point: Node2D = spawn_points.get_node_or_null(note_name)
	if spawn_point == null:
		push_error("Spawn point not found: " + note_name)
	return spawn_point


func _action_to_direction(action_name: String) -> String:
	"""Convert action name to direction string for note targets"""
	match action_name:
		"action_up":
			return "up"
		"action_down":
			return "down"
		"action_left":
			return "left"
		"action_right":
			return "right"
	return ""


func get_scale_factor() -> Vector2:
	"""Get current viewport scale factor relative to base resolution"""
	return get_viewport().size / BASE_RESOLUTION
