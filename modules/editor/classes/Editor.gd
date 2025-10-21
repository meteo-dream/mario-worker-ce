extends Node

enum MODE {
	NONE,
	EDITOR,
	TESTING
}
const config_path = "user://editor_config.thss"

var camera: Camera2D:
	get():
		if is_instance_valid(camera): return camera
		return null
var scene: LevelEditor:
	get():
		if is_instance_valid(scene): return scene
		return null
var current_level: LevelEdited:
	set(to):
		current_level = to
		#Scenes.current_scene = to
	get():
		if is_instance_valid(current_level): return current_level
		return null
var current_level_properties: LevelProperties:
	set(to):
		if !to:
			current_level_properties = LevelProperties.new()
			return
		current_level_properties = to
var gui: Control:
	get():
		if is_instance_valid(gui): return gui
		return null

var mode: int = MODE.NONE

var default_config: Dictionary = {
	lang = "",
	editor_sounds = true,
	editor_scale = 0.0,
	grid_size_x = 16,
	grid_size_y = 16,
	grid_offset_x = 0,
	grid_offset_y = 0,
	grid_primary_line_x = 2,
	grid_primary_line_y = 2,
	editor_options = {
		erase_with_rmb = false,
		erase_specific_object = true,
	}
}
var config: Dictionary = default_config.duplicate(true)
var grid_shown: bool = true
var grid_size: Vector2
var grid_offset: Vector2
var editor_scale: float = 1.0
var screen_size := Vector2i(640, 480)

var level_path: String
var is_loading: bool = false

func _ready() -> void:
	get_window().min_size = Vector2(800, 480)
	if !DirAccess.dir_exists_absolute("user://User Data/Levels"):
		DirAccess.make_dir_recursive_absolute("user://User Data/Levels")
	load_config()
	process_loaded_config()


func get_group_property(group_name: StringName, property: StringName) -> bool:
	var res: bool
	for i in get_tree().get_nodes_in_group(group_name):
		if i.get(property): res = true
	return res

func find_child_by_type(parent: Node, type) -> Node:
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
		var grandchild = find_child_by_type(child, type)
		if grandchild != null:
			return grandchild
	return null

func is_window_active() -> bool:
	var res: bool = true
	var _win = DisplayServer.window_get_active_popup()
	if _win != -1: res = false
	if !DisplayServer.window_is_focused(0): res = false
	return res

func show_window(dialog: Window) -> void:
	if dialog.visible:
		if dialog.mode == Window.MODE_MINIMIZED:
			dialog.mode = Window.MODE_WINDOWED
		dialog.grab_focus()
		return
	dialog.show()
	if dialog.content_scale_factor != editor_scale:
		dialog.content_scale_factor = editor_scale
		dialog.size *= editor_scale
		dialog.min_size *= editor_scale
		var usable_size = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen(0)).size
		if dialog.size.y > usable_size.y:
			dialog.size.y = usable_size.y
		if dialog.size.x > usable_size.x:
			dialog.size.x = usable_size.x
		dialog.move_to_center()
		#await get_tree().physics_frame
		#dialog.position = (
		#	(dialog.position) - (dialog.size / 2)
		#)


func set_game_screen_size(to: Vector2i) -> void:
	screen_size = to
	GlobalViewport.vp.size = to
	GlobalViewport.center_container.ratio = float(to.x) / float(to.y)
	SettingsManager._window_scale_logic(true)


## Loads the settings variable from file
func load_config() -> void:
	var loaded_data: Dictionary = SettingsManager.load_data(config_path, "EditorConfig")
	if loaded_data.is_empty():
		return

	config = loaded_data
	_check_for_validity()
	print("[Editor] Loaded editor config from a file.")

## Saves the tweaks variable to a file
func save_config() -> void:
	SettingsManager.save_data(config, config_path, "EditorConfig")
	print("[Editor] Editor config saved!")

func process_loaded_config() -> void:
	var current_screen := DisplayServer.window_get_current_screen(get_window().get_window_id())
	var non_windows_scale := DisplayServer.screen_get_scale(current_screen)
	if Editor.config.editor_scale < 0.5:
		if OS.get_name() != "Windows":
			Editor.config.editor_scale = non_windows_scale
		elif DisplayServer.screen_get_dpi(current_screen) > 120:
			Editor.config.editor_scale = 2.0
	
	var _scr_size: Vector2i = DisplayServer.screen_get_size(current_screen)
	if (Editor.config.editor_scale >= 2.0 && 
		_scr_size.x >= 1920 && _scr_size.y >= 1080
	):
		get_window().min_size = Vector2i(1600, 800)
		get_window().size = Vector2i(1920, 1080)
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().position = (
			(_scr_size / 2) - (get_window().size / 2)
		)
	
	if Editor.config.editor_scale >= 0.5:
		get_window().content_scale_factor = Editor.config.editor_scale
		editor_scale = Editor.config.editor_scale
		ProjectSettings.set_setting("display/window/stretch/scale", Editor.config.editor_scale)


func _check_for_validity() -> void:
	for i in default_config.keys():
		if !i in config:
			config[i] = default_config[i]
			continue
		if config[i] is Dictionary && default_config.get(i):
			for j in default_config[i].keys():
				if !j in config[i]:
					config[i][j] = default_config[i][j]
					print("[EditorConfig] Restored %s in dict %s" % [j, i])
