extends Control
class_name LevelEditor

const NOTIFICATION = preload("res://modules/editor/gui/notification.tscn")
const PROP_CONTAINER = preload("res://modules/editor/gui/prop_container.tscn")
const PROP_CAT_CONTAINER = preload("res://modules/editor/gui/prop_cat_container.tscn")
const PROP_LINEEDIT = preload("res://modules/editor/gui/prop_lineedit.tscn")
const PROP_CHECKBOX = preload("res://modules/editor/gui/prop_checkbox.tscn")
const PROP_COLORPICKER = preload("res://modules/editor/gui/prop_colorpicker.tscn")

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

@onready var control: Control = %DrawArea2

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
		%ScrollPropContainer.visible = !editing_sel in [EDIT_SEL.TILE]
		%ScrollTileContainer.visible = editing_sel in [EDIT_SEL.TILE, EDIT_SEL.SCENERY]
		if to == EDIT_SEL.TILE:
			%SelectedObjSprite.visible = false
			selected_object = null
			selected = []
			_on_selected_array_change()


var selected_object: Node2D = null:
	get():
		if is_instance_valid(selected_object):
			return selected_object
		return null
var changes_after_save: bool = false
var mouse_blocked: bool

var selected: Array[Node2D]


func _ready() -> void:
	#if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_WINDOWED:
	#	DisplayServer.window_set_size(Vector2i(1280, 720))
	Editor.scene = self
	Editor.mode = Editor.MODE.EDITOR
	var loaded_level
	if Editor.current_level == null:
		loaded_level = preload("res://modules/editor/stages/base_level.tscn")
	Editor.current_level = loaded_level.instantiate()
	add_child(Editor.current_level)
	Thunder.reorder_top(Editor.current_level)
	
	reparent.call_deferred(get_tree().root, true)
	SettingsManager.show_mouse()
	Input.set_custom_mouse_cursor(preload("res://engine/components/ui/generic/textures/mouse_cursor.png"), Input.CURSOR_BUSY)
	Input.set_default_cursor_shape(Input.CURSOR_BUSY)
	
	editing_sel = EDIT_SEL.NONE


func _physics_process(delta: float) -> void:
	var m_mask = Input.get_mouse_button_mask()
	if (m_mask == MOUSE_BUTTON_MASK_LEFT & MOUSE_BUTTON_MASK_RIGHT) && mouse_blocked && Editor.is_window_active():
		mouse_blocked = false
		print("Input unblocked!")
	#print(Editor.is_window_active())
	if !Editor.is_window_active(): return
	if mouse_blocked: return
	
	match tool_mode:
		TOOL_MODES.SELECT: _tool_select_process()
		TOOL_MODES.PAN: _tool_pan_process()
		TOOL_MODES.LIST: _tool_list_process()
		TOOL_MODES.PAINT: _tool_paint_process()
		TOOL_MODES.PICKER: _tool_pick_process()
		TOOL_MODES.RECT: _tool_rect_process()
		TOOL_MODES.ERASE: _tool_erase_process()
	
	%TargetLabel.text = "Target: %s" % get_global_mouse_position().round()


func _input(event: InputEvent) -> void:
	if event is InputEventAction:
		if event.is_action(&"a_ctrl"):
			Thunder._current_player.completed = event.is_pressed()
		elif event.is_action(&"a_delete") && event.is_pressed():
			if tool_mode == TOOL_MODES.SELECT && len(selected) > 0:
				for i in selected:
					i.queue_free()
				selected = []
				_on_selected_array_change()
	
	elif event is InputEventMouseButton:
		if !Editor.is_window_active():
			mouse_blocked = true
			print("Input blocked!")
			return
		mouse_blocked = event.is_pressed() && !can_draw()
		
		if !can_draw():
			return
		match tool_mode:
			TOOL_MODES.SELECT when (!event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT):
				%SelectedObjSprite.global_position = get_pos_on_grid()
				%ShapeCastPoint.force_shapecast_update()
				var col: bool = %ShapeCastPoint.is_colliding()
				if !Input.is_action_pressed(&"a_shift"):
					selected.resize(0)
				if col:
					for i in %ShapeCastPoint.get_collision_count():
						var _col = %ShapeCastPoint.get_collider(i)
						if !_col || !_col.get_parent(): continue
						_col = _col.get_parent()
						if _col in selected:
							deselect_object(_col)
						else:
							select_object(_col)
						break
				else:
					selected.resize(0)
					_on_selected_array_change()
					return
	if event is InputEventMouseMotion || (event is InputEventMouseButton && event.is_pressed()):
		if !can_draw():
			return
		if tool_mode == TOOL_MODES.PAINT:
			if editing_sel == EDIT_SEL.TILE:
				# WORK IN PROGRESS: Simple tile editing
				var tilemap: TileMapLayer = Editor.current_level.get_node_or_null("tile/Blocks")
				if !tilemap: return
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					tilemap.set_cells_terrain_connect([tilemap.local_to_map(get_pos_on_grid())], 0, -1)
				elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					tilemap.set_cells_terrain_connect([tilemap.local_to_map(get_pos_on_grid())], 0, 0)
				return
			%SelectedObjSprite.global_position = get_pos_on_grid()
			%ShapeCast2D.force_shapecast_update()
			#var _sel_rect: Rect2 = %SelectedObjTexture.get_rect()
			if %ShapeCast2D.is_colliding():
				%SelectedObjSprite.visible = false
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) && selected_object:
					%ShapeCast2D.force_shapecast_update()
					for i in %ShapeCast2D.get_collision_count():
						var _col = %ShapeCast2D.get_collider(i)
						if !_col || !_col.get_parent(): continue
						_col = _col.get_parent()
						if _col.get_meta(&"nameid") == selected_object.get_meta(&"nameid"):
							_col.queue_free()
							changes_after_save = true
				return
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && selected_object:
				var obj = selected_object.duplicate()
				obj.global_position = %SelectedObjSprite.global_position
				var _node_folder = obj.get_meta(&"categoryid", "enemy")
				if !Editor.current_level.has_node(_node_folder):
					var new_node = Node2D.new()
					new_node.name = _node_folder
					Editor.current_level.add_child(new_node)
				Editor.current_level.get_node(_node_folder).add_child(obj, true)
				obj.owner = Editor.current_level
				changes_after_save = true
				#obj.set_meta(&"nameid", selected_object.get_meta(&"nameid"))
				obj._prepare_editor()


func get_pos_on_grid(forced_grid: bool = false) -> Vector2:
	#var _offset: Vector2 = %SelectedObjTexture.size / 2.0
	var _offset := Editor.grid_offset + Vector2.ONE * 16
	var _grid_pos = Vector2( (get_global_mouse_position().round() - _offset) / Editor.grid_size ).round() * Editor.grid_size
	return _grid_pos + Vector2.ONE * 16 if Editor.grid_shown || forced_grid else get_global_mouse_position().round() #- Vector2.ONE * 16

func can_draw() -> bool:
	var dr2 = %DrawArea2.get_rect()
	dr2.size -= 4 * Vector2.ONE
	dr2 = dr2.abs()
	return (
		%DrawArea.get_rect().has_point(%DrawArea.get_local_mouse_position()) &&
		dr2.has_point(%DrawArea2.get_local_mouse_position())
	)


func notify(text: String, outline_color: Color = Color(0.505, 1, 0.34)) -> void:
	var notif = NOTIFICATION.instantiate()
	var panel_c: PanelContainer = notif.get_child(0)
	var styleb: StyleBoxFlat = panel_c.get_theme_stylebox(&"panel").duplicate()
	styleb.border_color = outline_color
	panel_c.add_theme_stylebox_override(&"panel", styleb)
	notif.get_child(0).get_child(0).get_child(0).text = text
	%NotificationBox.add_child(notif)
	notif.modulate.a = 0.0
	var __tw = notif.create_tween()
	__tw.tween_property(notif, "modulate:a", 1.0, 0.3)
	__tw.tween_interval(3.0)
	__tw.tween_property(notif, "modulate:a", 0.0, 1.0)
	__tw.tween_callback(notif.queue_free)

func notify_error(text: String) -> void:
	text = "Error: " + text
	notify(text, Color.FIREBRICK)
	
func notify_warn(text: String) -> void:
	text = "Warning: " + text
	notify(text, Color.YELLOW)


func save_level(path) -> bool:
	if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift"):
		%SaveFileDialog.deselect_all()
		if %SaveFileDialog.current_file.is_empty():
			%SaveFileDialog.current_file = "MyLevel"
		%SaveFileDialog.show()
		await %SaveFileDialog.visibility_changed
		if %SaveFileDialog.current_path:
			path = %SaveFileDialog.current_path
		else:
			notify_warn("Level was not saved.")
			return false
	
	var to_save := PackedScene.new()
	var _lvl = Editor.current_level
	if !_lvl:
		notify_error("Failed to save level.")
		Editor.level_path = ""
		return false
	
	# saving level properties
	var _level_props = Editor.current_level.get_node_or_null("LevelProperties")
	if !_level_props:
		Editor.current_level_properties.name = "LevelProperties"
		Editor.current_level.add_child(Editor.current_level_properties, true)
	
	_level_props.player_position = Editor.current_level_properties.player_position
	_level_props.level_display_name_1 = Editor.current_level_properties.level_display_name_1
	_level_props.level_display_name_2 = Editor.current_level_properties.level_display_name_2
	_level_props.level_name = Editor.current_level_properties.level_name
	_level_props.level_description = Editor.current_level_properties.level_description
	_level_props.level_author = Editor.current_level_properties.level_author
	_level_props.level_author_email = Editor.current_level_properties.level_author_email
	_level_props.level_author_website = Editor.current_level_properties.level_author_website
	
	## TODO: Idk this doesn't seem to work?
	for i in _lvl.get_children():
		i.owner = _lvl
	if Thunder._current_player:
		Thunder._current_player.set_process(false)
		Thunder._current_player.suit = null
		Thunder._current_player.global_position = Editor.current_level_properties.player_position
	to_save.pack(_lvl)
	#if path.get_extension().is_empty():
	#	path += ".tscn"
	print(path)
	var er = ResourceSaver.save(to_save, path, ResourceSaver.FLAG_COMPRESS)
	Thunder._current_player.suit = CharacterManager.get_suit(Thunder._current_player_state.name)
	if er != OK:
		notify_error(error_string(er))
		Editor.level_path = ""
		return false
	changes_after_save = false
	Editor.level_path = path
	notify("Level saved!")
	return true


func load_level(path) -> bool:
	var res: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	#var res = load(path)
	if !res:
		notify_error("Failed to load level.")
		Editor.level_path = ""
		return false
	var new_level := res.instantiate()
	if !new_level:
		notify_error("Failed to load level.")
		Editor.level_path = ""
		return false
	
	# We do not need duplicating players
	if Thunder._current_player:
		Thunder._current_player.queue_free()
	# Removing unnecessary garbage scenes resulting from live-testing in editor
	for i in get_children():
		if i.is_in_group(&"editor_internal_object"): continue
		i.queue_free()
	add_child(new_level, false)
	# Forcefully removing old level and immediately assigning a new one
	if Editor.current_level:
		Editor.current_level.free()
	Editor.current_level = new_level
	Thunder.reorder_top(new_level)
	#add_child.call_deferred(new_level, false)
	#Editor.set_deferred(&"current_level", new_level)
	#Thunder.reorder_top.call_deferred(new_level)
	
	var _level_props = Editor.current_level.get_node_or_null("LevelProperties")
	Editor.current_level_properties = _level_props.duplicate() if _level_props else null
	
	%PropertiesTabs.update_input_values()
	
	if Editor.mode == Editor.MODE.EDITOR:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED,
			&"editor_addable_object", &"_prepare_editor", false
		)
	notify.call_deferred("Level loaded with %d objects!" % get_tree().get_node_count_in_group(&"editor_addable_object"))
	return true


func select_object(obj: Node2D) -> void:
	selected.append(obj)
	_on_selected_array_change()

func deselect_object(obj: Node2D) -> void:
	selected.erase(obj)
	_on_selected_array_change()

func _on_selected_array_change() -> void:
	%EditorGridSelection.queue_redraw()
	if len(selected) > 1:
		%ObjectName.text = "%d objects selected" % [selected.size()]
		var first_meta = selected[0].get_meta(&"nameid")
		for item in selected:
			if item.get_meta(&"nameid") != first_meta:
				for i in %PropListContainer.get_children():
					i.queue_free()
				break
	elif len(selected) == 0:
		%ObjectName.text = ""
		for i in %PropListContainer.get_children():
			i.queue_free()
	elif len(selected) == 1:
		for i in %PropListContainer.get_children():
			i.queue_free()
		%ObjectName.text = '"%s"' % selected[0].name
		var prop_list: Array[Dictionary] = selected[0].get_property_list()
		var wait_for: int = -1
		#var _inst = load(selected[0].scene_path).instantiate()
		#var instance_prop_list: Array[Dictionary] = _inst.get_property_list()
		#for property in instance_prop_list:
			#if !(property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) || property.usage == 4096:
				#continue
			#if property.name == "sprite": continue
			#print(property.usage)
			#_add_prop(property, _inst)
			
		for property in prop_list:
			var prop_name = property.name
			if prop_name != "modulate":
				if wait_for != -1 && property.usage != wait_for:
					continue
				else:
					wait_for = -1
			if property.usage & PROPERTY_USAGE_CATEGORY && prop_name in ["Node", "CanvasItem"]:
				wait_for = PROPERTY_USAGE_CATEGORY
				print("Waiting")
				if prop_name != "CanvasItem":
					continue
			if prop_name.begins_with("global_") || prop_name.begins_with("process_") || prop_name.begins_with("metadata") || property.name in [
				"rotation", "transform", "script"
			]:
				continue
			
			if property.usage & PROPERTY_USAGE_INTERNAL || property.usage == 4102:
				continue
			if property.usage & PROPERTY_USAGE_CATEGORY:
				prints("CAT:",property.usage, prop_name)
				var _prop_cat = PROP_CAT_CONTAINER.instantiate()
				_prop_cat.custom_minimum_size.y = 21
				var label: Label = _prop_cat.get_child(0)
				label.text = prop_name
				label.add_theme_font_size_override("font_size", 15)
				%PropListContainer.add_child(_prop_cat)
				continue
			if property.usage & PROPERTY_USAGE_GROUP:
				if prop_name in ["Material", "Texture"]:
					wait_for = PROPERTY_USAGE_GROUP
					continue
				
				#var _prop_cat = PROP_CAT_CONTAINER.instantiate()
				#var label: Label = _prop_cat.get_child(0)
				#label.text = prop_name
				#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				#label.add_theme_color_override("font_color", Color.WHITE)
				#label.remove_theme_font_override(&"font")
				#%PropListContainer.add_child(_prop_cat)
				continue
			
			print(property.usage)
			_add_prop(property, selected[0])

func _add_prop(property: Dictionary, target) -> void:
	var prop_value = target.get(property.name)
	var _prop_c = PROP_CONTAINER.instantiate()
	_prop_c.get_child(0).text = property.name
	match property.type:
		TYPE_BOOL:
			var _checkbox = PROP_CHECKBOX.instantiate()
			_prop_c.add_child(_checkbox)
			_checkbox.button_pressed = prop_value
		TYPE_COLOR:
			var _colorpick = PROP_COLORPICKER.instantiate()
			_prop_c.add_child(_colorpick)
			_colorpick.color = prop_value
		_:
			var _lineedit = PROP_LINEEDIT.instantiate()
			_prop_c.add_child(_lineedit)
			_lineedit.text = str(prop_value)
	%PropListContainer.add_child(_prop_c)
	

## -Select tool ready functions-
func _tool_select() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%SelectMode.button_pressed = true
	%SelectedObjTexture.texture = null
	%SelectedObjSprite.texture = null
	selected_object = null

func _tool_pan() -> void:
	control.set_default_cursor_shape(Control.CURSOR_DRAG)
	%PanMode.button_pressed = true
	%SelectedObjTexture.texture = null
	%SelectedObjSprite.texture = null

func _tool_list() -> void:
	control.set_default_cursor_shape(Control.CURSOR_HELP)
	%ListMode.button_pressed = true
	%SelectedObjTexture.texture = null
	%SelectedObjSprite.texture = null

func _tool_paint() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%PaintMode.button_pressed = true
	var _sel_obj = selected_object if is_instance_valid(selected_object) else selected[0] if len(selected) == 1 else null
	if _sel_obj:
		%SelectedObjSprite.texture = _sel_obj.editor_icon
		#var texsize = %SelectedObjSprite.texture.get_size()
		#%SelectedObjSprite.offset.x = texsize.x / 2
		#var size_y = (texsize.y / 2) if texsize.y <= 32 else 16
		if !is_instance_valid(selected_object) && len(selected) == 1:
			selected_object = selected[0]
		#%SelectedObjTexture.size = %SelectedObjTexture.texture.get_size()
	else:
		%SelectedObjSprite.texture = null
		%SelectedObjTexture.texture = null

func _tool_pick() -> void:
	control.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)
	%PickMode.button_pressed = true

func _tool_rect() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%RectMode.button_pressed = true
	if is_instance_valid(selected_object):
		%SelectedObjSprite.texture = selected_object.editor_icon
		#%SelectedObjTexture.size = %SelectedObjTexture.texture.get_size()
	else:
		%SelectedObjSprite.texture = null
		%SelectedObjTexture.texture = null

func _tool_erase() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%EraseMode.button_pressed = true


## -Select tool process functions-
func _tool_select_process() -> void:
	%SelectedObjSprite.global_position = get_pos_on_grid()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	%ShapeCastPoint.force_shapecast_update()
	var col: bool = %ShapeCastPoint.is_colliding()
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if col else Control.CURSOR_ARROW

func _tool_pan_process() -> void:
	pass

func _tool_list_process() -> void:
	pass

func _tool_paint_process() -> void:
	if editing_sel != EDIT_SEL.TILE:
		%SelectedObjSprite.visible = can_draw() && !%ShapeCast2D.is_colliding()
	
	if !can_draw():
		return
	%SelectedObjSprite.global_position = get_pos_on_grid()
	if is_instance_valid(selected_object):
		%SelectedObjSprite.offset = selected_object.offset
	%SelectedObjSprite.reset_physics_interpolation()

func _tool_pick_process() -> void:
	pass

func _tool_rect_process() -> void:
	pass

func _tool_erase_process() -> void:
	%SelectedObjSprite.visible = false
	%SelectedObjTexture.visible = false
	%SelectedObjSprite.global_position = get_pos_on_grid()
	%SelectedObjSprite.reset_physics_interpolation()
	%ShapeCastPoint.force_shapecast_update()
	var _col = %ShapeCastPoint.is_colliding()
	control.set_default_cursor_shape(Control.CURSOR_FORBIDDEN if _col else Control.CURSOR_ARROW)
	if is_processing_input() && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for i in %ShapeCastPoint.get_collision_count():
			var _sele = %ShapeCastPoint.get_collider(i)
			if _sele && _sele.has_node(".."):
				_sele.get_parent().queue_free()
