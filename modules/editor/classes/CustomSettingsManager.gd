extends "res://engine/singletones/scripts/SettingsManager.gd"


## Processes certain settings and applies their effects
func _process_settings() -> void:
	# Game Speed
	Engine.time_scale = settings.game_speed
	@warning_ignore("narrowing_conversion")
	Engine.physics_ticks_per_second = Engine.time_scale * _default_tps

	var window_id: int = GlobalViewport.get_window_id()
	# Vsync
	if window_id >= 0:
		var current_vsync = DisplayServer.window_get_vsync_mode(window_id)
		if settings.vsync && current_vsync != DisplayServer.VSYNC_ENABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED, window_id)
		elif !settings.vsync && current_vsync != DisplayServer.VSYNC_DISABLED:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED, window_id)
		
		# Scale
		_window_scale_logic()
		
		# Fullscreen
		if !settings.fullscreen && DisplayServer.window_get_mode(window_id) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			# This is needed to avoid borders being outside the monitor boundaries when you exit fullscreen
			if OS.get_name() == "Windows":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED, window_id)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
			_window_scale_logic(true)
		elif settings.fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, window_id)

	# Filter
	GlobalViewport._update_view()

	ProjectSettings.set_setting(
		&"rendering/textures/canvas_textures/default_texture_filter",
		int(settings.filter)
	)

	# Music Volume
	Audio._settings_music_bus_volume_db = linear_to_db(settings.music)

	# Sound Volume
	Audio._settings_sound_bus_volume_db = linear_to_db(settings.sound)

	settings_updated.emit()


## Handles scaling the window via the Scale menu option
func _window_scale_logic(force_update: bool = false) -> void:
	if no_saved_settings: return
	if settings.scale == 0: return
	if old_scale == settings.scale && !force_update: return
	
	#return

	var window_id: int = GlobalViewport.get_window_id()
	if window_id < 0: return
	var current_screen: int = DisplayServer.window_get_current_screen(window_id)
	var screen_size: Vector2i = DisplayServer.screen_get_usable_rect(current_screen).size
	var screen_center: Vector2i = screen_size / 2
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(Editor.screen_size * settings.scale, window_id)
	await get_tree().physics_frame
	if old_scale != 0 || settings.scale > 1:
		DisplayServer.window_set_position(
			screen_center - (DisplayServer.window_get_size(window_id) / 2)
		, window_id)
		GlobalViewport._update_view()

	old_scale = settings.scale


func hide_mouse() -> void:
	return
	#if Editor.mode == Editor.MODE.EDITOR:
	#else:
	#	super()
