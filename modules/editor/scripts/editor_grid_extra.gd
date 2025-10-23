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
	var tile_picking: bool = (
		(Editor.scene.is_paint_tool() || Editor.scene.tool_mode == LevelEditor.TOOL_MODES.SELECT) &&
		Input.is_action_pressed(&"a_ctrl") && !Input.is_action_pressed(&"a_shift")
	) || Editor.scene.tool_mode == LevelEditor.TOOL_MODES.PICKER
	
	var color := Color.ORANGE if !tile_picking else Color.MAGENTA
	var is_paint_tool: bool = (
		Editor.scene.is_paint_tool() ||
		Editor.scene.tool_mode == LevelEditor.TOOL_MODES.PICKER
	)
	
	if (
		could_draw && (is_paint_tool || tile_picking) &&
		Editor.scene.editing_sel in [LevelEditor.EDIT_SEL.TILE]
	):
		var size = Vector2.ONE * 32
		#var mouse_cursor := get_global_mouse_position()
		var pos = Editor.scene.get_tile_pos_on_grid()
		draw_rect(Rect2(pos - Vector2.ONE * 16, size), color, false)
		return
	
	if !Editor.grid_shown: return
	
	if Editor.scene.tool_mode == LevelEditor.TOOL_MODES.ERASE:
		var size = Vector2.ONE * 32
		#var mouse_cursor := get_global_mouse_position()
		var pos: Vector2
		if Editor.scene.editing_sel != LevelEditor.EDIT_SEL.TILE:
			pos = Editor.scene.get_pos_on_grid()
		else:
			pos = Editor.scene.get_tile_pos_on_grid()
			#size = Vector2.ONE * 32
		draw_rect(Rect2(pos - Vector2.ONE * 16, size), Color.RED, false)
