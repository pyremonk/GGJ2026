extends LevelManager

func set_current_level_path(value: String) -> void:
	super.set_current_level_path(value)
	GameState.set_current_level_path(value)

func set_checkpoint_level_path(value: String) -> void:
	super.set_checkpoint_level_path(value)
	GameState.set_checkpoint_level_path(value)

func get_checkpoint_level_path() -> String:
	var state_level_path: String = GameState.get_checkpoint_level_path()
	if not state_level_path.is_empty():
		return state_level_path
	return super.get_checkpoint_level_path()

func _load_level_won_screen_or_next_level(next_level_path: String = "") -> void:
	"""Override to properly handle next level progression"""
	if level_won_scene:
		var instance = level_won_scene.instantiate()
		get_tree().current_scene.add_child(instance)
		
		# Determine the next level to load
		var level_to_load: String = next_level_path
		if level_to_load.is_empty():
			level_to_load = get_next_level_path()
		
		# If there's a next level, connect Continue to load it
		if not level_to_load.is_empty():
			_try_connecting_signal_to_node(instance, &"continue_pressed", func(): load_level(level_to_load))
		else:
			# No next level - Continue goes to ending or main menu
			_try_connecting_signal_to_node(instance, &"continue_pressed", _load_win_screen_or_ending)
		
		_try_connecting_signal_to_node(instance, &"restart_pressed", _reload_level)
		_try_connecting_signal_to_node(instance, &"main_menu_pressed", _load_main_menu)
		
		# Note: Level selection button will be added when level picker is implemented
	else:
		# No won scene - load next level directly
		if not next_level_path.is_empty():
			load_level(next_level_path)
		else:
			var next_level: String = get_next_level_path()
			if not next_level.is_empty():
				load_level(next_level)
			else:
				_load_win_screen_or_ending()
