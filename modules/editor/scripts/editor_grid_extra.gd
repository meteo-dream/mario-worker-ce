extends Node2D

var last_pos: Vector2

func _process(delta: float) -> void:
	var pos = Editor.scene.get_pos_on_grid()
	if !Editor.is_window_active(): return
	if pos != last_pos:
		queue_redraw()
		last_pos = pos

func _draw() -> void:
	if !Editor.grid_shown: return
	
	if Editor.scene.tool_mode == LevelEditor.TOOL_MODES.ERASE:
		var size = Editor.grid_size
		var mouse_cursor := get_global_mouse_position()
		var pos = Editor.scene.get_pos_on_grid()
		draw_rect(Rect2(pos, size), Color.RED, false)
