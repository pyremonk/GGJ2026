extends Control

## Master volume control slider for quick volume adjustment
## Updates the Master audio bus volume in real-time

const MASTER_BUS_INDEX: int = 0
const MIN_DB: float = -40.0
const MAX_DB: float = 0.0

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_icon: Label = %VolumeIcon
@onready var mute_button: Button = %MuteButton
@onready var percent_label: Label = $Background/HBoxContainer/PercentLabel


func _ready() -> void:
	_setup_slider()
	_load_current_volume()
	_connect_signals()


func _setup_slider() -> void:
	"""Configure slider range to map to decibel values"""
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(MASTER_BUS_INDEX))


func _load_current_volume() -> void:
	"""Load current master volume from AudioServer"""
	var current_db: float = AudioServer.get_bus_volume_db(MASTER_BUS_INDEX)
	volume_slider.value = _db_to_linear(current_db)
	_update_mute_button()
	_update_percent_label(volume_slider.value)


func _connect_signals() -> void:
	"""Connect UI signals to handler functions"""
	volume_slider.value_changed.connect(_on_volume_changed)
	if mute_button:
		mute_button.pressed.connect(_on_mute_toggled)


func _on_volume_changed(value: float) -> void:
	"""Handle slider value changes and update master volume"""
	var db_value: float = _linear_to_db(value)
	AudioServer.set_bus_volume_db(MASTER_BUS_INDEX, db_value)
	AppSettings.set_bus_volume(MASTER_BUS_INDEX, value)
	_update_mute_button()
	_update_percent_label(value)


func _update_percent_label(value: float) -> void:
	"""Update the percentage label to show current volume"""
	if percent_label:
		var percent: int = roundi(value * 100.0)
		percent_label.text = str(percent) + "%"


func _on_mute_toggled() -> void:
	"""Toggle mute state"""
	var is_muted: bool = AudioServer.is_bus_mute(MASTER_BUS_INDEX)
	AudioServer.set_bus_mute(MASTER_BUS_INDEX, not is_muted)
	AppSettings.set_mute(not is_muted)
	_update_mute_button()


func _update_mute_button() -> void:
	"""Update mute button appearance based on mute state"""
	if not mute_button:
		return
	
	var is_muted: bool = AudioServer.is_bus_mute(MASTER_BUS_INDEX)
	mute_button.text = "🔇" if is_muted else "🔊"


func _linear_to_db(linear: float) -> float:
	"""Convert linear volume (0-1) to decibels"""
	if linear <= 0.0:
		return MIN_DB
	return clampf(linear_to_db(linear), MIN_DB, MAX_DB)


func _db_to_linear(db: float) -> float:
	"""Convert decibels to linear volume (0-1)"""
	if db <= MIN_DB:
		return 0.0
	return db_to_linear(db)
