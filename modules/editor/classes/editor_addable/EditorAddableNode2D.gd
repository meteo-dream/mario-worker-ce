@abstract
class_name EditorAddableNode2D
extends Node2D

@export_enum("tile", "scenery", "enemy", "bonus", "misc", "special") var category: String
@export var subcategory: String = "Other"
@export var offset: Vector2
@export var editor_icon: Texture2D
@export var editor_button_icon: Texture2D
@export_multiline var text_description: String

var translated_name: String
var _editor_icon: Texture2D
var _editor_ready: bool
var _shape: Shape2D

func _ready() -> void:
	setup_object()


func setup_object() -> Node:
	if Editor.current_level && !get_parent() is Button:
		add_to_group(&"editor_addable_object")
	if Editor.mode == Editor.MODE.EDITOR:
		_install_icon()
		var _par = get_parent()
		if _par is Button:
			if editor_button_icon:
				_par.icon = editor_button_icon
				_par.add_theme_constant_override(&"icon_max_width", editor_button_icon.get_width())
			else:
				_par.icon = editor_icon
			process_mode = Node.PROCESS_MODE_DISABLED
	else:
		return _prepare_gameplay()
	return null

@abstract func _install_icon() -> void

func _on_editor_object_selected(category_name: String) -> void:
	if !Editor.scene.is_paint_tool():
		Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor._edit_sel_to_enum(category_name)
	Editor.scene.apply_stored_selection_object(self)
	Editor.scene.selected_object = self
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
	_area.collision_layer = 1 << 7 << LevelEditor._edit_sel_to_enum(category)
	_area.collision_mask = 0
	_area.position -= offset
	add_child(_area)
	var _col = CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	_col.shape = _shape
	_shape.size = Vector2.ONE * 32
	_area.add_child(_col)
	
	_editor_ready = true
	queue_redraw()
	
	prints(name, global_position)

@abstract func _prepare_gameplay() -> Node

func _paint_object(_section_node: Node2D, mouse_clicked_once: bool) -> Node2D:
	var obj = Editor.scene.selected_object.duplicate()
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	obj.position = Editor.scene.get_pos_on_grid() - _section_node.global_position
	var _node_folder = obj.category
	if !_section_node.has_node(_node_folder):
		printerr("Section %d: Node %s doesn't exist" % [Editor.scene.section, obj.category])
		return null
	_section_node.get_node(_node_folder).add_child(obj, true)
	obj.owner = Editor.current_level
	Editor.scene.changes_after_save = true
	EditorAudio.place_object()
	obj._prepare_editor(true)
	return obj


func _hovering() -> void:
	pass

func _hovered() -> void:
	pass


func get_editor_sprite_pos() -> Vector2:
	return offset


func _draw() -> void:
	if Editor.mode != Editor.MODE.EDITOR || !_editor_ready: return
	if Editor.scene.editing_sel != LevelEditor._edit_sel_to_enum(category):
		return
	var _rect: Rect2 = _shape.get_rect()
	_rect.position -= offset
	var _modulate: float = 0.5
	draw_rect(_rect, Color.RED - Color(0, 0, 0, _modulate))
