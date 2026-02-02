extends Node

## Temporary gameplay manager for GGJ2026 deadline
## Handles pause input, window instantiation, and level flow
## Attached as child node to GameplayLevel Control nodes

const TEMP_MAIN_MENU_PATH: String = "res://scenes/temp_main_menu.tscn"
const PAUSE_MENU_LAYER_PATH: String = "res://scenes/windows/pause_menu_layer.tscn"
const LEVEL_WON_WINDOW_PATH: String = "res://scenes/windows/level_won_window.tscn"
const LEVEL_LOST_WINDOW_PATH: String = "res://scenes/windows/level_lost_window.tscn"

const LEVEL_1_PATH: String = "res://scenes/game_scene/levels/gameplay_level_1.tscn"
const LEVEL_2_PATH: String = "res://scenes/game_scene/levels/gameplay_level_2.tscn"
const LEVEL_3_PATH: String = "res://scenes/game_scene/levels/gameplay_level_3.tscn"

var _pause_layer: CanvasLayer = null
var _music_player: Node = null
var _gameplay_base: Node = null
var _next_level_path: String = ""
var _should_stay_paused: bool = false  # Track if we want to stay paused after menu closes


func _ready() -> void:
	_find_gameplay_base()
	_find_music_player()
	_connect_level_signals()
	
	# Set process mode to allow handling input when paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _find_gameplay_base() -> void:
	"""Find the GameplayBase node (sibling)"""
	var parent: Node = get_parent()
	if not parent:
		push_error("TempGameplayManager: No parent node")
		return
	
	_gameplay_base = parent.get_node_or_null("GameplayBase")
	if not _gameplay_base:
		push_error("TempGameplayManager: Could not find GameplayBase node")


func _find_music_player() -> void:
	"""Find MusicPlayer node in GameplayBase"""
	if not _gameplay_base:
		return
	
	_music_player = _gameplay_base.find_child("MusicPlayer", true, false)
	if not _music_player:
		push_error("TempGameplayManager: Could not find MusicPlayer node")


func _connect_level_signals() -> void:
	"""Connect to level outcome signals from level script"""
	# The level.gd script is on the parent Control node
	var level_node: Node = get_parent()
	if not level_node:
		return
	
	if level_node.has_signal("level_won"):
		level_node.level_won.connect(_on_level_won)
	
	if level_node.has_signal("level_lost"):
		level_node.level_lost.connect(_on_level_lost)


func _unhandled_input(event: InputEvent) -> void:
	"""Handle ESC key for pause menu"""
	if event.is_action_pressed("ui_cancel"):
		# Toggle between paused and unpaused
		if _pause_layer:
			# Pause menu is open - close it properly to unpause
			_should_stay_paused = false
			var pause_menu: Node = _pause_layer.get_node_or_null("%PauseMenu")
			if pause_menu and pause_menu.has_method("close"):
				pause_menu.close()
			else:
				# Fallback if we can't find the pause menu
				_pause_layer.hide()
		else:
			# No pause menu - open it and pause
			_pause_game()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	"""Toggle pause state and show/hide pause menu"""
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	"""Pause the game and show pause menu"""
	if _pause_layer:
		# Already paused
		return
	
	# Pause music playback
	if _music_player and _music_player.has_method("pause_playback"):
		_music_player.pause_playback()
	
	# Set tree to paused BEFORE showing the menu
	# The pause menu will save this as initial_pause_state
	get_tree().paused = true
	_should_stay_paused = true
	
	# Instantiate and show pause menu layer
	var pause_scene: PackedScene = load(PAUSE_MENU_LAYER_PATH) as PackedScene
	if pause_scene:
		_pause_layer = pause_scene.instantiate() as CanvasLayer
		_pause_layer.visible = true  # Ensure it's visible
		add_child(_pause_layer)
		
		# Override the pause menu's main menu path to use our temp main menu
		var pause_menu: Node = _pause_layer.get_node_or_null("%PauseMenu")
		if pause_menu:
			if "main_menu_scene_path" in pause_menu:
				pause_menu.main_menu_scene_path = TEMP_MAIN_MENU_PATH
			
			if pause_menu.has_signal("hidden"):
				pause_menu.hidden.connect(_on_pause_menu_hidden)
			
			# Force show the pause menu
			if pause_menu.has_method("show"):
				pause_menu.show()


func _resume_game() -> void:
	"""Resume the game and hide pause menu"""
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	
	# Resume music playback
	if _music_player and _music_player.has_method("resume_playback"):
		_music_player.resume_playback()
	
	# Unpause tree
	get_tree().paused = false


func _on_pause_menu_hidden() -> void:
	"""Handle pause menu being hidden (user pressed resume or closed it)"""
	# Clean up pause layer
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	
	# Resume music if the game is not paused (Resume button was pressed)
	# The pause menu's close() already unpaused the tree when Resume was clicked
	if not get_tree().paused:
		# Resume button was clicked - unpause and resume music
		if _music_player and _music_player.has_method("resume_playback"):
			_music_player.resume_playback()
		_should_stay_paused = false


func _on_level_won(next_level_path: String) -> void:
	"""Handle level won outcome"""
	_next_level_path = _override_next_level_path(next_level_path)
	
	# Stop music
	if _music_player and _music_player.has_method("stop_playback"):
		_music_player.stop_playback()
	
	# Show level won window
	var won_scene: PackedScene = load(LEVEL_WON_WINDOW_PATH) as PackedScene
	if won_scene:
		var won_window: Node = won_scene.instantiate()
		add_child(won_window)
		
		# Connect signals
		if won_window.has_signal("continue_pressed"):
			won_window.continue_pressed.connect(_on_won_continue_pressed)
		if won_window.has_signal("main_menu_pressed"):
			won_window.main_menu_pressed.connect(_on_won_main_menu_pressed)
		if won_window.has_signal("restart_pressed"):
			won_window.restart_pressed.connect(_on_won_restart_pressed)


func _on_level_lost() -> void:
	"""Handle level lost outcome"""
	# Stop music
	if _music_player and _music_player.has_method("stop_playback"):
		_music_player.stop_playback()
	
	# Show level lost window
	var lost_scene: PackedScene = load(LEVEL_LOST_WINDOW_PATH) as PackedScene
	if lost_scene:
		var lost_window: Node = lost_scene.instantiate()
		add_child(lost_window)
		
		# Connect signals
		if lost_window.has_signal("restart_pressed"):
			lost_window.restart_pressed.connect(_on_lost_restart_pressed)
		if lost_window.has_signal("main_menu_pressed"):
			lost_window.main_menu_pressed.connect(_on_lost_main_menu_pressed)


func _override_next_level_path(original_path: String) -> String:
	"""Override next level path so level 3 goes to level 1"""
	# Check current scene to determine override
	var current_scene_path: String = get_tree().current_scene.scene_file_path
	
	if current_scene_path == LEVEL_3_PATH:
		return LEVEL_1_PATH  # Level 3 -> Level 1
	
	return original_path  # Use original path for levels 1 and 2


func _on_won_continue_pressed() -> void:
	"""Handle continue (next level) from won window"""
	if _next_level_path.is_empty():
		# No next level, go to main menu
		SceneLoader.load_scene(TEMP_MAIN_MENU_PATH)
	else:
		SceneLoader.load_scene(_next_level_path)


func _on_won_main_menu_pressed() -> void:
	"""Handle main menu button from won window"""
	SceneLoader.load_scene(TEMP_MAIN_MENU_PATH)


func _on_won_restart_pressed() -> void:
	"""Handle restart button from won window"""
	SceneLoader.reload_current_scene()


func _on_lost_restart_pressed() -> void:
	"""Handle restart button from lost window"""
	SceneLoader.reload_current_scene()


func _on_lost_main_menu_pressed() -> void:
	"""Handle main menu button from lost window"""
	SceneLoader.load_scene(TEMP_MAIN_MENU_PATH)
