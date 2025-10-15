extends "res://engine/singletones/scripts/SettingsManager.gd"


## Handles scaling the window via the Scale menu option
func _window_scale_logic(force_update: bool = false) -> void:
	if no_saved_settings: return
	if settings.scale == 0: return
	if old_scale == settings.scale && !force_update: return
	
	print(DisplayServer.get_window_list())
	return

	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_usable_rect(current_screen).size
	var screen_center: Vector2i = screen_size / 2
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	) * settings.scale)
	await get_tree().physics_frame
	if old_scale != 0 || settings.scale > 1:
		DisplayServer.window_set_position(
			screen_center - (DisplayServer.window_get_size() / 2)
		)
		GlobalViewport._update_view()

	old_scale = settings.scale


func hide_mouse() -> void:
	return
	#if Editor.mode == Editor.MODE.EDITOR:
	#else:
	#	super()
