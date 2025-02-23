extends Node2D

@export
var grid_size: Vector2 = Vector2.ONE * 32.0 :
	set(value):
		grid_size = value
@export
var grid_offset: Vector2:
	set(value):
		grid_offset = value

@export
var color: Color = Color.DIM_GRAY :
	set(value):
		queue_redraw()
		color = value

func _ready() -> void:
	%GridButton.button_pressed = Editor.grid_shown
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


func _draw():
	if !Editor.camera: return
	var vp_size: = get_viewport_rect().size
	var cam_pos: = Editor.camera.get_screen_center_position()
	var vp_right: = vp_size.x + cam_pos.x
	var vp_bottom: = vp_size.y + cam_pos.y
	
	if Editor.grid_shown:
		var leftmost: = -vp_right + cam_pos.x
		var topmost: = -vp_bottom# + cam_pos.y
		
		var left: float = ceil(leftmost / grid_size.x) * grid_size.x
		var bottommost: = vp_size.y + cam_pos.y
		for x in range(0, (vp_right / grid_size.x) * 2 + 1):
			draw_line(Vector2(left, topmost), Vector2(left, bottommost), color)
			left += grid_size.x
	#
		var top: float = ceil(topmost / grid_size.y) * grid_size.y
		var rightmost: = vp_right + cam_pos.x
		for y in range(0, (vp_bottom / grid_size.y) * 2 + 1):
			draw_line(Vector2(leftmost, top), Vector2(rightmost, top), color)
			top += grid_size.y
	
	draw_line(Vector2(0, vp_bottom),Vector2(0, -vp_bottom), Color.GREEN - Color(Color.BLACK, 0.2))
	draw_line(Vector2(vp_right, 0),Vector2(-vp_right, 0), Color.RED - Color(Color.BLACK, 0.2))


func _on_grid_button_pressed() -> void:
	Editor.grid_shown = !Editor.grid_shown
	queue_redraw()
