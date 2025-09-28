extends Node2D

var last_pos: Vector2
var could_draw: bool

func _physics_process(delta: float) -> void:
	var pos = Editor.scene.get_pos_on_grid()
	if !Editor.is_window_active(): return
	var can_draw: bool = Editor.scene.can_draw_not_blocked()
	if pos != last_pos || can_draw:
		could_draw = can_draw
		queue_redraw()
		last_pos = pos

func _draw() -> void:
	if (
		could_draw &&
		Editor.scene.tool_mode in [LevelEditor.TOOL_MODES.PAINT] &&
		Editor.scene.editing_sel in [LevelEditor.EDIT_SEL.TILE]
	):
		var size = Editor.grid_size
		#var mouse_cursor := get_global_mouse_position()
		var pos = Editor.scene.get_pos_on_grid(true)
		draw_rect(Rect2(pos - Vector2.ONE * 16, size), Color.ORANGE, false)
	
	if !Editor.grid_shown: return
	
	if Editor.scene.tool_mode == LevelEditor.TOOL_MODES.ERASE:
		var size = Editor.grid_size
		#var mouse_cursor := get_global_mouse_position()
		var pos = Editor.scene.get_pos_on_grid()
		draw_rect(Rect2(pos - Vector2.ONE * 16, size), Color.RED, false)
