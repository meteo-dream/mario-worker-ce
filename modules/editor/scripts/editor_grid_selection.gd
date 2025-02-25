extends Node2D

#var last_pos: Vector2

#func _process(delta: float) -> void:
	#var pos = Editor.scene.get_pos_on_grid()
	#if !Editor.is_window_active(): return
	#if pos != last_pos:
		#queue_redraw()
		#last_pos = pos

func _draw() -> void:
	if Editor.scene == null: return
	
	for i in Editor.scene.selected:
		for j in i.get_children():
			if j is Sprite2D:
				draw_set_transform(j.global_position)
				draw_rect(j.get_rect(), Color.CORAL, false, -1, false)
				print(j.get_rect())
