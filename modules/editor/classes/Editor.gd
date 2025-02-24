extends Node

var camera: Camera2D:
	get():
		if is_instance_valid(camera): return camera
		return null
var scene: LevelEditor:
	get():
		if is_instance_valid(scene): return scene
		return null
var current_level: Level:
	get():
		if is_instance_valid(current_level): return current_level
		return null

var mode: int

var grid_shown: bool = true
var grid_size: Vector2
var grid_offset: Vector2

var level_path: String

func _ready() -> void:
	get_window().min_size = Vector2(800, 480)

func get_group_property(group_name: StringName, property: StringName) -> bool:
	var res: bool
	for i in get_tree().get_nodes_in_group(group_name):
		if i.get(property): res = true
	return res

func is_window_active() -> bool:
	var res: bool = true
	var _win = DisplayServer.window_get_active_popup()
	if _win != -1: res = false
	if !DisplayServer.window_is_focused(0): res = false
	return res
