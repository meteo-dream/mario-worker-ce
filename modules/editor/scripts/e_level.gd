@warning_ignore("missing_tool")
extends Level
class_name LevelEdited

const HUD = preload("res://modules/editor/objects/editor-friendly/level_hud.tscn")
const SECTION_POS_Y_VALUE: int = 32768
const E_CAM_AREA = preload("uid://dg21ubacsmyiw")
const E_SECTION = preload("uid://dguegm6pi350a")

func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if Editor.mode == Editor.MODE.EDITOR:
		return
	
	if !has_node("LevelProperties"):
		push_error("No level properties found!")
		return

	var hud = HUD.instantiate()
	add_child(hud)
	hud.get_node("Control/WorldHolder/DisplayName1").text = Editor.current_level_properties.level_display_name_1
	hud.get_node("Control/WorldHolder/DisplayName2").text = Editor.current_level_properties.level_display_name_2
	

func get_section(section_index: int) -> Node2D:
	if has_node("Section%d" % section_index):
		return get_node("Section%d" % section_index)
	if !Editor.current_level_properties:
		printerr("no current level properties")
		return
	
	var _new_node := E_SECTION.instantiate()
	_new_node.name = "Section%d" % section_index
	_new_node.position.y = (section_index - 1) * SECTION_POS_Y_VALUE
	add_child(_new_node)
	_new_node.owner = Editor.current_level
	
	var section: SectionProperties = Editor.current_level_properties.sections.get_or_add(
		section_index, SectionProperties.new()
	)
	section.position.y = _new_node.global_position.y
	
	#var _folder := Node2D.new()
	#_folder.name = "Background"
	#_new_node.add_child(_folder)
	#for _cat in ["tile", "scenery", "bonus", "misc", "enemy", "special", "CamAreas"]:
		#var _new_folder = _folder.duplicate()
		#_new_folder.name = _cat
		#_new_node.add_child(_new_folder)
	
	#var cam_area = E_CAM_AREA.instantiate()
	#cam_area.size = Vector2(11008, 480)
	#section.size = cam_area.size
	#_new_node.get_node("CamAreas").add_child(cam_area)
	return _new_node
