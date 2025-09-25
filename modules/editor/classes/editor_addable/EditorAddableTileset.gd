class_name EditorAddableTileset
extends EditorAddableNode2D

@export_file("*.tscn", "*.scn") var scene_path: String

#@onready var scene: PackedScene = load(scene_path)


func _install_icon() -> void:
	#var state = scene.get_state()
	if editor_icon != null: return

func _prepare_gameplay() -> Node:
	return null
