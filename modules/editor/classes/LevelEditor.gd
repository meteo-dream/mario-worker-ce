extends Control
class_name LevelEditor

signal section_switched_to(section_index: int)

const NOTIFICATION = preload("res://modules/editor/gui/notification.tscn")
const PROP_CONTAINER = preload("res://modules/editor/gui/prop_container.tscn")
const PROP_CAT_CONTAINER = preload("res://modules/editor/gui/prop_cat_container.tscn")
const PROP_LINEEDIT = preload("res://modules/editor/gui/prop_lineedit.tscn")
const PROP_CHECKBOX = preload("res://modules/editor/gui/prop_checkbox.tscn")
const PROP_COLORPICKER = preload("res://modules/editor/gui/prop_colorpicker.tscn")

const E_PLAYER = preload("uid://dmljul85ysxlp")
const E_TILEMAP = preload("uid://cpkmy1ccyuval")

enum TOOL_MODES {
	SELECT,
	PAN,
	LIST,
	PAINT,
	PICKER,
	RECT,
	ERASE,
	LINE,
}

enum EDIT_SEL {
	NONE,
	TILE,
	SCENERY,
	ENEMY,
	BONUS,
	MISC,
	SPECIAL,
	MAX
}

@onready var control: Control = %DrawArea2
@onready var selected_obj_sprite: Sprite2D = %SelectedObjSprite

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
		if editing_sel != to:
			#editor_cache.stored_category_sel[to] = selected_object
			if editing_sel == EDIT_SEL.TILE:
				editor_cache.stored_category_tileset = selected_tileset
				editor_cache.stored_category_tile_holder = selected_tile_holder
		editing_sel = to
		%PaintMode.disabled = to == EDIT_SEL.NONE
		%PickMode.disabled = to == EDIT_SEL.NONE
		%RectMode.disabled = to == EDIT_SEL.NONE
		%EraseMode.disabled = to == EDIT_SEL.NONE
		%RotateLeft.disabled = to == EDIT_SEL.NONE
		%RotateRight.disabled = to == EDIT_SEL.NONE
		%EditingMenuButton.select(to)
		%EraseWithRMB.disabled = to == EDIT_SEL.TILE
		%EraseSpecificObject.disabled = to == EDIT_SEL.TILE || !%EraseWithRMB.button_pressed
		%UseTileTerrains.disabled = to != EDIT_SEL.TILE
		if to == EDIT_SEL.NONE:
			tool_mode = TOOL_MODES.SELECT
		%ScrollPropContainer.visible = !to in [EDIT_SEL.TILE]
		%TilePanel.visible = to in [EDIT_SEL.TILE]
		%ShapeCast2D.collision_mask = 1 << 7 << to
		%ShapeCastPoint.collision_mask = 1 << 7 << to
		get_tree().call_group(&"editor_addable_object", &"queue_redraw")
		if to == EDIT_SEL.TILE:
			selected_obj_sprite.visible = selected_tile_holder != null && can_draw()
			selected_object = null
			selected = []
			_on_selected_array_change()


var selected_object: Node2D = null:
	get():
		if is_instance_valid(selected_object):
			return selected_object
		return null
var selected_tileset: Dictionary
var selected_tile_holder: TileHolder
var selected: Array[Node2D]
var section: int = 1

var changes_after_save: bool = false:
	set(to):
		changes_after_save = to
		var _end: String = " (*)" if changes_after_save else ""
		DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name") + _end)
var mouse_blocked: bool
var special_object_blocked: bool
var editor_options: Dictionary = {
	erase_with_rmb = false,
	erase_specific_object = true,
	use_tile_terrains = true,
}
var editor_cache := EditorCacheData.new()
var mouse_clicked_once: bool


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
	Editor.gui.apply_level_properties()
	Editor.is_loading = false
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED,
		&"editor_addable_object", &"_prepare_editor", false
	)
	
	reparent.call_deferred(get_tree().root, true)
	SettingsManager.show_mouse()
	Input.set_custom_mouse_cursor(preload("res://engine/components/ui/generic/textures/mouse_cursor.png"), Input.CURSOR_BUSY)
	Input.set_default_cursor_shape(Input.CURSOR_BUSY)
	changes_after_save = false
	
	editing_sel = EDIT_SEL.NONE
	%ObjectPickMenu.show()
	section_switched_to.connect(Editor.camera._on_section_switched)


func _physics_process(delta: float) -> void:
	var m_mask = Input.get_mouse_button_mask()
	if (m_mask == MOUSE_BUTTON_MASK_LEFT & MOUSE_BUTTON_MASK_RIGHT) && mouse_blocked && Editor.is_window_active():
		mouse_blocked = false
		print("Input unblocked!")
	mouse_clicked_once = false
	#print(Editor.is_window_active())
	if !Editor.is_window_active(): return
	
	%TargetLabel.text = tr("Target: %.v") % get_global_mouse_position().round()
	%CountLabel.text = tr(" Objects: %d, Tilemaps: %d") % [
		get_tree().get_node_count_in_group(&"editor_addable_object"),
		get_tree().get_node_count_in_group(&"editor_addable_tilemap"),
	]
	if special_object_blocked:
		if Input.is_action_just_pressed(&"ui_cancel"):
			special_object_blocked = false
	
	if mouse_blocked: return
	
	match tool_mode:
		TOOL_MODES.SELECT: _tool_select_process()
		TOOL_MODES.PAN: _tool_pan_process()
		TOOL_MODES.LIST: _tool_list_process()
		TOOL_MODES.PAINT: _tool_paint_process()
		TOOL_MODES.PICKER: _tool_pick_process()
		TOOL_MODES.RECT: _tool_rect_process()
		TOOL_MODES.ERASE: _tool_erase_process()


func _input(event: InputEvent) -> void:
	if event.is_action(&"a_ctrl") && Thunder._current_player && !event.is_echo():
		Thunder._current_player.completed = event.is_pressed()
	elif event.is_action(&"a_delete") && event.is_pressed() && !event.is_echo():
		if tool_mode == TOOL_MODES.SELECT && len(selected) > 0:
			for i in selected:
				if i is EditorAddableSpecial && !i.deletable:
					continue
				i.queue_free()
			selected = []
			_on_selected_array_change()
			EditorAudio.kick()
			changes_after_save = true
	elif event.is_action(&"ui_menu_toggle") && event.is_pressed() && !event.is_echo() && !special_object_blocked:
		if %ObjectPickMenu.visible:
			object_pick_menu_close(false)
		else:
			%ObjectPickMenu.show()
		EditorAudio.menu_open()
	elif event.is_action(&"ui_zoom_in") && event.is_pressed() && !event.is_echo() && can_draw_not_blocked():
		if !Input.is_action_pressed(&"a_alt") && !Input.is_action_pressed(&"a_ctrl") && tool_mode in [TOOL_MODES.PAINT, TOOL_MODES.RECT]:
			switch_tile_by(-1)
	elif event.is_action(&"ui_zoom_out") && event.is_pressed() && !event.is_echo() && can_draw_not_blocked():
		if !Input.is_action_pressed(&"a_alt") && !Input.is_action_pressed(&"a_ctrl") && tool_mode in [TOOL_MODES.PAINT, TOOL_MODES.RECT]:
			switch_tile_by(1)
	if event.is_action_pressed(&"ui_drop_player") && Thunder._current_player:
		var pl := Thunder._current_player
		if !pl.test_move(
			Transform2D(pl.transform.x / 2, pl.transform.y / 2, get_global_mouse_position()), Vector2.ZERO, null, 0.08, true
		):
			pl.global_position = get_global_mouse_position()
			pl.reset_physics_interpolation()
	
	elif event is InputEventMouseButton:
		if !Editor.is_window_active():
			mouse_blocked = true
			print("Input blocked!")
			return
		mouse_blocked = event.is_pressed() && !can_draw()
		mouse_clicked_once = event.is_pressed()
		
		if can_draw():
			_input_mouse_click(event)
	
	if !Editor.current_level:
		return
	if event is InputEventMouseMotion || (event is InputEventMouseButton && event.is_pressed()):
		if can_draw_not_blocked():
			_input_mouse_hold(event)


func _input_mouse_click(event: InputEventMouseButton) -> void:
	if (!event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT) && (
		tool_mode == TOOL_MODES.PICKER || Input.is_action_pressed(&"a_ctrl") && !Input.is_action_pressed(&"a_shift")
	):
		var picked: bool = pick_block()
		if picked:
			tool_mode = TOOL_MODES.PAINT
			EditorAudio.menu_accept()
	elif tool_mode == TOOL_MODES.SELECT && (!event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT):
		selected_obj_sprite.global_position = get_pos_on_grid()
		%ShapeCastPoint.force_shapecast_update()
		var col: bool = %ShapeCastPoint.is_colliding()
		if !Input.is_action_pressed(&"a_shift"):
			selected.resize(0)
		if !col:
			selected.resize(0)
			_on_selected_array_change()
			return
		
		for i in %ShapeCastPoint.get_collision_count():
			var _col = %ShapeCastPoint.get_collider(i)
			if !_col || !_col.get_parent(): continue
			_col = _col.get_parent()
			if _col in selected:
				deselect_object(_col)
			else:
				select_object(_col)
			break


func _input_mouse_hold(event: InputEvent) -> void:
	if tool_mode == TOOL_MODES.PAINT && !Input.is_action_pressed(&"a_ctrl"):
		if editing_sel == EDIT_SEL.TILE:
			_input_paint_tile(event)
			return
		if is_instance_valid(selected_object):
			selected_obj_sprite.global_position = selected_object.get_editor_sprite_pos()
		%ShapeCast2D.force_shapecast_update()
		#var _sel_rect: Rect2 = %SelectedObjTexture.get_rect()
		if %ShapeCast2D.is_colliding():
			selected_obj_sprite.visible = false
			# Erasing the object by RMB
			_input_paint_object_rmb()
			return
		# Painting the object to the level
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && selected_object:
			_input_paint_object()


func _input_paint_tile(event: InputEvent) -> void:
	#var tile_parent: Node2D = Editor.current_level.get_section(section).get_node_or_null("tile")
	if !selected_tile_holder: return
	var tilemap: TileMapLayer = selected_tile_holder.tilemap
	if !tilemap: return
	var _section_node = Editor.current_level.get_section(section)
	var local_pos: Vector2i = _section_node.to_local(tilemap.local_to_map(get_pos_on_grid()))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) && tilemap.get_cell_tile_data(local_pos):
		if selected_tile_holder.terrain > -1:
			tilemap.set_cells_terrain_connect(
				[local_pos],
				selected_tile_holder.terrain_set,
				-1
			)
		else:
			tilemap.erase_cell(local_pos)
		%AudioBlockErase.play()
		changes_after_save = true
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if event is InputEventMouseButton && event.is_pressed():
			EditorAudio.place_object()
		if selected_tile_holder.terrain > -1:
			tilemap.set_cells_terrain_connect([local_pos],
				selected_tile_holder.terrain_set,
				selected_tile_holder.terrain
			)
		else:
			tilemap.set_cell(local_pos,
				selected_tile_holder.source_id,
				selected_tile_holder.id,
				selected_tile_holder.alt_tile
			)
		changes_after_save = true


func _input_paint_object_rmb() -> void:
	if !(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) && selected_object):
		return
	%ShapeCast2D.force_shapecast_update()
	for i in %ShapeCast2D.get_collision_count():
		var _col = %ShapeCast2D.get_collider(i)
		if !_col || !_col.get_parent(): continue
		_col = _col.get_parent()
		if _col.get("properties") && !editor_options.erase_with_rmb:
			# TODO: Properties menu
			OS.alert("This will open up the properties menu...")
			break
		if _col is EditorAddableSpecial && !_col.deletable:
			break
		# Check if found object is of the same type as the selected object
		if editor_options.erase_with_rmb && (
			(
				_col.get_meta(&"nameid") == selected_object.get_meta(&"nameid") &&
				editor_options.erase_specific_object
			) || !editor_options.erase_specific_object
		):
			_col.queue_free()
			%AudioBlockErase.play()
			changes_after_save = true


func _input_paint_object() -> void:
	if !selected_object is EditorAddableNode2D:
		printerr("Selected object is invalid")
		return
	var _section_node = Editor.current_level.get_section(section)
	selected_object._paint_object(_section_node, mouse_clicked_once)


func tileset_selected() -> void:
	var tile_parent: Node2D = Editor.current_level.get_section(section).get_node_or_null("tile")
	var _tilemap = tile_parent.get_node_or_null(selected_tileset.name_id)
	for i in get_tree().get_nodes_in_group(&"editor_addable_tilemap"):
		if i == _tilemap: continue
		if i is TileMapLayer:
			if len(i.get_used_cells()) == 0:
				i.queue_free()
	if _tilemap && _tilemap.has_meta(&"editor_tileset"):
		selected_tile_holder.tilemap = _tilemap
		return
	var old_tiles: PackedByteArray
	if _tilemap && !_tilemap.has_meta(&"editor_tileset"):
		old_tiles = _tilemap.tile_map_data
		_tilemap.free.call_deferred()
	var _new_tilemap = E_TILEMAP.instantiate()
	_new_tilemap.tile_set = selected_tileset.tileset
	_new_tilemap.name = selected_tileset.name_id
	if old_tiles:
		_new_tilemap.tile_map_data = old_tiles
	tile_parent.add_child.call_deferred(_new_tilemap)
	(func():
		_new_tilemap.owner = Editor.current_level
		_new_tilemap.set_meta(&"editor_tileset", Editor.scene.selected_tileset)
		selected_tile_holder.tilemap = _new_tilemap
	).call_deferred()


func select_paint(category_name: String, from_menu: bool = true) -> void:
	tool_mode = TOOL_MODES.PAINT
	editing_sel = _edit_sel_to_enum(category_name)
	selected = []
	_on_selected_array_change()
	object_to_paint_selected(from_menu)


func switch_tile_by(amount: int) -> void:
	var play_sound: bool
	match editing_sel:
		EDIT_SEL.TILE:
			var tile_index: int = selected_tile_holder.tiles.find(selected_tile_holder.id)
			var old_index = tile_index
			tile_index = clampi(tile_index + amount, 0, len(selected_tile_holder.tiles) - 1)
			if old_index != tile_index:
				selected_tile_holder.id = selected_tile_holder.tiles[tile_index]
				play_sound = true
	
	if play_sound:
		EditorAudio.menu_accept()
		tool_mode = TOOL_MODES.PAINT


func section_switched(to: int) -> void:
	if to < 1 || to > 10: return
	EditorAudio.kick(0)
	editor_cache.section_camera_pos[section] = Editor.camera.global_position
	section = to
	var section_node = Editor.current_level.get_section(to)
	section_switched_to.emit(to)
	if editor_cache.section_camera_pos.has(to):
		Editor.camera.global_position = editor_cache.section_camera_pos[to]
	else:
		Editor.camera.global_position = section_node.global_position + Vector2(448, 224)
	Editor.camera.reset_physics_interpolation()
	%PropertiesTabs.update_section_values()


func get_pos_on_grid(forced_grid: bool = false) -> Vector2:
	#var _offset: Vector2 = %SelectedObjTexture.size / 2.0
	var _offset: Vector2 = Editor.grid_offset + Vector2.ONE * 16
	var _grid_pos = Vector2( (get_global_mouse_position().round() - _offset) / Editor.grid_size ).round() * Editor.grid_size
	return _grid_pos + Vector2.ONE * 16 if Editor.grid_shown || forced_grid else get_global_mouse_position().round() #- Vector2.ONE * 16

func get_tile_pos_on_grid() -> Vector2:
	var tile_grid = 32
	var _offset := (Vector2.ONE * 16) + get_sectioned_pos(Vector2.ZERO)
	return _offset + Vector2(
		(Editor.current_level.get_section(section).get_local_mouse_position().round() - _offset) / tile_grid
	).round() * tile_grid

func get_sectioned_pos(pos: Vector2) -> Vector2:
	return Vector2(0, (section - 1) * LevelEdited.SECTION_POS_Y_VALUE) + pos

func can_draw() -> bool:
	if %ObjectPickMenu.visible:
		return false
	var dr2 = control.get_rect()
	dr2.size -= 4 * Vector2.ONE
	dr2 = dr2.abs()
	return (
		%DrawArea.get_rect().has_point(%DrawArea.get_local_mouse_position()) &&
		dr2.has_point(control.get_local_mouse_position()) &&
		!%ZoomContainer.get_rect().has_point(%ZoomContainer.get_global_mouse_position())
	)

func can_draw_not_blocked() -> bool:
	return can_draw() && !mouse_blocked


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
	text = tr("Error: %s") % text
	notify(text, Color.FIREBRICK)
	
func notify_warn(text: String) -> void:
	text = tr("Warning: %s") % text
	notify(text, Color.YELLOW)


func object_pick_menu_close(play_sound: bool = true) -> void:
	if !%ObjectPickMenu.visible:
		return
	%ObjectPickMenu.hide()
	if play_sound:
		EditorAudio.menu_close()
	editor_options.erase_with_rmb = %EraseWithRMB.button_pressed
	editor_options.erase_specific_object = %EraseSpecificObject.button_pressed
	editor_options.use_tile_terrains = %UseTileTerrains.button_pressed


func save_level(path: String, forced_dialog: bool = false) -> bool:
	if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift") || forced_dialog:
		%SaveFileDialog.deselect_all()
		if %SaveFileDialog.current_file.is_empty():
			%SaveFileDialog.current_file = "MyLevel"
		if %SaveFileDialog.current_dir == "user://":
			%SaveFileDialog.current_dir = "user://User Data/Levels"
		%SaveFileDialog.show()
		await %SaveFileDialog.visibility_changed
		if %SaveFileDialog.current_path:
			path = %SaveFileDialog.current_path
		else:
			notify_warn(tr("Level was not saved."))
			return false
	
	var to_save := PackedScene.new()
	var _lvl: LevelEdited = Editor.current_level
	if !_lvl:
		notify_error(tr("Failed to save level."))
		Editor.level_path = ""
		return false
	
	# saving level properties
	var _level_props = Editor.current_level.get_node_or_null("LevelProperties")
	if !_level_props:
		var _new_node = Node.new()
		_new_node.name = "LevelProperties"
		_new_node.set_script(preload("uid://cuj30d6nnmpec"))
		Editor.current_level.add_child(_new_node, true)
		_level_props = _new_node
	
	_level_props.properties = Editor.current_level_properties.duplicate(true)
	
	var _editor_player
	if Thunder._current_player:
		Thunder._current_player.reparent(self)
		_editor_player = Thunder._current_player
	var player = E_PLAYER.instantiate()
	_lvl.add_child(player, true)
	Thunder.reorder_top(player)
	player.global_position = Editor.current_level_properties.player_position
	
	for i in _lvl.get_children():
		i.owner = _lvl
	
	var err = to_save.pack(_lvl)
	if err != OK:
		notify_error(tr("Save failed: %s") % error_string(err))
		player.free()
		_editor_player.reparent(_lvl)
		Thunder._current_player = _editor_player
		Editor.level_path = ""
		return false
	#if path.get_extension().is_empty():
	#	path += ".tscn"
	print(path)
	var er = ResourceSaver.save(to_save, path, ResourceSaver.FLAG_COMPRESS)
	player.free()
	_editor_player.reparent(_lvl)
	Thunder._current_player = _editor_player
	#Thunder._current_player.suit = CharacterManager.get_suit(Thunder._current_player_state.name)
	if er != OK:
		notify_error(tr("Save failed: %s") % error_string(er))
		Editor.level_path = ""
		return false
	changes_after_save = false
	Editor.level_path = path
	notify(tr("Level saved!"))
	return true


func load_level(path) -> bool:
	Editor.is_loading = true
	selected = []
	_on_selected_array_change()
	editor_cache = EditorCacheData.new()
	editing_sel = EDIT_SEL.NONE
	var res: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	#var res = load(path)
	if !res:
		notify_error(tr("Failed to load: Data is corrupted"))
		Editor.level_path = ""
		Editor.is_loading = false
		return false
	
	var _editor_player = Thunder._current_player
	if _editor_player:
		_editor_player.queue_free()
	
	var new_level := res.instantiate()
	if !new_level:
		notify_error(tr("Failed to load: Scene is corrupted"))
		Editor.level_path = ""
		Editor.is_loading = false
		return false
	if !new_level is LevelEdited:
		notify_error(tr("This is not a valid level."))
		Editor.level_path = ""
		Editor.is_loading = false
		new_level.free.call_deferred()
		return false
	
	# Removing unnecessary garbage scenes resulting from live-testing in editor
	for i in get_children():
		if i.is_in_group(&"editor_internal_object"): continue
		i.queue_free()
	add_child(new_level, false)
	
	var _level_props = new_level.get_node_or_null("LevelProperties")
	if _level_props && "properties" in _level_props:
		if _level_props.properties.get("level_major_version") < ProjectSettings.get_setting("application/thunder_settings/major_version", 1):
			notify_error(tr("Failed to load: Incompatible Version"))
			Editor.level_path = ""
			Editor.is_loading = false
			new_level.free.call_deferred()
			return false
		Editor.current_level_properties = _level_props.properties.duplicate(true)
	else:
		notify_error(tr("Failed to load: Missing LevelProperties"))
		Editor.level_path = ""
		Editor.is_loading = false
		new_level.free.call_deferred()
		return false
	
	# Forcefully removing old level and immediately assigning a new one
	if Editor.current_level:
		Editor.current_level.free()
	Editor.current_level = new_level
	Thunder.reorder_top(new_level)
	#add_child.call_deferred(new_level, false)
	#Editor.set_deferred(&"current_level", new_level)
	#Thunder.reorder_top.call_deferred(new_level)
	
	%PropertiesTabs.update_input_values()
	%PropertiesTabs.update_section_values()
	
	if Editor.mode == Editor.MODE.EDITOR:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED,
			&"editor_addable_object", &"_prepare_editor", false
		)
	Editor.is_loading = false
	Editor.level_path = path
	changes_after_save = false
	notify.call_deferred(tr("Level loaded with %d objects!") % [
		get_tree().get_node_count_in_group(&"editor_addable_object")
	])
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
		%ObjectName.text = tr("%d objects selected") % [selected.size()]
		var first_meta = selected[0].get_meta(&"nameid")
		for item in selected:
			if item.get_meta(&"nameid") != first_meta:
				for i in %PropListContainer.get_children():
					i.queue_free()
				break
	elif len(selected) == 0:
		%ObjectName.text = "" # NO_TRANSLATE
		for i in %PropListContainer.get_children():
			i.queue_free()
	elif len(selected) == 1:
		for i in %PropListContainer.get_children():
			i.queue_free()
		%ObjectName.text = '"%s"' % [selected[0].translated_name if selected[0].get(&"translated_name") else selected[0].name]
		#var prop_list: Array[Dictionary] = selected[0].get_property_list()
		#var wait_for: int = -1
		#var _inst = load(selected[0].scene_path).instantiate()
		#var instance_prop_list: Array[Dictionary] = _inst.get_property_list()
		#for property in instance_prop_list:
			#if !(property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) || property.usage == 4096:
				#continue
			#if property.name == "sprite": continue
			#print(property.usage)
			#_add_prop(property, _inst)
			
		#for property in prop_list:
			#var prop_name = property.name
			#if prop_name != "modulate":
				#if wait_for != -1 && property.usage != wait_for:
					#continue
				#else:
					#wait_for = -1
			#if property.usage & PROPERTY_USAGE_CATEGORY && prop_name in ["Node", "CanvasItem"]:
				#wait_for = PROPERTY_USAGE_CATEGORY
				#print("Waiting")
				#if prop_name != "CanvasItem":
					#continue
			#if prop_name.begins_with("global_") || prop_name.begins_with("process_") || prop_name.begins_with("metadata") || property.name in [
				#"rotation", "transform", "script"
			#]:
				#continue
			#
			#if property.usage & PROPERTY_USAGE_INTERNAL || property.usage == 4102:
				#continue
			#if property.usage & PROPERTY_USAGE_CATEGORY:
				#prints("CAT:",property.usage, prop_name)
				#var _prop_cat = PROP_CAT_CONTAINER.instantiate()
				#_prop_cat.custom_minimum_size.y = 21
				#var label: Label = _prop_cat.get_child(0)
				#label.text = prop_name
				#label.add_theme_font_size_override("font_size", 15)
				#%PropListContainer.add_child(_prop_cat)
				#continue
			#if property.usage & PROPERTY_USAGE_GROUP:
				#if prop_name in ["Material", "Texture"]:
					#wait_for = PROPERTY_USAGE_GROUP
					#continue
				#
				# #var _prop_cat = PROP_CAT_CONTAINER.instantiate()
				# #var label: Label = _prop_cat.get_child(0)
				# #label.text = prop_name
				# #label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				# #label.add_theme_color_override("font_color", Color.WHITE)
				# #label.remove_theme_font_override(&"font")
				# #%PropListContainer.add_child(_prop_cat)
				#continue
			#
			#print(property.usage)
			#_add_prop(property, selected[0])

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


func object_to_paint_selected(from_menu: bool = false) -> void:
	if from_menu:
		object_pick_menu_close()


func pick_block() -> bool:
	
	if editing_sel != EDIT_SEL.TILE: return false
	var _tile_pos: Vector2i = get_tile_pos_on_grid() / 32
	if selected_tile_holder && is_instance_valid(selected_tile_holder.tilemap):
		var _tile: int = selected_tile_holder.tilemap.get_cell_source_id(_tile_pos)
		if _tile != -1:
			selected_tile_holder.id = selected_tile_holder.tilemap.get_cell_atlas_coords(_tile_pos)
			selected_tile_holder.source_id = _tile
			selected_tile_holder.alt_tile = selected_tile_holder.tilemap.get_cell_alternative_tile(_tile_pos)
			selected_tile_holder.terrain = -1
			selected_tile_holder.terrain_set = -1
			return true
	for i in Editor.current_level.get_section(section).get_node("tile").get_children():
		if !i.has_meta(&"editor_tileset"):
			continue
		if i is TileMapLayer && i.get_cell_source_id(_tile_pos) > -1:
			%TabContainer.get_child(0)._on_editor_tileset_selected(
				i.get_cell_source_id(_tile_pos), i.get_meta(&"editor_tileset")
			)
			#selected_tile_holder = TileHolder.new()
			#selected_tile_holder.tilemap = i
			selected_tile_holder.id = i.get_cell_atlas_coords(_tile_pos)
			#selected_tile_holder.source_id = i.get_cell_source_id(_tile_pos)
			selected_tile_holder.alt_tile = i.get_cell_alternative_tile(_tile_pos)
			#selected_tile_holder.tiles = []
			#var _tileset: TileSet = selected_tile_holder.tilemap.tile_set
			#var _source = _tileset.get_source(selected_tile_holder.source_id)
			# #if _tileset.get_terrain_sets_count() > 0:
			# #	selected_tile_holder.tiles.append(Vector2(-1, -1))
			#selected_tile_holder.tiles.resize(_source.get_tiles_count())
			#for j in _source.get_tiles_count():
				#selected_tile_holder.tiles[j] = _source.get_tile_id(j)
			#selected_tileset = i.get_meta(&"editor_tileset")
			return true
	
	return false


func is_paint_tool() -> bool:
	return tool_mode in [TOOL_MODES.PAINT, TOOL_MODES.RECT, TOOL_MODES.LINE]


func stash_selected_object(set_empty: bool = true) -> void:
	editor_cache.stored_category_sel[editing_sel] = selected_object
	if set_empty:
		selected_obj_sprite.texture = null
		%SelectedObjDisplay.texture = null
		%SelectedObjControl.visible = false
		selected_object = null


func apply_stored_selection_object(override: Node2D = null) -> void:
	var _stored_obj = editor_cache.stored_category_sel[editing_sel] if !override else override
	if !is_instance_valid(_stored_obj):
		return
	selected_obj_sprite.texture = _stored_obj.editor_icon
	%SelectedObjDisplay.texture = _stored_obj.editor_icon
	%SelectedObjControl.visible = true
	selected_object = _stored_obj
	%SelectedObjLabel.text = tr("Painting %s") % [_stored_obj.translated_name]
	selected_obj_sprite.offset = Vector2.ZERO
	if !is_instance_valid(selected_object) && len(selected) == 1:
		selected_object = selected[0]
		return


## -- Select tool ready functions --
func _tool_select() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%SelectMode.button_pressed = true
	stash_selected_object(true)
	%SelectedObjLabel.text = \
		tr("Left click an object to select it.\nRight click to display its properties.\nClick with Shift for multiple.")

func _tool_pan() -> void:
	control.set_default_cursor_shape(Control.CURSOR_DRAG)
	%PanMode.button_pressed = true
	stash_selected_object(true)
	%SelectedObjLabel.text = tr("Panning mode")

func _tool_list() -> void:
	control.set_default_cursor_shape(Control.CURSOR_HELP)
	%ListMode.button_pressed = true
	stash_selected_object(true)
	%SelectedObjLabel.text = tr("List mode")

func _tool_paint() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%PaintMode.button_pressed = true
	var _sel_obj = selected_object if is_instance_valid(selected_object) else selected[0] if len(selected) == 1 else null
	if _sel_obj == null && editing_sel != EDIT_SEL.TILE:
		_sel_obj = editor_cache.stored_category_sel[editing_sel]
	if is_instance_valid(_sel_obj):
		apply_stored_selection_object(_sel_obj)
	elif selected_tile_holder && selected_tileset && editing_sel == EDIT_SEL.TILE:
		%SelectedObjControl.visible = true
		%SelectedObjLabel.text = tr("Painting Tileset: %s") % [selected_tileset.translated_name]
		var tile_source: TileSetAtlasSource = selected_tileset.tileset.get_source(selected_tile_holder.source_id)
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = tile_source.texture
		if selected_tile_holder.id.x > -1:
			atlas_texture.region = tile_source.get_tile_texture_region(selected_tile_holder.id)
			selected_obj_sprite.texture = atlas_texture
			selected_obj_sprite.offset = -Vector2(
				tile_source.get_tile_data(selected_tile_holder.id, 0).texture_origin
			)
		else:
			selected_obj_sprite.texture = preload("uid://dxx5wntq6ggux")
			selected_obj_sprite.offset = Vector2.ZERO
		%SelectedObjDisplay.texture = atlas_texture
		
	else:
		selected_obj_sprite.texture = null
		%SelectedObjDisplay.texture = null
		%SelectedObjControl.visible = false
		selected_obj_sprite.offset = Vector2.ZERO
		var _event: String = tr(&"Space", &"key")
		var _new_event: String
		for i in InputMap.action_get_events(&"ui_menu_toggle"):
			if i is InputEventKey:
				_new_event = i.as_text().get_slice(' (', 0)
				break
		# NO_TRANSLATE
		if _new_event != "Space": _event = _new_event
		%SelectedObjLabel.text = tr("Nothing to paint. Press %s to pick an object") % [_event.to_upper()]
		
		selected = []
		_on_selected_array_change()

func _tool_pick() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%PickMode.button_pressed = true
	%SelectedObjControl.visible = false
	%SelectedObjLabel.text = tr("Pick a tile/object to select for drawing")
	selected = []
	_on_selected_array_change()

func _tool_rect() -> void:
	control.set_default_cursor_shape(Control.CURSOR_BUSY)
	%RectMode.button_pressed = true
	if is_instance_valid(selected_object):
		selected_obj_sprite.texture = selected_object.editor_icon
		%SelectedObjDisplay.texture = selected_object.editor_icon
		%SelectedObjControl.visible = true
		%SelectedObjLabel.text = selected_object.name
		#%SelectedObjTexture.size = %SelectedObjTexture.texture.get_size()
	else:
		selected_obj_sprite.texture = null
		%SelectedObjDisplay.texture = null
		%SelectedObjControl.visible = false
		%SelectedObjLabel.text = str("")
		#%SelectedObjTexture.texture = null

func _tool_erase() -> void:
	control.set_default_cursor_shape(Control.CURSOR_ARROW)
	%EraseMode.button_pressed = true
	%SelectedObjControl.visible = false
	%SelectedObjLabel.text = tr("Erase mode")
	selected = []
	_on_selected_array_change()


## -- Select tool process functions --
func _tool_select_process() -> void:
	selected_obj_sprite.global_position = get_pos_on_grid()
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
	selected_obj_sprite.visible = can_draw() && !%ShapeCast2D.is_colliding()
	
	if Input.is_action_just_pressed(&"ui_editor_1"):
		switch_tile_by(-1)
	if Input.is_action_just_pressed(&"ui_editor_2"):
		switch_tile_by(1)
	if Input.is_action_just_pressed(&"ui_editor_3"):
		switch_tile_by(-10)
	if Input.is_action_just_pressed(&"ui_editor_4"):
		switch_tile_by(10)
	
	if !can_draw():
		return
	selected_obj_sprite.self_modulate.a = 0.0 if Input.is_action_pressed(&"a_ctrl") else 0.5
	if editing_sel != EDIT_SEL.TILE && is_instance_valid(selected_object):
		selected_obj_sprite.global_position = selected_object.get_editor_sprite_pos()
	elif editing_sel == EDIT_SEL.TILE && selected_tile_holder:
		selected_obj_sprite.global_position = get_tile_pos_on_grid()
	
	selected_obj_sprite.reset_physics_interpolation()

func _tool_pick_process() -> void:
	pass

func _tool_rect_process() -> void:
	pass

func _tool_erase_process() -> void:
	selected_obj_sprite.visible = false
	%SelectedObjTexture.visible = false
	selected_obj_sprite.global_position = get_pos_on_grid()
	selected_obj_sprite.reset_physics_interpolation()
	if editing_sel > EDIT_SEL.NONE:
		%SelectedObjLabel.text = tr("Erasing: %s Category") % tr(%EditingMenuButton.get_item_text(editing_sel))
	if editing_sel == EDIT_SEL.TILE:
		# TODO: Tile erasing
		return
	%ShapeCastPoint.force_shapecast_update()
	var _col = %ShapeCastPoint.is_colliding()
	control.set_default_cursor_shape(Control.CURSOR_FORBIDDEN if _col else Control.CURSOR_ARROW)
	if can_draw_not_blocked() && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		for i in %ShapeCastPoint.get_collision_count():
			var _sele = %ShapeCastPoint.get_collider(i)
			if !_sele || !_sele.has_node(".."): continue
			var _par = _sele.get_parent()
			if !_par is EditorAddableNode2D: continue
			if _par is EditorAddableSpecial && !_par.deletable:
				continue
			_par.queue_free()
			EditorAudio.kick()
			changes_after_save = true


static func _edit_sel_to_enum(edit_sel_string: String) -> EDIT_SEL:
	match edit_sel_string:
		"none": return EDIT_SEL.NONE
		"tile": return EDIT_SEL.TILE
		"scenery": return EDIT_SEL.SCENERY
		"enemy": return EDIT_SEL.ENEMY
		"bonus": return EDIT_SEL.BONUS
		"misc": return EDIT_SEL.MISC
		"special": return EDIT_SEL.SPECIAL
	return EDIT_SEL.MISC


func restart() -> void:
	pass


## Used to store what tile is currently selected to draw.
class TileHolder:
	var source_id: int
	var id: Vector2i
	var terrain: int = -1
	var terrain_set: int = -1
	var alt_tile: int = 0
	var tiles: Array[Vector2i]
	var tilemap: TileMapLayer

## Used to store editor-specific cache data for the current session.
class EditorCacheData:
	var section_camera_pos: Dictionary[int, Vector2]
	var stored_category_sel: Array[Node2D]
	var stored_category_tileset: Dictionary
	var stored_category_tile_holder: TileHolder
	
	func _init() -> void:
		stored_category_sel.resize(EDIT_SEL.MAX)
