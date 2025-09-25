@tool
extends "res://engine/components/cam_area/cam_area.gd"

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if Editor.mode != Editor.MODE.EDITOR:
		super(_delta)


func _draw() -> void:
	if !Engine.is_editor_hint() && Editor.mode != Editor.MODE.EDITOR:
		return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	var color = Color.DARK_CYAN if len(_det_areas) > 0 else Color.AQUA
	draw_rect(get_global_rect().grow(2).abs(), color, false, 4)
