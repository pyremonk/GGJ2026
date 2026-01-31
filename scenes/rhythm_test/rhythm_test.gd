extends Control

## Main test scene for rhythm game architecture.
## Coordinates all components and provides configuration UI.

const FLYING_BEAT_INDICATOR_SCRIPT: String = "res://scripts/ui/FlyingBeatIndicator.gd"

@onready var music_player: Node = %MusicPlayer
@onready var midi_router: Node = %MIDIEventRouter
@onready var note_scheduler: Node = %NoteScheduler
@onready var player_input: Node = %PlayerInput
@onready var judge: Node = %Judge
@onready var referee: Node = %Referee
@onready var latency_calibration: Node = %LatencyCalibration

@onready var beat_indicator_container: Control = $UI/BeatIndicatorContainer
@onready var feedback_display: Label = %FeedbackDisplay
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var debug_label: Label = %DebugLabel
@onready var audio_delay_label: Label = %AudioDelayLabel
@onready var beat_count_label: Label = %BeatCountLabel
@onready var completed_beats_label: Label = %CompletedBeatsLabel
@onready var lookahead_label: Label = %LookaheadLabel

@onready var audio_file_button: Button = %AudioFileButton
@onready var midi_file_button: Button = %MIDIFileButton
@onready var subdivision_option: OptionButton = %SubdivisionOption
@onready var start_button: Button = %StartButton
@onready var calibrate_button: Button = %CalibrateButton
@onready var delay_decrease_button: Button = %DelayDecreaseButton
@onready var delay_increase_button: Button = %DelayIncreaseButton
@onready var lookahead_decrease_button: Button = %LookaheadDecreaseButton
@onready var lookahead_increase_button: Button = %LookaheadIncreaseButton

@onready var calibration_ui: CanvasLayer = %CalibrationUI
@onready var instruction_label: Label = %InstructionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var result_label: Label = %ResultLabel

@onready var audio_file_dialog: FileDialog = %AudioFileDialog
@onready var midi_file_dialog: FileDialog = %MIDIFileDialog

var _audio_stream: AudioStream = null
var _midi_file_path: String = ""
var _is_playing: bool = false
var _total_beats_rendered: int = 0
var _total_beats_in_song: int = 0
var _completed_beats: int = 0

func _ready() -> void:
	_connect_signals()
	_setup_ui()
	_load_default_files()
	
	# Connect PlayerInput to MusicPlayer for song-relative timing
	player_input.set_music_player(music_player)

func _connect_signals() -> void:
	player_input.input_pressed.connect(_on_player_input)
	judge.judgment_made.connect(referee._on_judgment_made)
	judge.judgment_made.connect(_on_judgment_made)
	referee.score_changed.connect(_on_score_changed)
	referee.combo_changed.connect(_on_combo_changed)
	note_scheduler.upcoming_beat.connect(_on_upcoming_beat)
	note_scheduler.beat_missed.connect(_on_beat_missed)
	
	latency_calibration.calibration_beat.connect(_on_calibration_beat)
	latency_calibration.calibration_complete.connect(_on_calibration_complete)
	
	audio_file_button.pressed.connect(_on_audio_file_button_pressed)
	midi_file_button.pressed.connect(_on_midi_file_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	calibrate_button.pressed.connect(_on_calibrate_button_pressed)
	delay_decrease_button.pressed.connect(_on_delay_decrease_pressed)
	delay_increase_button.pressed.connect(_on_delay_increase_pressed)
	lookahead_decrease_button.pressed.connect(_on_lookahead_decrease_pressed)
	lookahead_increase_button.pressed.connect(_on_lookahead_increase_pressed)
	
	audio_file_dialog.file_selected.connect(_on_audio_file_selected)
	midi_file_dialog.file_selected.connect(_on_midi_file_selected)

func _setup_ui() -> void:
	subdivision_option.clear()
	subdivision_option.add_item("Quarter Notes", 4)
	subdivision_option.add_item("Eighth Notes", 8)
	subdivision_option.selected = 0
	
	calibration_ui.visible = false
	start_button.disabled = true
	
	score_label.text = "Score: 0"
	combo_label.text = "Combo: 0"
	debug_label.text = "Next beat: --"
	audio_delay_label.text = "Audio Delay: %.0fms" % music_player.audio_delay_ms
	beat_count_label.text = "Beats Rendered: 0 / 0"
	completed_beats_label.text = "Beats Completed: 0"
	lookahead_label.text = "Lookahead: %.0fms" % note_scheduler.lookahead_ms

func _load_default_files() -> void:
	var default_audio_path: String = "res://assets/testing_track/Testing_Track.ogg"
	var default_midi_path: String = "res://assets/testing_track/Testing_Track.mid"
	
	if FileAccess.file_exists(default_audio_path):
		_audio_stream = load(default_audio_path)
		audio_file_button.text = "Audio: Testing_Track.ogg"
	
	if FileAccess.file_exists(default_midi_path):
		_midi_file_path = default_midi_path
		midi_file_button.text = "MIDI: Testing_Track.mid"
	
	_check_files_ready()

func _check_files_ready() -> void:
	start_button.disabled = (_audio_stream == null or _midi_file_path.is_empty())

func _on_audio_file_button_pressed() -> void:
	audio_file_dialog.popup_centered()

func _on_midi_file_button_pressed() -> void:
	midi_file_dialog.popup_centered()

func _on_audio_file_selected(path: String) -> void:
	_audio_stream = load(path)
	if _audio_stream != null:
		var filename: String = path.get_file()
		audio_file_button.text = "Audio: " + filename
	else:
		audio_file_button.text = "Audio: ERROR"
	_check_files_ready()

func _on_midi_file_selected(path: String) -> void:
	_midi_file_path = path
	var filename: String = path.get_file()
	midi_file_button.text = "MIDI: " + filename
	_check_files_ready()

func _on_start_button_pressed() -> void:
	if _is_playing:
		_stop_playback()
	else:
		_start_playback()

func _start_playback() -> void:
	if not music_player.load_files(_audio_stream, _midi_file_path):
		push_error("RhythmTest: Failed to load files")
		return
	
	var selected_subdivision: int = subdivision_option.get_item_id(subdivision_option.selected)
	midi_router.beat_subdivision = selected_subdivision
	
	print("=== Starting Playback ===")
	print("Beat subdivision: ", selected_subdivision)
	
	var tempo_map: Array = music_player.get_tempo_map()
	print("Tempo map received: ", tempo_map)
	
	var midi_resource: Resource = music_player.get_midi_resource()
	print("MIDI resource: ", midi_resource)
	
	midi_router.load_midi_data(midi_resource, tempo_map)
	var beat_events: Array[BeatEvent] = midi_router.generate_beat_events()
	
	print("Beat events generated: ", beat_events.size())
	
	if beat_events.is_empty():
		push_error("RhythmTest: No beat events generated")
		return
	
	# Debug: Print timing information
	if beat_events.size() > 0:
		print("First beat at: %.0fms" % beat_events[0].hit_time_ms)
		print("Last beat at: %.0fms" % beat_events[-1].hit_time_ms)
		if _audio_stream != null:
			var audio_length_ms: float = _audio_stream.get_length() * 1000.0
			print("Audio length: %.0fms" % audio_length_ms)
			print("Last beat needs scheduling by: %.0fms" % (beat_events[-1].hit_time_ms - note_scheduler.lookahead_ms))
	
	_total_beats_in_song = beat_events.size()
	_total_beats_rendered = 0
	_completed_beats = 0
	
	note_scheduler.initialize(beat_events)
	referee.reset()
	
	music_player.start_playback()
	_is_playing = true
	start_button.text = "Stop"

func _stop_playback() -> void:
	music_player.stop_playback()
	_is_playing = false
	start_button.text = "Start"
	note_scheduler.reset()

func _process(delta: float) -> void:
	if _is_playing:
		var current_time_ms: float = music_player.get_current_time_ms()
		note_scheduler.update(current_time_ms)
		
		# Debug: Show offset from next beat
		var next_beat: BeatEvent = note_scheduler.get_next_beat()
		if next_beat != null:
			var offset_from_beat: float = next_beat.hit_time_ms - current_time_ms
			debug_label.text = "Next beat in: %.0fms" % offset_from_beat
		else:
			debug_label.text = "No more beats"
		
		# Update beat count label
		beat_count_label.text = "Beats Rendered: %d / %d" % [_total_beats_rendered, _total_beats_in_song]
		completed_beats_label.text = "Beats Completed: %d" % _completed_beats
	else:
		debug_label.text = "Next beat: --"
		beat_count_label.text = "Beats Rendered: 0 / 0"
		completed_beats_label.text = "Beats Completed: 0"

func _on_player_input(action_name: String, input_time_ms: float) -> void:
	if latency_calibration.is_calibrating():
		latency_calibration._on_player_tap(input_time_ms)
		return
	
	if not _is_playing:
		return
	
	var next_beat: BeatEvent = note_scheduler.get_next_beat()
	if next_beat != null:
		judge.judge_input(input_time_ms, next_beat, action_name)

func _on_judgment_made(beat: BeatEvent, offset_ms: float, rating: HitRating.Rating) -> void:
	feedback_display.show_feedback(offset_ms, rating)

func _on_beat_missed(beat: BeatEvent) -> void:
	# Automatically register a miss if beat passed without input
	var miss_offset_ms: float = 1000.0  # Arbitrary large offset to show it's a miss
	feedback_display.show_feedback(miss_offset_ms, HitRating.Rating.MISS)
	referee._on_judgment_made(beat, miss_offset_ms, HitRating.Rating.MISS)

func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d" % score

func _on_combo_changed(combo: int) -> void:
	combo_label.text = "Combo: %d" % combo

func _on_upcoming_beat(beat: BeatEvent) -> void:
	var current_time_ms: float = music_player.get_current_time_ms()
	
	# Spawn a new flying beat indicator for this beat
	var flying_indicator: Control = Control.new()
	var script: GDScript = load(FLYING_BEAT_INDICATOR_SCRIPT)
	flying_indicator.set_script(script)
	beat_indicator_container.add_child(flying_indicator)
	
	# Initialize the flying indicator with beat timing and music player reference
	flying_indicator.initialize(beat.hit_time_ms, current_time_ms, music_player)
	
	# Connect to beat completion signal
	flying_indicator.beat_visual_complete.connect(_on_beat_visual_complete)
	
	# Track total beats rendered
	_total_beats_rendered += 1

func _on_beat_visual_complete() -> void:
	_completed_beats += 1

func _on_calibrate_button_pressed() -> void:
	calibration_ui.visible = true
	instruction_label.text = "Tap RIGHT ARROW on each beat"
	progress_label.text = "Beat 0/%d" % latency_calibration.num_calibration_beats
	result_label.text = ""
	latency_calibration.start_calibration()

func _on_calibration_beat(beat_number: int) -> void:
	progress_label.text = "Beat %d/%d" % [beat_number + 1, latency_calibration.num_calibration_beats]

func _on_calibration_complete(offset_ms: float) -> void:
	result_label.text = "Offset: %.0fms" % offset_ms
	judge.set_latency_offset(offset_ms)
	
	await get_tree().create_timer(2.0).timeout
	calibration_ui.visible = false

func _on_delay_decrease_pressed() -> void:
	music_player.audio_delay_ms -= 100.0
	audio_delay_label.text = "Audio Delay: %.0fms" % music_player.audio_delay_ms

func _on_delay_increase_pressed() -> void:
	music_player.audio_delay_ms += 100.0
	audio_delay_label.text = "Audio Delay: %.0fms" % music_player.audio_delay_ms

func _on_lookahead_decrease_pressed() -> void:
	note_scheduler.lookahead_ms -= 500.0
	note_scheduler.lookahead_ms = maxf(note_scheduler.lookahead_ms, 0.0)
	lookahead_label.text = "Lookahead: %.0fms" % note_scheduler.lookahead_ms

func _on_lookahead_increase_pressed() -> void:
	note_scheduler.lookahead_ms += 500.0
	lookahead_label.text = "Lookahead: %.0fms" % note_scheduler.lookahead_ms
