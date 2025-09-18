class_name EditorAddableTileset
extends EditorAddableNode2D

@export_file("*.tscn", "*.scn") var scene_path: String

@onready var scene: PackedScene = load(scene_path)


func _prepare_gameplay() -> Node:
	return null
