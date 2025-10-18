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
	"lang": "",
	"editor_sounds": true,
	"grid_size_x": 16,
	"grid_size_y": 16,
	"grid_offset_x": 0,
	"grid_offset_y": 0,
	"grid_primary_line_x": 2,
	"grid_primary_line_y": 2,
}
var config: Dictionary = default_config.duplicate(true)
var grid_shown: bool = true
var grid_size: Vector2
var grid_offset: Vector2

var level_path: String
var is_loading: bool = false

func _ready() -> void:
	get_window().min_size = Vector2(800, 480)
	if !DirAccess.dir_exists_absolute("user://User Data/Levels"):
		DirAccess.make_dir_recursive_absolute("user://User Data/Levels")
	load_config()

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
