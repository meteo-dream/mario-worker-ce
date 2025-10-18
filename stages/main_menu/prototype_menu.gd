extends Control

@onready var check_box: CheckBox = %EditorSounds

func _ready() -> void:
	reparent.call_deferred(get_tree().root, true)
	add_to_group(&"prototype_menu")
	SettingsManager.show_mouse()
	Editor.current_level_properties = null
	Editor.current_level = null
	if Editor.config.lang == "":
		for i in get_tree().get_nodes_in_group(&"menu_lang"):
			i.button_pressed = OS.get_locale_language() == i.name.trim_prefix("Lang_")
	else:
		for i in get_tree().get_nodes_in_group(&"menu_lang"):
			if i.name.trim_prefix("Lang_") == Editor.config.lang:
				%Lang_en.button_pressed = false
				i.button_pressed = true
				break
	%EditorSounds.button_pressed = Editor.config.editor_sounds
	Editor.save_config()


func _on_button_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Editor"), !check_box.button_pressed)
	Editor.config.editor_sounds = check_box.button_pressed
	Editor.save_config()
	Scenes.goto_scene("res://modules/editor/stages/level_editor.tscn")
	queue_free()


func _on_test_level_pressed() -> void:
	if $LoadFileDialog.current_dir == "user://":
		$LoadFileDialog.current_dir = "user://User Data/Levels"
	$LoadFileDialog.show()


func _on_load_file_dialog_file_selected(path: String) -> bool:
	if !path: return false
	
	Editor.is_loading = true
	var res: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	#var res = load(path)
	if !res:
		_throw_error_on_load(tr("Failed to load: Data is corrupted"))
		return false
	var new_level := res.instantiate()
	if !new_level:
		_throw_error_on_load(tr("Failed to load: Scene is corrupted"))
		return false
	if !new_level is LevelEdited:
		_throw_error_on_load(
			tr("This is not a valid level. See logs at\n\n%s") % OS.get_user_data_dir().path_join("logs")
		)
		new_level.free.call_deferred()
		return false
	
	var _level_props = new_level.get_node_or_null("LevelProperties")
	if _level_props && "properties" in _level_props:
		if _level_props.properties.get("level_major_version") < ProjectSettings.get_setting("application/thunder_settings/major_version", 1):
			_throw_error_on_load(tr("Failed to load: Incompatible Version"))
			new_level.free.call_deferred()
			return false
		Editor.current_level_properties = _level_props.properties.duplicate(true)
	else:
		_throw_error_on_load(tr("Failed to load: Missing LevelProperties"))
		new_level.free.call_deferred()
		return false
	
	# We do not need duplicating players
	if Thunder._current_player:
		Thunder._current_player.queue_free()
	
	GlobalViewport.show()
	hide()
	GlobalViewport.close_requested.connect(_free_level_scene, CONNECT_ONE_SHOT)
	
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
	
	Editor.current_level_properties = _level_props.properties
	
	Scenes.current_scene = new_level
	GlobalViewport.grab_focus()
	
	#get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT,
		#&"editor_addable_object", &"_prepare_gameplay", false
	#)
	#notify.call_deferred("Level loaded with %d objects!" % get_tree().get_node_count_in_group(&"editor_addable_object"))
	return true


func _free_level_scene() -> void:
	if !GlobalViewport.visible: return
	GlobalViewport.hide()
	if Scenes.custom_scenes.pause.opened:
		Scenes.custom_scenes.pause.toggle(false, true)
	get_window().show()
	if Scenes.current_scene && Scenes.current_scene != self:
		Scenes.current_scene.queue_free()
	#Editor.mode = Editor.MODE.NONE
	Editor.current_level = null
	Editor.current_level_properties = null
	Editor.level_path = ""
	Scenes.current_scene = self
	Audio.stop_all_musics()
	Audio.stop_all_sounds()
	show()
	for i in get_tree().get_nodes_in_group(&"prototype_menu"):
		if is_instance_valid(i) && i != self:
			i.queue_free()


func _physics_process(delta: float) -> void:
	if !GlobalViewport.visible: return
	if (!is_instance_valid(Scenes.current_scene) || Scenes.current_scene == self) && get_window().visible:
		_free_level_scene()


func _throw_error_on_load(text: String) -> void:
	OS.alert(text)
	Editor.level_path = ""
	Editor.is_loading = false


func _on_browse_files_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://User Data/Levels"))


func _on_lang_toggled(toggled_on: bool, lang_string: String) -> void:
	if !toggled_on: return
	TranslationServer.set_locale(lang_string)
	Editor.config.lang = TranslationServer.get_locale()
	%AboutWindow.update_locale_text()


func _on_exit_pressed() -> void:
	Editor.save_config()
	get_tree().quit()
