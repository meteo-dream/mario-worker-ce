extends Button

@onready var template: String = text

func _ready() -> void:
	text = template % 100
	pressed.connect(func():
		Editor.camera.zoom = Vector2.ONE
		text = template % 100
	)
