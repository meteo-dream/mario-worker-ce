@abstract
class_name EditorAddableNode2D
extends Node2D

@export_enum("tile", "scenery", "enemy", "bonus", "misc", "special") var category: String
@export var offset: Vector2
@export var editor_icon: Texture2D


func _ready() -> void:
	setup_object()

func setup_object() -> Node:
	if Editor.current_level && !get_parent() is Button:
		add_to_group(&"editor_addable_object")
	if Editor.mode == Editor.MODE.EDITOR:
		_install_icon()
		if get_parent() is Button:
			get_parent().icon = editor_icon
			process_mode = Node.PROCESS_MODE_DISABLED
	else:
		return _prepare_gameplay()
	return null

@abstract func _install_icon() -> void

func _on_editor_object_selected(category_name: String) -> void:
	Editor.scene.selected_object = self
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor._edit_sel_to_enum(category_name)
	Editor.scene.selected = []
	Editor.scene._on_selected_array_change()
	Editor.scene.object_to_paint_selected(true)

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

@abstract func _prepare_gameplay() -> Node
