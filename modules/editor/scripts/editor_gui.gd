extends Control

@onready var properties_tabs: TabContainer = %PropertiesTabs
@onready var top_box_left: HBoxContainer = %TopBoxLeft
@onready var top_box_right: HBoxContainer = %TopBoxRight
var _audio_workaround: int

func _ready() -> void:
	Editor.gui = self
	%SelectMode.button_group.pressed.connect(_on_button_group_pressed)
	resized.connect(_on_window_resized, CONNECT_DEFERRED)
	%CloseConfirmationDialog.add_button(tr("Don't Save", &"Close confirmation dialog"), true, "dontsave")
	Thunder.reorder_bottom(%CloseConfirmationDialog.get_cancel_button())
	Thunder.reorder_bottom(%CloseConfirmationDialog.get_cancel_button().get_parent().get_child(3))
	Thunder._connect(%CloseConfirmationDialog.confirmed, _on_save_level_button_pressed.bind(true))
	Thunder._connect(%CloseConfirmationDialog.custom_action, _on_dontsave)
	_on_tab_container_tab_selected(%TabContainer.current_tab)
	
	_update_grid_spinbox(%GridOffset1, Editor.config.grid_offset_x)
	_update_grid_spinbox(%GridOffset2, Editor.config.grid_offset_y)
	_update_grid_spinbox(%GridStep1, Editor.config.grid_size_x)
	_update_grid_spinbox(%GridStep2, Editor.config.grid_size_y)
	_update_grid_spinbox(%GridPrimaryLine1, Editor.config.grid_primary_line_x, true)
	_update_grid_spinbox(%GridPrimaryLine2, Editor.config.grid_primary_line_y, true)


func disable_toolbar_buttons() -> void:
	%PlayButton.disabled = true
	#%SelectMode.disabled = true
	%ListMode.disabled = true
	%PickMode.disabled = true
	%RotateLeft.disabled = true
	%RotateRight.disabled = true
	%LoadLevelButton.disabled = true
	%SaveLevelButton.disabled = true
	%EditingMenuButton.disabled = true

func enable_toolbar_buttons() -> void:
	%PlayButton.disabled = false
	#%SelectMode.disabled = false
	%ListMode.disabled = false
	%PickMode.disabled = false
	%RotateLeft.disabled = false
	%RotateRight.disabled = false
	%LoadLevelButton.disabled = false
	%SaveLevelButton.disabled = false
	%EditingMenuButton.disabled = false


func show_one_dialog(dialog: Window) -> void:
	Editor.show_window(dialog)


func apply_level_properties() -> void:
	if !Editor.current_level_properties:
		Editor.current_level_properties = LevelProperties.new()
	# Main
	Editor.current_level.time = properties_tabs.time_limit.value
	if Editor.current_level.time == 0: Editor.current_level.time = -1
	Editor.current_level_properties.level_name = properties_tabs.level_name.text
	Editor.current_level_properties.level_display_name_1 = properties_tabs.display_name_1.text
	Editor.current_level_properties.level_display_name_2 = properties_tabs.display_name_2.text
	Editor.current_level_properties.level_description = properties_tabs.level_description.text
	Editor.current_level_properties.level_author = properties_tabs.level_author.text
	Editor.current_level_properties.level_author_email = properties_tabs.author_email.text
	Editor.current_level_properties.level_author_website = properties_tabs.author_website.text
	
	# Sections
	for i in Editor.current_level_properties.sections:
		var section = Editor.current_level.get_section(i)
		var gradient: Gradient = section.get_node("Background/GradientLayer/Gradient").texture.gradient
		gradient.set_color(0, properties_tabs.gradient_top.color)
		gradient.set_color(1, properties_tabs.gradient_bottom.color)
		
		Editor.current_level_properties.sections[i].size = Vector2i(
			properties_tabs.section_width.value,
			properties_tabs.section_height.value,
		)
		section.get_node("CamAreas/CamArea").size = Editor.current_level_properties.sections[i].size
	
	# Experimental
	if properties_tabs.widescreen_check_box.button_pressed:
		Editor.current_level_properties.screen_resolution = Vector2i(864, 480)
	else:
		Editor.current_level_properties.screen_resolution = Vector2i(640, 480)


func open_obj_properties(_col) -> void:
	# TODO: Properties menu
	OS.alert("This will open up the properties menu... Properties aren't implemented yet!")


func _on_button_group_pressed(button: BaseButton) -> void:
	match button.name:
		"SelectMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.SELECT
		"PanMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAN
		"ListMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.LIST
		"PaintMode":
			Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
			Editor.scene.apply_stored_selection_object()
		"PickMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PICKER
		"RectMode":
			Editor.scene.tool_mode = LevelEditor.TOOL_MODES.RECT
			Editor.scene.apply_stored_selection_object()
		"EraseMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.ERASE


func _on_menu_button_item_selected(index: int) -> void:
	Editor.scene.stash_selected_object(true)
	Editor.scene.editing_sel = index
	Editor.scene.apply_stored_selection_object()
	EditorAudio.menu_hover()


var window_old_size: Vector2i
func _on_h_split_container_dragged(_offset: int) -> void:
	window_old_size = get_tree().root.size
	_on_window_resized()

func _on_window_resized() -> void:
	var size_x = %HSplitContainer.size.x
	%HSplitContainer.split_offset -= window_old_size.x - get_tree().root.size.x
	if %HSplitContainer.split_offset > size_x - 144:
		%HSplitContainer.split_offset = size_x - 144
	if %HSplitContainer.split_offset < (size_x / 3):
		%HSplitContainer.split_offset = (size_x / 3)
	_on_v_split_container_dragged(0)
	%VSplitContainer.split_offset -= window_old_size.y - get_tree().root.size.y
	if get_tree().root.size.x / get_tree().root.content_scale_factor <= 1024 && top_box_right.get_parent() == top_box_left:
		top_box_right.reparent(%TopBoxContainer)
	elif get_tree().root.size.x / get_tree().root.content_scale_factor > 1024 && top_box_right.get_parent() == %TopBoxContainer:
		top_box_right.reparent(top_box_left)


func _on_v_split_container_dragged(offset: int) -> void:
	var size_y = %VSplitContainer.size.y
	if %VSplitContainer.split_offset > size_y - 84:
		%VSplitContainer.split_offset = size_y - 84
		return
	var maxsize = maxi(size_y / 6, 80)
	if %VSplitContainer.split_offset < maxsize:
		%VSplitContainer.split_offset = maxsize


func _on_close_editor_button_pressed() -> void:
	if Editor.scene.changes_after_save:
		show_one_dialog(%CloseConfirmationDialog)
	else:
		_on_exit()

func _on_dontsave(action: StringName) -> void:
	if action == &"dontsave": _on_exit()

func _on_exit() -> void:
	#Editor.scene.queue_free()
	Scenes.goto_scene(ProjectSettings.get_setting("application/thunder_settings/main_menu_path"))
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))


func _on_save_level_button_pressed(exit_after_save: bool = false, forced_dialog: bool = false) -> void:
	if !Editor.current_level:
		Editor.scene.notify_error(tr("Save failed."))
		return
	#if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift"):
	#	Thunder._connect(%SaveFileDialog.file_selected, _on_save_dialog_confirmed)
	#	%SaveFileDialog.deselect_all()
	#	%SaveFileDialog.show()
	#	return
	var has_saved = await Editor.scene.save_level(Editor.level_path, forced_dialog)
	if exit_after_save && has_saved:
		Editor.scene.mouse_blocked = true
		Editor.scene.set_process_input(false)
		await get_tree().create_timer(0.4, false, false, true).timeout
		Editor.scene.set_process_input(true)
		_on_exit()

func _on_save_dialog_confirmed(path: String) -> void:
	#%SaveFileDialog.hide()
	#if %SaveFileDialog.close_requested
	Editor.scene.save_level.call_deferred(path)

func _on_load_dialog_confirmed(path: String) -> void:
	#%SaveFileDialog.hide()
	#if %SaveFileDialog.close_requested
	Editor.scene.load_level.call_deferred(path)

func _on_play_level_button_pressed() -> void:
	OS.alert(tr("This button is unimplemented for now, use 'Play Level' from the title screen"))


func _on_play_button_pressed() -> void:
	#if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift"):
		#Thunder._connect(%SaveFileDialog.file_selected, _on_save_dialog_confirmed)
		#%SaveFileDialog.deselect_all()
		#%SaveFileDialog.show()
		#return
	disable_toolbar_buttons()
	
	var has_saved = await Editor.scene.save_level(Editor.level_path)
	if has_saved:
		await get_tree().create_timer(0.4, false, false, true).timeout
		Editor.mode = Editor.MODE.TESTING
		Editor.scene.load_level.call_deferred(Editor.level_path)
		#%LoadFileDialog.show()
		%StopButton.disabled = false
		#Editor.current_level.duplicate()
	else:
		enable_toolbar_buttons()


func _on_load_level_button_pressed() -> void:
	Thunder._connect(%LoadFileDialog.file_selected, _on_load_dialog_confirmed)
	if %LoadFileDialog.current_dir == "user://":
		%LoadFileDialog.current_dir = "user://User Data/Levels"
	show_one_dialog(%LoadFileDialog)


func _on_stop_button_pressed() -> void:
	if Editor.mode == Editor.MODE.TESTING:
		Editor.mode = Editor.MODE.EDITOR
		Editor.scene.load_level.call_deferred(Editor.level_path)
		
	%StopButton.disabled = true
	
	enable_toolbar_buttons()


func _on_level_properties_button_pressed() -> void:
	show_one_dialog(%LevelProperties)


func _on_level_prop_apply_pressed() -> void:
	apply_level_properties()
	Editor.scene.changes_after_save = true

func _on_level_prop_cancel_pressed() -> void:
	%LevelProperties.hide()
	properties_tabs.update_input_values()
	properties_tabs.update_section_values()

func _on_level_prop_ok_pressed() -> void:
	_on_level_prop_apply_pressed()
	%LevelProperties.hide()


func _on_tab_container_tab_selected(tab: int) -> void:
	tab += 1
	(func():
		Editor.scene.stash_selected_object(true)
		Editor.scene.editing_sel = tab
		Editor.scene.apply_stored_selection_object()
		print(tab)
		if _audio_workaround < 2:
			_audio_workaround += 1
			return
		EditorAudio.menu_hover()
	).call_deferred()


func _on_object_picker_button_pressed() -> void:
	%ObjectPickMenu.show()
	EditorAudio.menu_open()


func _on_center_level_button_pressed() -> void:
	var section_y: int = Editor.current_level.SECTION_POS_Y_VALUE * (Editor.scene.section - 1)
	Editor.camera.position = Vector2(448, section_y + 224)
	Editor.camera.reset_physics_interpolation()


func _on_erase_with_rmb_toggled(toggled_on: bool) -> void:
	%EraseSpecificObject.disabled = !toggled_on


func _update_grid_spinbox(obj: SpinBox, init_val: float, is_line: bool = false) -> void:
	obj.value = init_val
	if !is_line:
		_on_grid_value_changed(init_val, obj)
		Thunder._connect(obj.value_changed, _on_grid_value_changed.bind(obj))
	else:
		_on_grid_line_value_changed(init_val, obj)
		Thunder._connect(obj.value_changed, _on_grid_line_value_changed.bind(obj))

func _on_grid_value_changed(to: float, obj: SpinBox) -> void:
	obj.suffix = tr(&"px", &"Grid value suffix")

func _on_grid_line_value_changed(to: float, obj: SpinBox) -> void:
	obj.suffix = tr_n(&"step", &"steps", int(to), &"Grid primary line value suffix")


func _on_more_grid_button_pressed() -> void:
	Editor.show_window(%ConfigureSnapWindow)
