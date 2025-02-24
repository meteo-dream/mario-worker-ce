extends PlayerCamera2D

func _ready() -> void:
	if Editor.mode == 0:
		super()
	Thunder._current_camera = self
