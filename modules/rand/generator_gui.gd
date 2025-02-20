extends Control

@onready var node: Node = $Node
@onready var line_edit: LineEdit = $LineEdit


func _input(event: InputEvent) -> void:
	if !event.is_pressed() || event.is_echo(): return
	if event.is_action("ui_focus_next"):
		line_edit.grab_focus()
	if event.is_action("ui_accept"):
		line_edit.release_focus()
		print("Level is generating")
		node.generate_level(line_edit.text)
		print("Level generated")
	if event.is_action("m_jump"):
		print("loading level")
		Scenes.goto_scene("user://savedlvl.scn")
