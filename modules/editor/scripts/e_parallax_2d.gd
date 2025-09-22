extends Parallax2D

func _ready() -> void:
	if Editor.mode != Editor.MODE.NONE:
		repeat_times = 10
		return
	repeat_times = 1
