extends PlayerCamera2D

func _ready() -> void:
	if Editor.mode == Editor.MODE.NONE:
		enabled = true
		super()
	Thunder._current_camera = self
