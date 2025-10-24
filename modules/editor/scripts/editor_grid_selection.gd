extends Node2D

#var last_pos: Vector2

func _ready() -> void:
	Editor.camera.zoomed.connect(queue_redraw, CONNECT_DEFERRED)

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
		#draw_set_transform(j.global_position)
		#draw_rect(j.shape.get_rect(), Color.CORAL, false, -1, false)
		
		var c := Color.CORAL
		var xform: Transform2D = j.global_transform
		draw_set_transform_matrix(xform)
		var rect = j.shape.get_rect()
		var endpoints: Array[Vector2] = [
			xform.basis_xform(rect.position),
			xform.basis_xform(rect.position + Vector2(rect.size.x, 0)),
			xform.basis_xform(rect.position + rect.size),
			xform.basis_xform(rect.position + Vector2(0, rect.size.y))
		]
		for i in 4:
			draw_line(
				endpoints[i], endpoints[(i + 1) % 4], c,
				round(2 * Editor.editor_scale) / Editor.camera.zoom.x
			)
		#print(j.shape.get_rect())
