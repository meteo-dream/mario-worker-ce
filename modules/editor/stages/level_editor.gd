extends Control
class_name LevelEditor

enum TOOL_MODES {
	SELECT,
	PAN,
	LIST,
	PAINT,
	PICKER,
	RECT,
	ERASE
}

enum EDIT_SEL {
	NONE,
	TILE,
	SCENERY,
	ENEMY,
	BONUS,
	MISC
}

@onready var control: Control = %DrawArea

var tool_mode: int:
	set(to):
		tool_mode = to
		match tool_mode:
			TOOL_MODES.SELECT: _tool_select()
			TOOL_MODES.PAN: _tool_pan()
			TOOL_MODES.LIST: _tool_list()
			TOOL_MODES.PAINT: _tool_paint()
			TOOL_MODES.PICKER: _tool_pick()
			TOOL_MODES.RECT: _tool_rect()
			TOOL_MODES.ERASE: _tool_erase()
var editing_sel: int = EDIT_SEL.NONE:
	set(to):
		editing_sel = to
		%PaintMode.disabled = editing_sel == EDIT_SEL.NONE
		%PickMode.disabled = editing_sel == EDIT_SEL.NONE
		%RectMode.disabled = editing_sel == EDIT_SEL.NONE
		%EraseMode.disabled = editing_sel == EDIT_SEL.NONE
		%RotateLeft.disabled = editing_sel == EDIT_SEL.NONE
		%RotateRight.disabled = editing_sel == EDIT_SEL.NONE
		%EditingMenuButton.select(editing_sel)
		if editing_sel == EDIT_SEL.NONE:
			tool_mode = TOOL_MODES.SELECT

var selected_object: Node2D = null


func _ready() -> void:
	#if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_WINDOWED:
	#	DisplayServer.window_set_size(Vector2i(1280, 720))
	if Editor.current_level == null:
		Editor.current_level = get_node_or_null("Level")
	Editor.scene = self
	Data.technical_values.editor_mode = 1
	reparent.call_deferred(get_tree().root, true)
	SettingsManager.show_mouse()
	Input.set_custom_mouse_cursor(preload("res://engine/components/ui/generic/textures/mouse_cursor.png"), Input.CURSOR_BUSY)
	Input.set_default_cursor_shape(Input.CURSOR_BUSY)
	
	%SelectMode.button_group.pressed.connect(_on_button_group_pressed)
	editing_sel = EDIT_SEL.NONE


func _physics_process(delta: float) -> void:
	match tool_mode:
		TOOL_MODES.SELECT: _tool_select_process()
		TOOL_MODES.PAN: _tool_pan_process()
		TOOL_MODES.LIST: _tool_list_process()
		TOOL_MODES.PAINT: _tool_paint_process()
		TOOL_MODES.PICKER: _tool_pick_process()
		TOOL_MODES.RECT: _tool_rect_process()
		TOOL_MODES.ERASE: _tool_erase_process()
	
	%TargetLabel.text = "Target: %s" % get_global_mouse_position()


func _on_button_group_pressed(button: BaseButton) -> void:
	match button.name:
		"SelectMode": tool_mode = TOOL_MODES.SELECT
		"PanMode": tool_mode = TOOL_MODES.PAN
		"ListMode": tool_mode = TOOL_MODES.LIST
		"PaintMode": tool_mode = TOOL_MODES.PAINT
		"PickMode": tool_mode = TOOL_MODES.PICKER
		"RectMode": tool_mode = TOOL_MODES.RECT
		"EraseMode": tool_mode = TOOL_MODES.ERASE


## -Select tool ready functions-
func _tool_select() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%SelectMode.button_pressed = true
	%SelectedObjTexture.texture = null
	selected_object = null

func _tool_pan() -> void:
	control.set_default_cursor_shape(Control.CURSOR_DRAG)
	%PanMode.button_pressed = true
	%SelectedObjTexture.texture = null

func _tool_list() -> void:
	control.set_default_cursor_shape(Control.CURSOR_HELP)
	%ListMode.button_pressed = true
	%SelectedObjTexture.texture = null

func _tool_paint() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%PaintMode.button_pressed = true
	if is_instance_valid(selected_object):
		%SelectedObjTexture.texture = selected_object.editor_icon
	else:
		%SelectedObjTexture.texture = null

func _tool_pick() -> void:
	control.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)
	%PickMode.button_pressed = true

func _tool_rect() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%RectMode.button_pressed = true
	if is_instance_valid(selected_object):
		%SelectedObjTexture.texture = selected_object.editor_icon
	else:
		%SelectedObjTexture.texture = null

func _tool_erase() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%EraseMode.button_pressed = true


## -Select tool process functions-
func _tool_select_process() -> void:
	pass

func _tool_pan_process() -> void:
	pass

func _tool_list_process() -> void:
	pass

func _tool_paint_process() -> void:
	var can_draw = %DrawArea.get_rect().has_point(%DrawArea.get_local_mouse_position())
	%SelectedObjTexture.visible = can_draw
	
	if !can_draw:
		return
	%SelectedObjTexture.global_position = get_pos_on_grid()
	#var _sel_rect: Rect2 = %SelectedObjTexture.get_rect()
	%ShapeCast2D.force_shapecast_update()
	if %ShapeCast2D.is_colliding():
		%SelectedObjTexture.visible = false
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) && selected_object:
			%ShapeCast2D.force_shapecast_update()
			for i in %ShapeCast2D.get_collision_count():
				var _col = %ShapeCast2D.get_collider(i)
				if !_col || !_col.get_parent(): continue
				_col = _col.get_parent()
				if _col.get_meta(&"nameid") == selected_object.get_meta(&"nameid"):
					_col.queue_free()
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && selected_object:
		var obj = selected_object.duplicate()
		obj.global_position = %SelectedObjTexture.global_position + Vector2.ONE * 16
		Editor.current_level.get_node("Enemies").add_child(obj)
		#obj.set_meta(&"nameid", selected_object.get_meta(&"nameid"))
		obj._prepare_editor()

func _tool_pick_process() -> void:
	pass

func _tool_rect_process() -> void:
	pass

func _tool_erase_process() -> void:
	%SelectedObjTexture.visible = false
	%SelectedObjTexture.global_position = get_pos_on_grid()
	%ShapeCast2D.force_shapecast_update()
	var _col = %ShapeCast2D.is_colliding()
	control.set_default_cursor_shape(Control.CURSOR_FORBIDDEN if _col else Control.CURSOR_ARROW)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for i in %ShapeCast2D.get_collision_count():
			var _sele = %ShapeCast2D.get_collider(i)
			if _sele && _sele.get_parent(): _sele.get_parent().queue_free()


func _on_menu_button_item_selected(index: int) -> void:
	editing_sel = index


func get_pos_on_grid() -> Vector2:
	var _offset: Vector2 = %SelectedObjTexture.size / 2.0
	var _grid_pos = Vector2( (get_global_mouse_position() - _offset) / 32.0 ).round() * 32
	return _grid_pos if Editor.grid_shown else get_global_mouse_position()
