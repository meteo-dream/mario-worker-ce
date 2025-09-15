extends Control

func _ready() -> void:
	reparent.call_deferred(get_tree().root, true)
	SettingsManager.show_mouse()


func _on_button_pressed() -> void:
	Scenes.goto_scene("res://modules/editor/stages/level_editor.tscn")


func _on_test_level_pressed() -> void:
	$LoadFileDialog.show()


func _on_load_file_dialog_file_selected(path: String) -> bool:
	if !path: return false
	
	var res: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	#var res = load(path)
	if !res:
		OS.alert("Failed to load level.")
		Editor.level_path = ""
		return false
	var new_level := res.instantiate()
	if !new_level:
		OS.alert("Failed to load level.")
		Editor.level_path = ""
		return false
	
	# We do not need duplicating players
	if Thunder._current_player:
		Thunder._current_player.queue_free()
	# Removing unnecessary garbage scenes resulting from live-testing in editor
	#for i in get_children():
	#	if i.is_in_group(&"editor_internal_object"): continue
	#	i.queue_free()
	
	GlobalViewport.show()
	GlobalViewport.connect(&"close_requested", func():
		GlobalViewport.hide()
		Scenes.current_scene.queue_free()
		#Editor.mode = Editor.MODE.NONE
		Editor.current_level = null
		Editor.current_level_properties = null
		Scenes.current_scene = self
		Audio.stop_all_musics()
		Audio.stop_all_sounds()
	, CONNECT_ONE_SHOT)
	
	Editor.mode = Editor.MODE.NONE
	# Forcefully removing old level and immediately assigning a new one
	if Editor.current_level:
		print("Found old level")
		Editor.current_level.free()
	GlobalViewport.vp.add_child(new_level, false)
	Editor.current_level = new_level
	Thunder.reorder_top(new_level)
	#add_child.call_deferred(new_level, false)
	#Editor.set_deferred(&"current_level", new_level)
	#Thunder.reorder_top.call_deferred(new_level)
	
	var _level_props = Editor.current_level.get_node_or_null("LevelProperties")
	Editor.current_level_properties = _level_props if _level_props else null
	
	Scenes.current_scene = new_level
	
	#get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT,
		#&"editor_addable_object", &"_prepare_gameplay", false
	#)
	#notify.call_deferred("Level loaded with %d objects!" % get_tree().get_node_count_in_group(&"editor_addable_object"))
	return true
