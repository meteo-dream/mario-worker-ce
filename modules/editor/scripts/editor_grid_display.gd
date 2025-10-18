extends Node2D

@export
var grid_size: Vector2 = Vector2.ONE * 16.0 :
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
var primary_line_every: Vector2 = Vector2(2, 2)

@export
var color: Color = Color.DIM_GRAY :
	set(value):
		queue_redraw()
		color = value

@export
var screen_color: Color = Color.DARK_ORANGE :
	set(value):
		queue_redraw()
		screen_color = value


func _ready() -> void:
	grid_size = Vector2(Editor.config.grid_size_x, Editor.config.grid_size_y)
	grid_offset = Vector2(Editor.config.grid_offset_x, Editor.config.grid_offset_y)
	primary_line_every = Vector2(Editor.config.grid_primary_line_x, Editor.config.grid_primary_line_y)
	%GridButton.button_pressed = Editor.grid_shown
	Editor.grid_size = grid_size
	Editor.grid_offset = grid_offset
	queue_redraw()
	%GridButton.pressed.connect(_on_grid_button_pressed)
	%GridOkBtn.pressed.connect(func():
		var _size := Vector2(
			%GridStep1.value,
			%GridStep2.value,
		)
		var _pos := Vector2(
			%GridOffset1.value,
			%GridOffset2.value,
		)
		var _line := Vector2(
			%GridPrimaryLine1.value,
			%GridPrimaryLine2.value,
		)
		grid_size = _size
		grid_offset = _pos
		primary_line_every = _line
		queue_redraw()
		Editor.save_config()
		Editor.config.grid_size_x = _size.x
		Editor.config.grid_size_y = _size.y
		Editor.config.grid_offset_x = _pos.x
		Editor.config.grid_offset_y = _pos.y
		Editor.config.grid_primary_line_x = _line.x
		Editor.config.grid_primary_line_y = _line.y
		%ConfigureSnapWindow.hide()
	)
	%GridCancelBtn.pressed.connect(func():
		%GridStep1.value = grid_size.x
		%GridStep2.value = grid_size.y
		%GridOffset1.value = grid_offset.x
		%GridOffset2.value = grid_offset.y
		%GridPrimaryLine1.value = primary_line_every.x
		%GridPrimaryLine2.value = primary_line_every.y
		%ConfigureSnapWindow.hide()
	)

func _process(delta: float) -> void:
	queue_redraw()
	#Editor.camera.draw.connect(queue_redraw)


func _draw():
	if !Editor.camera: return
	var vp_size := get_viewport_rect().size / Editor.camera.zoom / 2
	var cam_pos := Editor.camera.get_screen_center_position() + Editor.grid_offset
	var vp_center := Vector2.ZERO
	if Editor.current_level_properties.sections[Editor.scene.section].position:
		vp_center = Editor.current_level_properties.sections[Editor.scene.section].position
	var vp_right := vp_size.x
	var vp_bottom := vp_size.y
	
	if Editor.grid_shown:
		_draw_main_grid(vp_size, cam_pos)
	
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


func _draw_main_grid(vp_size: Vector2, cam_pos: Vector2) -> void:
	var screen_size := Vector2i(640, 480)
	var is_tile_selected: bool = Editor.scene.editing_sel == LevelEditor.EDIT_SEL.TILE
	if !is_tile_selected:
		# Generic grid
		for x in range(
			int((cam_pos.x - vp_size.x) / grid_size.x) - 1,
			int((vp_size.x + cam_pos.x) / grid_size.x) + 1
		):
			draw_line(
				Vector2(x * grid_size.x, cam_pos.y + vp_size.y + 1),
				Vector2(x * grid_size.x, cam_pos.y - vp_size.y - 1), Color(color, 0.2)
			)
		for y in range(
			int((cam_pos.y - vp_size.y) / grid_size.y) - 1,
			int((vp_size.y + cam_pos.y) / grid_size.y) + 1
		):
			draw_line(
				Vector2(cam_pos.x + vp_size.x + 1, y * grid_size.y),
				Vector2(cam_pos.x - vp_size.x - 1, y * grid_size.y), Color(color, 0.2)
			)
		# Primary lines of the grid
		for x in range(
			int((cam_pos.x - vp_size.x) / (grid_size.x * primary_line_every.x)) - 1,
			int((vp_size.x + cam_pos.x) / (grid_size.x * primary_line_every.x)) + 1
		):
			draw_line(
				Vector2(x * (grid_size.x * primary_line_every.x), cam_pos.y + vp_size.y + 1),
				Vector2(x * (grid_size.x * primary_line_every.x), cam_pos.y - vp_size.y - 1), Color(color, 0.4)
			)
		for y in range(
			int((cam_pos.y - vp_size.y) / (grid_size.y * primary_line_every.y)) - 1,
			int((vp_size.y + cam_pos.y) / (grid_size.y * primary_line_every.y)) + 1
		):
			draw_line(
				Vector2(cam_pos.x + vp_size.x + 1, y * (grid_size.y * primary_line_every.y)),
				Vector2(cam_pos.x - vp_size.x - 1, y * (grid_size.y * primary_line_every.y)), Color(color, 0.4)
			)
	else:
		var tileset_size: int = 32
		for x in range(
			int((cam_pos.x - vp_size.x) / tileset_size) - 1,
			int((vp_size.x + cam_pos.x) / tileset_size) + 1
		):
			draw_line(
				Vector2(x * tileset_size, cam_pos.y + vp_size.y + 1),
				Vector2(x * tileset_size, cam_pos.y - vp_size.y - 1), Color(Color.ORANGE, 0.3)
			)
		for y in range(
			int((cam_pos.y - vp_size.y) / tileset_size) - 1,
			int((vp_size.y + cam_pos.y) / tileset_size) + 1
		):
			draw_line(
				Vector2(cam_pos.x + vp_size.x + 1, y * tileset_size),
				Vector2(cam_pos.x - vp_size.x - 1, y * tileset_size), Color(Color.ORANGE, 0.3)
			)
	
	# Screen size lines
	for x in range(
		int((cam_pos.x - vp_size.x) / screen_size.x) - 1,
		int((vp_size.x + cam_pos.x) / screen_size.x) + 1
	):
		draw_line(
			Vector2(x * screen_size.x, cam_pos.y + vp_size.y + 1),
			Vector2(x * screen_size.x, cam_pos.y - vp_size.y - 1), Color(screen_color, 0.4)
		)
	for y in range(
		int((cam_pos.y - vp_size.y) / screen_size.y) - 1,
		int((vp_size.y + cam_pos.y) / screen_size.y) + 1
	):
		draw_line(
			Vector2(cam_pos.x + vp_size.x + 1, y * screen_size.y),
			Vector2(cam_pos.x - vp_size.x - 1, y * screen_size.y), Color(screen_color, 0.4)
		)
