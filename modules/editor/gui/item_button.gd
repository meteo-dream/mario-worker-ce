extends Button

var cached_scene

func _ready() -> void:
	pressed.connect(_on_pressed, CONNECT_DEFERRED)


func _on_pressed() -> void:
	Editor.scene.selected_object = get_child(0)
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor.EDIT_SEL.ENEMY
