extends Node

var camera: Camera2D:
	get():
		if is_instance_valid(camera): return camera
		return null
var scene: LevelEditor:
	get():
		if is_instance_valid(scene): return scene
		return null

var grid_shown: bool = true
var current_level: Level:
	get():
		if is_instance_valid(current_level): return current_level
		return null
