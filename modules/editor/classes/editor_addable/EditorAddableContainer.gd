class_name EditorAddableContainer
extends EditorAddableScene

const CONTAINER_ITEM_PLUS = preload("uid://cxy2emcerill2")
#const NULL_TEXTURE = preload("uid://drhsgmwqaacvm")

@onready var item_displayer: Sprite2D = $ItemDisplayer

var current_displaying_item: String = ""
var plus_shown: bool

func _prepare_editor(is_new: bool = true) -> void:
	add_to_group(&"editor_container")
	Thunder._connect(Editor.scene.edit_sel_switched, update_displayer)
	update_displayer(false)
	super(is_new)
	Thunder.reorder_bottom(item_displayer)


func _prepare_gameplay() -> Node:
	var instance: Node = scene.instantiate()
	if "position" in instance:
		instance.position = position + instance_offset
	if internal_settings.get("result"):
		instance.result = internal_settings.result
	if internal_settings.get("is_brick", false) && properties.get("max_items"):
		instance.max_items = get_prop("max_items")
	add_sibling.call_deferred(instance)
	prints("Game:", instance.name, position)
	queue_free()
	return instance


func _physics_process(delta: float) -> void:
	if Editor.mode != Editor.MODE.EDITOR: return
	if !Thunder.view.is_getting_closer(self, 32): return
	if plus_shown:
		update_displayer(false)
	if Editor.scene.editing_sel != LevelEditor.EDIT_SEL.BONUS || !Editor.scene.is_paint_tool():
		return
	
	if !is_instance_valid(Editor.scene.selected_object) || !Editor.scene.selected_object is EditorAddableItem:
		return
	var _sel: EditorAddableItem = Editor.scene.selected_object
	if !_sel.addable_to_container: return
	if !_sel.get_prop_internal("result_inst"): return
	if Editor.scene.object_pick_menu.visible: return
	
	var shape_cast: ShapeCast2D = Editor.scene.get_node("%ShapeCast2D")
	shape_cast.force_shapecast_update()
	if !shape_cast.is_colliding(): return
	for i in shape_cast.get_collision_count():
		var _col = shape_cast.get_collider(i)
		if !_col || !_col.get_parent(): continue
		_col = _col.get_parent()
		if !_col == self: continue
		
		if Input.is_action_just_pressed(&"ui_mclick_left"):
			EditorAudio.kick(2)
			Editor.scene.changes_after_save = true
			internal_settings.result = _sel.get_prop_internal("result_inst")
			update_displayer(false)
		else:
			update_displayer(true)
		

#func _hovered() -> void:
	#print(name)
#	update_displayer()


func update_displayer(addable: bool) -> void:
	if !item_displayer: return
	if addable:
		item_displayer.texture = CONTAINER_ITEM_PLUS
		item_displayer.scale = Vector2.ONE
		item_displayer.reset_physics_interpolation()
		plus_shown = true
		return
	plus_shown = false
	_item_display(true)


func _item_display(forced: bool = false) -> void:
	if !item_displayer: return
	var _result = internal_settings.get("result")
	if !_result || !_result.creation_nodepack: return _item_display_reset(forced)
	if _result.creation_nodepack.resource_path == current_displaying_item && !forced: return
	
	var creation_scene = _result.creation_nodepack.instantiate()
	var sprite = creation_scene.get_node_or_null("Sprite")
	if !sprite: sprite = creation_scene.get_node_or_null("Sprite2D")
	if !sprite: sprite = creation_scene.get_node_or_null("AnimatedSprite")
	if !sprite: sprite = creation_scene.get_node_or_null("AnimatedSprite2D")
	
	if !sprite:
		push_error("[QuestionBlock] Failed to retrieve the preview of result")
		item_displayer.scale = Vector2.ONE
	else:
		if is_instance_of(sprite, Sprite2D):
			item_displayer.texture = sprite.texture
		elif is_instance_of(sprite, AnimatedSprite2D):
			item_displayer.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		item_displayer.scale = Vector2.ONE / 2
		item_displayer.reset_physics_interpolation()
	
	current_displaying_item = _result.creation_nodepack.resource_path

func _item_display_reset(forced: bool = false) -> void:
	if current_displaying_item == "" && !forced: return
	
	item_displayer.texture = null #NULL_TEXTURE
	current_displaying_item = ""
