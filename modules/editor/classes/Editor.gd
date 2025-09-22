extends Node

enum MODE {
	NONE,
	EDITOR,
	TESTING
}

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

var grid_shown: bool = true
var grid_size: Vector2
var grid_offset: Vector2

var level_path: String
var is_loading: bool = false

func _ready() -> void:
	get_window().min_size = Vector2(800, 480)

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
