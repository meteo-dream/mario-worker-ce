class_name EditorAddableObject
extends Node2D

@export_file("*.tscn", "*.scn") var scene_path: String
@export_enum("enemy", "scenery", "bonus", "misc", "special") var category: String
@export var editor_icon: Texture2D
@export var offset: Vector2
#@export var properties: Array[Dictionary]

@onready var scene: PackedScene = load(scene_path)
@onready var texture_corrected: Texture2D = editor_icon

func _ready() -> void:
	if Editor.current_level && !get_parent() is Button:
		add_to_group(&"editor_addable_object")
	if Editor.mode == Editor.MODE.EDITOR:
		_install_icon()
		if get_parent() is Button:
			get_parent().icon = editor_icon
	else:
		_prepare_gameplay()


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
	add_to_group(&"editor_addable_" + category)
	if is_new:
		position += offset
	reset_physics_interpolation()
	var _texture = Sprite2D.new()
	_texture.texture = editor_icon
	#_texture.position = -Vector2.ONE * 16
	add_child(_texture)
	
	var _area = Area2D.new()
	_area.collision_layer = 1 << 8
	_area.collision_mask = 0
	add_child(_area)
	var _col = CollisionShape2D.new()
	var _shape = RectangleShape2D.new()
	_col.shape = _shape
	_shape.size = Vector2.ONE * 32
	_col.position = -offset
	_area.add_child(_col)
	
	prints(name, global_position)

func _prepare_gameplay() -> void:
	var instance: Node = scene.instantiate()
	if "position" in instance:
		instance.position = position
	add_sibling.call_deferred(instance)
	prints("Game:", instance.name, position)
	queue_free()
