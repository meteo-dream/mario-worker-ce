extends PlayerCamera2D

func _ready() -> void:
	if Data.technical_values.get("editor_mode") == 0:
		super()
	Thunder._current_camera = self
