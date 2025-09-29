class_name EditorAddableScene
extends EditorAddableNode2D

@export_file("*.tscn", "*.scn") var scene_path: String
@export var properties: Dictionary[String, Variant]
@export var internal_settings: Dictionary[String, Variant]

@onready var scene: PackedScene = load(scene_path)


func _install_icon() -> void:
	var state = scene.get_state()
	if editor_icon != null: return
	
	var specific_node = null
	var specific_index: int = -1
	var specific_anim: String
	for i in state.get_node_count():
		if specific_node != null && specific_index == -1:
			#prints(specific_node, str(state.get_node_path(i, false)).right(-2))
			if specific_node == str(state.get_node_path(i, false)).right(-2):
				specific_index = i
		if specific_index != -1 && i != specific_index:
			continue
		for j in state.get_node_property_count(i):
			var propname = state.get_node_property_name(i, j)
			if state.get_node_type(i) == &"AnimatedSprite2D":
				print(propname)
			if specific_node == null && propname == "sprite":
				specific_node = str(state.get_node_property_value(i, j))
			if propname == "animation":
				specific_anim = state.get_node_property_value(i, j)
				print(specific_anim)
				continue
			if propname in ["sprite_frames", "texture"]:
				var prop = state.get_node_property_value(i, j)
				if is_instance_of(prop, Texture2D):
					editor_icon = prop
					return
				elif is_instance_of(prop, SpriteFrames):
					var anim = prop.get_animation_names()[0] if !specific_anim else specific_anim
					editor_icon = prop.get_frame_texture(anim, 0)
					return

func _prepare_editor(is_new: bool = true) -> void:
	super(is_new)

func _prepare_gameplay() -> Node:
	var instance: Node = scene.instantiate()
	if "position" in instance:
		instance.position = position + instance_offset
	add_sibling.call_deferred(instance)
	prints("Game:", instance.name, position)
	queue_free()
	return instance
