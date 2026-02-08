@tool
extends OverlaidWindow

@export var options_menu_scene : PackedScene
## Path to a main menu scene.
## Will attempt to read from AppConfig if left empty.
@export_file("*.tscn") var main_menu_scene_path : String
@export_node_path(&"ConfirmationOverlaidWindow") var restart_confirmation_node_path : NodePath
@export_node_path(&"ConfirmationOverlaidWindow") var main_menu_confirmation_node_path : NodePath
@export_node_path(&"ConfirmationOverlaidWindow") var exit_confirmation_node_path : NodePath
@export var menu_container_node_path : NodePath = ^".."

@onready var restart_confirmation : ConfirmationOverlaidWindow = get_node(restart_confirmation_node_path)
@onready var main_menu_confirmation : ConfirmationOverlaidWindow = get_node(main_menu_confirmation_node_path)
@onready var exit_confirmation : ConfirmationOverlaidWindow = get_node(exit_confirmation_node_path)
@onready var menu_container : Node = get_node(menu_container_node_path)
@onready var main_menu_button = %MainMenuButton
@onready var exit_button = %ExitButton

var _open_window : Node
var _ignore_first_cancel : bool = false

func get_main_menu_scene_path() -> String:
	if main_menu_scene_path.is_empty():
		return AppConfig.main_menu_scene_path
	return main_menu_scene_path

func close() -> void:
	"""Override to always unpause when resuming from pause menu"""
	if not visible:
		return
	# Always unpause when closing the pause menu (Resume button)
	_scene_tree.paused = false
	# Restore mouse mode
	Input.set_mouse_mode(_initial_mouse_mode)
	# Restore focus
	if is_instance_valid(_initial_focus_control) and _initial_focus_control.is_inside_tree():
		_initial_focus_control.focus_mode = _initial_focus_mode
		_initial_focus_control.grab_focus()
	# Clean up exclusive control node
	if _exclusive_control_node:
		_exclusive_control_node.queue_free()
	# Hide window and emit signals (from WindowContainer.close())
	hide()
	closed.emit()

func close_window() -> void:
	if _open_window != null:
		if _open_window.has_method("close"):
			_open_window.close()
		else:
			_open_window.hide()
		_open_window = null

func _disable_focus() -> void:
	for child in %MenuButtons.get_children():
		if child is Control:
			child.focus_mode = FOCUS_NONE

func _enable_focus() -> void:
	for child in %MenuButtons.get_children():
		if child is Control:
			child.focus_mode = FOCUS_ALL

func _load_scene(scene_path: String) -> void:
	_scene_tree.paused = false
	SceneLoader.load_scene(scene_path)

func _show_window(window : Control) -> void:
	_disable_focus.call_deferred()
	window.open_window()
	_open_window = window
	await window.hidden
	_open_window = null
	_enable_focus.call_deferred()

func _load_and_show_menu(scene : PackedScene) -> void:
	var window_instance : Control = scene.instantiate()
	window_instance.visible = false
	menu_container.add_child.call_deferred(window_instance)
	await _show_window(window_instance)
	window_instance.queue_free()

func _handle_cancel_input() -> void:
	if _ignore_first_cancel:
		_ignore_first_cancel = false
		return
	if _open_window != null:
		close_window()
	else:
		super._handle_cancel_input()

func display_window() -> void:
	super.open_window()
	if Input.is_action_pressed("ui_cancel"):
		_ignore_first_cancel = true

func _refresh_exit_button() -> void:
	exit_button.visible = false

func _refresh_options_button() -> void:
	pass

func _refresh_main_menu_button() -> void:
	main_menu_button.visible = !get_main_menu_scene_path().is_empty()

func _ready() -> void:
	_refresh_exit_button()
	_refresh_options_button()
	_refresh_main_menu_button()
	restart_confirmation.confirmed.connect(_on_restart_confirmation_confirmed)
	main_menu_confirmation.confirmed.connect(_on_main_menu_confirmation_confirmed)
	exit_confirmation.confirmed.connect(_on_exit_confirmation_confirmed)

func _on_restart_button_pressed() -> void:
	_show_window(restart_confirmation)

func _on_options_button_pressed() -> void:
	pass

func _on_main_menu_button_pressed() -> void:
	_show_window(main_menu_confirmation)

func _on_exit_button_pressed() -> void:
	_show_window(exit_confirmation)

func _on_restart_confirmation_confirmed() -> void:
	SceneLoader.reload_current_scene()
	close()

func _on_main_menu_confirmation_confirmed():
	# Immediately unpause the tree before loading the main menu
	get_tree().paused = false
	SceneLoader.load_scene(get_main_menu_scene_path())

func _on_exit_confirmation_confirmed():
	get_tree().quit()
