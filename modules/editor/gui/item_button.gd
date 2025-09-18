extends Button

var cached_scene


func _on_pressed_add_object(category_name: String) -> void:
	Editor.scene.selected_object = get_child(0)
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor._edit_sel_to_enum(category_name)
	Editor.scene.selected = []
	Editor.scene._on_selected_array_change()
	Editor.scene.object_to_paint_selected(true)


func _on_pressed_add_tileset() -> void:
	Editor.scene.selected_object = get_child(0)
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor.EDIT_SEL.TILE
	Editor.scene.selected = []
	Editor.scene._on_selected_array_change()
	Editor.scene.object_to_paint_selected(true)
	
