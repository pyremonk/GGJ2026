extends CanvasLayer

@onready var pause_menu = %PauseMenu

func _on_pause_menu_hidden():
	hide()

func _on_visibility_changed():
	if visible:
		if pause_menu.has_method("display_window"):
			pause_menu.display_window()
		elif pause_menu.has_method("open_window"):
			pause_menu.open_window()
		else:
			pause_menu.show()

func _ready():
	visibility_changed.connect(_on_visibility_changed)
