extends Node

signal level_lost
signal level_won(level_path: String)

## Optional path to the next level if using an open world level system.
@export_file("*.tscn") var next_level_path: String

var level_state: LevelState

func _ready() -> void:
	level_state = GameState.get_level_state(scene_file_path)
	%ColorPickerButton.color = level_state.color
	%BackgroundColor.color = level_state.color
	if not level_state.tutorial_read:
		open_tutorials()
	
	# Connect gameplay_base signals if it exists
	_connect_gameplay_signals()


func _connect_gameplay_signals() -> void:
	"""Connect gameplay_base level outcome signals"""
	var gameplay_base: Node = get_node_or_null("%GameplayBase")
	if gameplay_base == null:
		return
	
	if gameplay_base.has_signal("level_won"):
		gameplay_base.level_won.connect(_on_gameplay_level_won)
	if gameplay_base.has_signal("level_lost"):
		gameplay_base.level_lost.connect(_on_gameplay_level_lost)


func _on_gameplay_level_won(next_level: String) -> void:
	"""Forward level_won signal from gameplay_base"""
	level_won.emit(next_level if not next_level.is_empty() else next_level_path)


func _on_gameplay_level_lost() -> void:
	"""Forward level_lost signal from gameplay_base"""
	level_lost.emit()


func open_tutorials() -> void:
	%TutorialManager.open_tutorials()
	level_state.tutorial_read = true
	GlobalState.save()


func _on_color_picker_button_color_changed(color: Color) -> void:
	%BackgroundColor.color = color
	level_state.color = color
	GlobalState.save()


func _on_tutorial_button_pressed() -> void:
	open_tutorials()
