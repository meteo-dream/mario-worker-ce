extends Camera2D

var zoom_min := 0.5
var zoom_max := 4.0
const ZOOM_INCREMENT: float = 6
#const ZOOM_RATE: float = 8.0
var zoom_speed := 0.1

var _is_dragging: bool
var _target_pos: Vector2
var _target_zoom: float = 1.0
var _skip_scroll: bool

func _ready() -> void:
	Editor.camera = self
	make_current()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if (event.button_mask == MOUSE_BUTTON_MASK_MIDDLE) || (
			Editor.scene.tool_mode == LevelEditor.TOOL_MODES.PAN && event.button_mask == MOUSE_BUTTON_LEFT
		): #&& !_skip_scroll:
			#var rect: Vector2 = get_viewport_rect().size
			#var rect_pos: Vector2 = get_viewport_rect().position
			#if event.position.y < 0:
				#return _wrap_mouse(Vector2(get_viewport().get_mouse_position().x, rect.y))
			#elif event.position.x < 0:
				#return _wrap_mouse(Vector2(rect.x, get_viewport().get_mouse_position().y))
			#elif event.position.y > rect.y:
				#return _wrap_mouse(Vector2(get_viewport().get_mouse_position().x, rect_pos.y))
			#elif event.position.x > rect.x:
				#return _wrap_mouse(Vector2(rect_pos.x, get_viewport().get_mouse_position().y))
			position -= event.relative / zoom
				
			#if event.screen_relative
		
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

func _wrap_mouse(to: Vector2) -> void:
	var last_pos: Vector2 = get_viewport().get_mouse_position()
	_skip_scroll = true
	Input.warp_mouse(to)
	position -= (last_pos - to) / zoom
	_skip_scroll = false


func zoom_in() -> void:
	var current_zoom_step: float = round(log(zoom.x) * 12.0 / log(2.0))
	var new_zoom: float = pow(2.0, (current_zoom_step + ZOOM_INCREMENT) / 12.0)
	var clamped_zoom = minf(new_zoom, zoom_max)
	#print(new_zoom)
	update_zoom(zoom, clamped_zoom * Vector2.ONE)

func zoom_out() -> void:
	var current_zoom_step: float = round(log(zoom.x) * 12.0 / log(2.0))
	var new_zoom: float = pow(2.0, (current_zoom_step - ZOOM_INCREMENT) / 12.0)
	var clamped_zoom = maxf(new_zoom, zoom_min)
	#print(new_zoom)
	update_zoom(zoom, clamped_zoom * Vector2.ONE)

func update_zoom(old_zoom: Vector2, new_zoom: Vector2) -> void:
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	var mouse_x = get_viewport().get_mouse_position().x
	var mouse_y = get_viewport().get_mouse_position().y
	var pixels_difference_x = (screen_width / old_zoom.x) - (screen_width / new_zoom.y)
	var pixels_difference_y = (screen_height / old_zoom.y) - (screen_height / new_zoom.y)
	var side_ratio_x = (mouse_x - (screen_width / 2)) / screen_width
	var side_ratio_y = (mouse_y - (screen_height / 2)) / screen_height
	position.x += pixels_difference_x * side_ratio_x
	position.y += pixels_difference_y * side_ratio_y
	zoom = new_zoom
	if position != get_screen_center_position():
		position = get_screen_center_position()
