extends Node

@export var properties := LevelProperties.new()

func _ready() -> void:
	Editor.current_level_properties = properties
