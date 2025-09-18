@warning_ignore("missing_tool")
extends Level
class_name LevelEdited

const HUD = preload("res://modules/editor/objects/editor-friendly/level_hud.tscn")

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if Editor.mode == Editor.MODE.EDITOR:
		return
	
	if !has_node("LevelProperties"):
		push_error("No level properties found!")
		return
	Editor.current_level_properties = $LevelProperties.properties

	var hud = HUD.instantiate()
	add_child(hud)
	hud.get_node("Control/WorldHolder/DisplayName1").text = Editor.current_level_properties.level_display_name_1
	hud.get_node("Control/WorldHolder/DisplayName2").text = Editor.current_level_properties.level_display_name_2
	

func get_section(section_index: int) -> Node2D:
	if has_node("Section%d" % section_index):
		return get_node("Section%d" % section_index)
	else:
		var _new_node := Node2D.new()
		_new_node.name = "Section%d" % section_index
		add_child(_new_node)
		var _folder := Node2D.new()
		_folder.name = "Background"
		_new_node.add_child(_folder)
		for _cat in ["tile", "scenery", "enemy", "bonus", "misc", "special"]:
			var _new_folder = _folder.duplicate()
			_new_folder.name = _cat
			_new_node.add_child(_new_folder)
		return _new_node
	
