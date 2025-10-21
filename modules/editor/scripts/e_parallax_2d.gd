extends Parallax2D

func _ready() -> void:
	if Editor.mode != Editor.MODE.NONE:
		repeat_times = 12
		return
	repeat_times = 1
	# temporary solution for widescreen and camera height of more than 480
	scroll_scale.y = 0
	repeat_size.x = Editor.screen_size.x
	var gradient = get_node_or_null("Gradient")
	if gradient:
		gradient.texture.width = Editor.screen_size.x
