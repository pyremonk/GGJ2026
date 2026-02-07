extends "res://scripts/core/menus/mini_options_menu.gd"

func _on_reset_game_control_reset_confirmed() -> void:
	GameState.reset()
