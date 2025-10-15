class_name EditorAddableSpecial
extends EditorAddableNode2D

enum PLACE_MODE {
	NORMAL,
	ONE_PER_LEVEL,
	ONE_PER_SECTION
}

@export var place_mode: PLACE_MODE
@export var group_name: StringName
@export var deletable: bool = true
@export var editor_icon_offset: Vector2


func _install_icon() -> void:
	if editor_icon != null: return

func _prepare_gameplay() -> Node:
	queue_free()
	return null

func _prepare_editor(is_new: bool = true) -> void:
	if group_name:
		add_to_group(group_name)
	if place_mode == PLACE_MODE.NORMAL:
		super(is_new)
		return
	if is_new:
		position += offset
	reset_physics_interpolation()
	var _texture = Sprite2D.new()
	_texture.texture = editor_icon
	_texture.offset = editor_icon_offset
	#_texture.position = -Vector2.ONE * 16
	add_child(_texture)
	
	_editor_ready = true
	
	prints(name, global_position)

func _paint_object(_section_node: Node2D, mouse_clicked_once: bool) -> Node2D:
	var group_nodes := get_tree().get_nodes_in_group(group_name)
	if place_mode == PLACE_MODE.NORMAL || group_nodes.is_empty():
		var new_node = super(_section_node, mouse_clicked_once)
		new_node.position_changed()
		return new_node
	if place_mode == PLACE_MODE.ONE_PER_LEVEL:
		group_nodes[0].position = Editor.scene.get_pos_on_grid() + offset
		group_nodes[0].reset_physics_interpolation()
		group_nodes[0].position_changed()
	elif place_mode == PLACE_MODE.ONE_PER_SECTION:
		var _affected: bool
		for i in group_nodes:
			if _section_node.is_ancestor_of(i):
				i.position = Editor.scene.get_pos_on_grid() + offset
				i.reset_physics_interpolation()
				i.position_changed()
				_affected = true
				break
		if !_affected:
			var new_node = super(_section_node, mouse_clicked_once)
			new_node.position_changed()
			return new_node
	Editor.scene.changes_after_save = true
	if mouse_clicked_once:
		EditorAudio.place_object()
	return null

func position_changed() -> void:
	pass

func get_editor_sprite_pos() -> Vector2:
	return Editor.scene.get_pos_on_grid() + offset + editor_icon_offset

func _draw() -> void:
	pass
