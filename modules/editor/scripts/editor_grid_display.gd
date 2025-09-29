extends Node2D

@export
var grid_size: Vector2 = Vector2.ONE * 32.0 :
	set(value):
		grid_size = value
		Editor.grid_size = value
@export
var grid_offset: Vector2:
	set(value):
		var remainder := Vector2i(
			roundi(value.x) % roundi(grid_size.x),
			roundi(value.y) % roundi(grid_size.y)
		)
		if remainder.x < 0: remainder.x += roundi(grid_size.x)
		if remainder.y < 0: remainder.y += roundi(grid_size.y)
		prints("Grid offset:", remainder)
		grid_offset = remainder
		Editor.grid_offset = remainder

@export
var color: Color = Color.DIM_GRAY :
	set(value):
		queue_redraw()
		color = value

func _ready() -> void:
	%GridButton.button_pressed = Editor.grid_shown
	Editor.grid_size = grid_size
	Editor.grid_offset = grid_offset
	queue_redraw()
	%GridButton.pressed.connect(_on_grid_button_pressed)
	%GridOkBtn.pressed.connect(func():
		var _size := Vector2(
			%ConfigureSnapWindow/VBoxContainer/HBoxContainer2/SpinBox.value,
			%ConfigureSnapWindow/VBoxContainer/HBoxContainer2/SpinBox2.value,
		)
		var _pos := Vector2(
			%ConfigureSnapWindow/VBoxContainer/HBoxContainer/SpinBox.value,
			%ConfigureSnapWindow/VBoxContainer/HBoxContainer/SpinBox2.value,
		)
		grid_size = _size
		grid_offset = _pos
		queue_redraw()
		%ConfigureSnapWindow.hide()
	)
	%GridCancelBtn.pressed.connect(func():
		%ConfigureSnapWindow/VBoxContainer/HBoxContainer2/SpinBox.value = grid_size.x
		%ConfigureSnapWindow/VBoxContainer/HBoxContainer2/SpinBox2.value = grid_size.y
		%ConfigureSnapWindow.hide()
	)

func _process(delta: float) -> void:
	queue_redraw()
	#Editor.camera.draw.connect(queue_redraw)


func _draw():
	if !Editor.camera: return
	var vp_size: = get_viewport_rect().size / Editor.camera.zoom / 2
	var cam_pos: = Editor.camera.get_screen_center_position() + Editor.grid_offset
	var vp_center = Vector2.ZERO
	if Editor.current_level_properties.sections[Editor.scene.section].position:
		vp_center = Editor.current_level_properties.sections[Editor.scene.section].position
	var vp_right: = vp_size.x# + cam_pos.x + Editor.grid_offset.x
	var vp_bottom: = vp_size.y# + cam_pos.y + Editor.grid_offset.y
	
	if Editor.grid_shown:
		for x in range(
			int((cam_pos.x - vp_size.x) / grid_size.x) - 1,
			int((vp_size.x + cam_pos.x) / grid_size.x) + 1
		):
			draw_line(
				Vector2(x * grid_size.x, cam_pos.y + vp_size.y + 1),
				Vector2(x * grid_size.x, cam_pos.y - vp_size.y - 1), color
			)
		for y in range(
			int((cam_pos.y - vp_size.y) / grid_size.y) - 1,
			int((vp_size.y + cam_pos.y) / grid_size.y) + 1
		):
			draw_line(
				Vector2(cam_pos.x + vp_size.x + 1, y * grid_size.y),
				Vector2(cam_pos.x - vp_size.x - 1, y * grid_size.y), color
			)
		#return
		#var leftmost: = -vp_right # + cam_pos.x
		#var topmost: = -vp_bottom # + cam_pos.y
		#
		#var left: float = Editor.grid_offset.x + ceil(leftmost / grid_size.x) * grid_size.x
		#var bottommost: = vp_size.y# + cam_pos.y
		#for x in range(0, (vp_right / grid_size.x) * 2 + 1 + Editor.grid_offset.x):
			#draw_line(Vector2(left, topmost), Vector2(left, bottommost), color)
			#left += grid_size.x
	
		#var top: float = Editor.grid_offset.y + ceil(topmost / grid_size.y) * grid_size.y
		#var rightmost: = vp_right# + cam_pos.x
		#for y in range(0, (vp_bottom / grid_size.y) * 2 + 1 + Editor.grid_offset.y):
			#draw_line(Vector2(leftmost, top), Vector2(rightmost, top), color)
			#top += grid_size.y
	
	var rect := Rect2(Vector2.ZERO, vp_size).abs()
	if rect.has_point(Vector2(cam_pos.abs().x, vp_center.y)):
		draw_line(
			Vector2(vp_center.x, cam_pos.y + vp_bottom),
			Vector2(vp_center.x, cam_pos.y - vp_bottom),
			Color.GREEN - Color(Color.BLACK, 0.2)
		)
	if rect.has_point(Vector2(vp_center.x, cam_pos.abs().y)):
		draw_line(
			Vector2(cam_pos.x + vp_right, vp_center.y),
			Vector2(cam_pos.x - vp_right, vp_center.y),
			Color.RED - Color(Color.BLACK, 0.2)
		)


func _on_grid_button_pressed() -> void:
	Editor.grid_shown = !Editor.grid_shown
	queue_redraw()
