extends Node

func _ready() -> void:
	var pckd := PackedScene.new()
	var err := pckd.pack(Scenes.current_scene)
	if err:
		print(error_string(err))
		return
	var er = ResourceSaver.save(pckd, "user://savedlvl.scn", ResourceSaver.FLAG_COMPRESS)
	if er:
		print(error_string(er))
