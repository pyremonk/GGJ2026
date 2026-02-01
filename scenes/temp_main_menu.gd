extends Control

## Temporary main menu for Global Game Jam 2026 deadline
## Bypasses the template menu system for simplified level access

const LEVEL_1_PATH: String = "res://scenes/game_scene/levels/gameplay_level_1.tscn"
const LEVEL_2_PATH: String = "res://scenes/game_scene/levels/gameplay_level_2.tscn"
const LEVEL_3_PATH: String = "res://scenes/game_scene/levels/gameplay_level_3.tscn"

@onready var level_1_button: Button = %Level1Button
@onready var level_2_button: Button = %Level2Button
@onready var level_3_button: Button = %Level3Button
@onready var background_music_player: AudioStreamPlayer = $BackgroundMusicPlayer


func _ready() -> void:
	_load_level_names()
	_connect_buttons()
	_register_menu_music()


func _load_level_names() -> void:
	"""Load level names from each level's GameplayBase level_config"""
	level_1_button.text = _get_level_name_from_scene(LEVEL_1_PATH)
	level_2_button.text = _get_level_name_from_scene(LEVEL_2_PATH)
	level_3_button.text = _get_level_name_from_scene(LEVEL_3_PATH)


func _get_level_name_from_scene(scene_path: String) -> String:
	"""Extract level name from a gameplay level's config"""
	var level_scene: PackedScene = load(scene_path) as PackedScene
	if not level_scene:
		push_warning("TempMainMenu: Failed to load scene: " + scene_path)
		return "Unknown Level"
	
	var level_instance: Node = level_scene.instantiate()
	if not level_instance:
		push_warning("TempMainMenu: Failed to instantiate scene: " + scene_path)
		return "Unknown Level"
	
	# Find GameplayBase child node
	var gameplay_base: Node = level_instance.find_child("GameplayBase", true, false)
	if not gameplay_base:
		level_instance.queue_free()
		push_warning("TempMainMenu: No GameplayBase found in scene: " + scene_path)
		return "Unknown Level"
	
	# Get level_config from GameplayBase
	if not "level_config" in gameplay_base:
		level_instance.queue_free()
		push_warning("TempMainMenu: No level_config in GameplayBase: " + scene_path)
		return "Unknown Level"
	
	var level_config: LevelConfig = gameplay_base.get("level_config") as LevelConfig
	level_instance.queue_free()
	
	if not level_config:
		push_warning("TempMainMenu: level_config is null: " + scene_path)
		return "Unknown Level"
	
	return level_config.level_name if not level_config.level_name.is_empty() else "Unknown Level"


func _connect_buttons() -> void:
	"""Connect button signals to load respective levels"""
	if level_1_button:
		level_1_button.pressed.connect(_on_level_1_button_pressed)
	if level_2_button:
		level_2_button.pressed.connect(_on_level_2_button_pressed)
	if level_3_button:
		level_3_button.pressed.connect(_on_level_3_button_pressed)


func _on_level_1_button_pressed() -> void:
	SceneLoader.load_scene(LEVEL_1_PATH)


func _on_level_2_button_pressed() -> void:
	SceneLoader.load_scene(LEVEL_2_PATH)


func _on_level_3_button_pressed() -> void:
	SceneLoader.load_scene(LEVEL_3_PATH)


func _register_menu_music() -> void:
	"""Register the background music player with MenuMusicManager"""
	if background_music_player:
		MenuMusicManager.register_menu_music_player(background_music_player)
	else:
		push_warning("TempMainMenu: BackgroundMusicPlayer not found")
