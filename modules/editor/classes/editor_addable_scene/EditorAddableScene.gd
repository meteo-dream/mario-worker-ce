class_name EditorAddableObject
extends Node2D

@export_file("*.tscn", "*.scn") var scene_path: String
@export_enum("enemy", "scenery", "bonus", "misc") var category: String
@export var editor_icon: Texture2D
@export var offset: Vector2
@export var properties: Array[Dictionary]

@onready var scene: Resource = load(scene_path)
@onready var texture_corrected: Texture2D = editor_icon

func _ready() -> void:
	if Editor.current_level && Editor.current_level.is_ancestor_of(self):
		add_to_group(&"editor_addable_object")
		#if Editor.mode != 1:
			#_prepare_gameplay()
		#else:
			#_prepare_editor()

func _prepare_editor() -> void:
	add_to_group(&"editor_addable_" + category)
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
	add_sibling(instance)
	queue_free()
