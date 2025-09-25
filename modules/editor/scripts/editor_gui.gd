extends Control

@onready var properties_tabs: TabContainer = %PropertiesTabs

func _ready() -> void:
	Editor.gui = self
	%SelectMode.button_group.pressed.connect(_on_button_group_pressed)
	resized.connect(_on_window_resized, CONNECT_DEFERRED)
	%CloseConfirmationDialog.add_button("Don't Save", false, "dontsave")
	Thunder._connect(%CloseConfirmationDialog.confirmed, _on_save_level_button_pressed.bind(true))
	Thunder._connect(%CloseConfirmationDialog.custom_action, _on_dontsave)
	_on_tab_container_tab_selected(%TabContainer.current_tab)


func disable_toolbar_buttons() -> void:
	%PlayButton.disabled = true
	%SelectMode.disabled = true
	%ListMode.disabled = true
	%PickMode.disabled = true
	%RotateLeft.disabled = true
	%RotateRight.disabled = true
	%LoadLevelButton.disabled = true
	%SaveLevelButton.disabled = true

func enable_toolbar_buttons() -> void:
	%PlayButton.disabled = false
	%SelectMode.disabled = false
	%ListMode.disabled = false
	%PickMode.disabled = false
	%RotateLeft.disabled = false
	%RotateRight.disabled = false
	%LoadLevelButton.disabled = false
	%SaveLevelButton.disabled = false


func show_one_dialog(dialog: Window) -> void:
	if dialog.visible:
		if dialog.mode == Window.MODE_MINIMIZED:
			dialog.mode = Window.MODE_WINDOWED
		dialog.grab_focus()
		return
	dialog.show()


func apply_level_properties() -> void:
	if !Editor.current_level_properties:
		Editor.current_level_properties = LevelProperties.new()
	Editor.current_level.time = properties_tabs.time_limit.value
	Editor.current_level_properties.level_name = properties_tabs.level_name.text
	Editor.current_level_properties.level_display_name_1 = properties_tabs.display_name_1.text
	Editor.current_level_properties.level_display_name_2 = properties_tabs.display_name_2.text
	Editor.current_level_properties.level_description = properties_tabs.level_description.text
	Editor.current_level_properties.level_author = properties_tabs.level_author.text
	Editor.current_level_properties.level_author_email = properties_tabs.author_email.text
	Editor.current_level_properties.level_author_website = properties_tabs.author_website.text


func _on_button_group_pressed(button: BaseButton) -> void:
	match button.name:
		"SelectMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.SELECT
		"PanMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAN
		"ListMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.LIST
		"PaintMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
		"PickMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PICKER
		"RectMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.RECT
		"EraseMode": Editor.scene.tool_mode = LevelEditor.TOOL_MODES.ERASE


func _on_menu_button_item_selected(index: int) -> void:
	Editor.scene.editing_sel = index


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
		Editor.scene.notify_error("Save failed.")
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
	OS.alert("This button is unimplemented for now, use 'Play Level' from the title screen")


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
	%LevelProperties.hide()
	Editor.scene.changes_after_save = true


func _on_level_prop_cancel_pressed() -> void:
	%LevelProperties.hide()
	properties_tabs.update_input_values()


func _on_tab_container_tab_selected(tab: int) -> void:
	tab += 1
	(func():
		Audio.play_1d_sound(Editor.scene.MENU_HOVER, true, { bus = "Editor" })
		Editor.scene.editing_sel = tab
	).call_deferred()
