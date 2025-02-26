extends Control

func _ready() -> void:
	Editor.gui = self
	%SelectMode.button_group.pressed.connect(_on_button_group_pressed)
	resized.connect(_on_window_resized, CONNECT_DEFERRED)
	%CloseConfirmationDialog.add_button("Don't Save", false, "dontsave")
	Thunder._connect(%CloseConfirmationDialog.confirmed, _on_save_level_button_pressed.bind(true))
	Thunder._connect(%CloseConfirmationDialog.custom_action, _on_dontsave)


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
		%CloseConfirmationDialog.show()
	else:
		_on_exit()

func _on_dontsave(action: StringName) -> void:
	if action == &"dontsave": _on_exit()

func _on_exit() -> void:
	Editor.scene.queue_free()
	Scenes.goto_scene(ProjectSettings.get_setting("application/thunder_settings/main_menu_path"))


func _on_save_level_button_pressed(exit_after_save: bool = false) -> void:
	if !Editor.current_level:
		Editor.scene.notify_error("Save failed.")
		return
	#if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift"):
	#	Thunder._connect(%SaveFileDialog.file_selected, _on_save_dialog_confirmed)
	#	%SaveFileDialog.deselect_all()
	#	%SaveFileDialog.show()
	#	return
	var has_saved = await Editor.scene.save_level(Editor.level_path)
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
	pass # Replace with function body.


func _on_play_button_pressed() -> void:
	#if Editor.level_path.is_empty() || Input.is_action_pressed(&"a_shift"):
		#Thunder._connect(%SaveFileDialog.file_selected, _on_save_dialog_confirmed)
		#%SaveFileDialog.deselect_all()
		#%SaveFileDialog.show()
		#return
	%PlayButton.disabled = true
	%SelectMode.disabled = true
	%ListMode.disabled = true
	%PickMode.disabled = true
	%RotateLeft.disabled = true
	%RotateRight.disabled = true
	%LoadLevelButton.disabled = true
	%SaveLevelButton.disabled = true
	var has_saved = await Editor.scene.save_level(Editor.level_path)
	if has_saved:
		await get_tree().create_timer(0.4, false, false, true).timeout
		Editor.mode = 2
		Editor.scene.load_level.call_deferred(Editor.level_path)
		#%LoadFileDialog.show()
		%StopButton.disabled = false
		#Editor.current_level.duplicate()
	else:
		%PlayButton.disabled = false
		%SelectMode.disabled = false
		%ListMode.disabled = false
		%PickMode.disabled = false
		%RotateLeft.disabled = false
		%RotateRight.disabled = false
		%LoadLevelButton.disabled = false
		%SaveLevelButton.disabled = false


func _on_load_level_button_pressed() -> void:
	Thunder._connect(%LoadFileDialog.file_selected, _on_load_dialog_confirmed)
	%LoadFileDialog.show()


func _on_stop_button_pressed() -> void:
	if Editor.mode == 2:
		Editor.mode = 1
		Editor.scene.load_level.call_deferred(Editor.level_path)
		
	%StopButton.disabled = true
	
	%PlayButton.disabled = false
	%SelectMode.disabled = false
	%ListMode.disabled = false
	%PickMode.disabled = false
	%RotateLeft.disabled = false
	%RotateRight.disabled = false
	%LoadLevelButton.disabled = false
	%SaveLevelButton.disabled = false
