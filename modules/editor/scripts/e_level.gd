extends Level

const HUD = preload("res://modules/editor/objects/editor-friendly/level_hud.tscn")

func _ready() -> void:
	super()
	if Editor.mode == Editor.MODE.EDITOR:
		return
	if Engine.is_editor_hint():
		return
	
	if has_node("LevelProperties"):
		Editor.current_level_properties = $LevelProperties
	
		var hud = HUD.instantiate()
		add_child(hud)
		hud.get_node("Control/WorldHolder/DisplayName1").text = $LevelProperties.level_display_name_1
		hud.get_node("Control/WorldHolder/DisplayName2").text = $LevelProperties.level_display_name_2
	
