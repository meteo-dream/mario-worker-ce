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
	
	for sel in Editor.scene.selected:
		var j = Editor.find_child_by_type(sel, CollisionShape2D)
		if !j: continue
		draw_set_transform(j.global_position)
		draw_rect(j.shape.get_rect(), Color.CORAL, false, -1, false)
		#var c := Color.CORAL
		#var xform: Transform2D = j.global_transform * get_viewport_transform()
		#var unscaled_transform: Transform2D = (xform * j.global_transform.affine_inverse() * j.global_transform).orthonormalized();
		#draw_set_transform(xform.get_origin(), 0.0, get_viewport_transform().affine_inverse().get_scale())
		#draw_set_transform_matrix(xform)
		#print(xform)
		#var rect = j.shape.get_rect()
		#var endpoints: Array[Vector2] = [
			#xform.basis_xform(rect.position),
			#xform.basis_xform(rect.position + Vector2(rect.size.x, 0)),
			#xform.basis_xform(rect.position + rect.size),
			#xform.basis_xform(rect.position + Vector2(0, rect.size.y))
		#]
		#for i in 4:
			#draw_line(endpoints[i], endpoints[(i + 1) % 4], c, round(2 * Editor.editor_scale))
		#print(j.shape.get_rect())
