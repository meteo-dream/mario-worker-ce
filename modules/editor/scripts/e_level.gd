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
	if Editor.mode == Editor.MODE.TESTING:
		hud.offset.y = 56
		hud.reset_physics_interpolation()
	
	if time <= 100 && time > 1:
		hud.timer_hurry()
	

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


func finish(walking: bool = false, walking_dir: int = 1) -> void:
	if !Thunder._current_player: return
	if _level_has_completed:
		return
	level_completed.emit()
	Thunder.autosplitter.update_il_counter()
	_level_has_completed = true
	print("[Game] Level complete.")

	Thunder._current_hud.timer.paused = true
	Thunder._current_player.completed = true
	Audio.stop_all_musics()
	if completion_music:
		var _custom_music = CharacterManager.get_sound_replace(completion_music, DEFAULT_COMPLETION, "level_complete", false)
		Audio.play_music(_custom_music, -1)

	if walking:
		_force_player_walking = true
		_force_player_walking_dir = walking_dir
	Data.values.onetime_blocks = true
	Thunder._current_player.left_right = 0

	get_tree().call_group_flags(
		get_tree().GROUP_CALL_DEFERRED,
		&"end_level_sequence",
		&"_on_level_end"
	)

	await get_tree().physics_frame
	if completion_music:
		await get_tree().create_timer(completion_music_delay_sec, false, false, true).timeout
	
	# In case the player dies after finish line (e.g. falling in a pit or by touching lava)
	if !Thunder._current_player:
		print_verbose("[Level] Player not found, aborting the level completion sequence.")
		return

	Thunder._current_hud.time_countdown_finished.connect(
		func() -> void:
			await get_tree().create_timer(0.8, false, false).timeout
			# Do not switch scenes if game over screen is opened, might be rare but just in case
			if Scenes.custom_scenes.get("game_over"):
				if Scenes.custom_scenes.game_over.get("opened"):
					return
			var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
			Data.values.checkpoint = -1
			Data.values.checked_cps = []

			if jump_to_scene:
				if !_crossfade:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
							.instantiate()
							.with_speeds(0.04, -0.1)
							.with_pause()
							.on_player_after_middle(completion_center_on_player_after_transition)
					)

					await TransitionManager.transition_middle
					Scenes.goto_scene(jump_to_scene)
				else:
					TransitionManager.accept_transition(
						load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
							.instantiate()
							.with_scene(jump_to_scene)
					)
			else:
				printerr("[Level] Jump to scene is not defined in the level.")
	)

	if completion_write_save:
		var profile = ProfileManager.current_profile
		var path = scene_file_path if !completion_write_save_path_override else completion_write_save_path_override
		if Data.values.get("map_force_selected_marker"):
			Data.values.map_force_go_next = true
			Data.values.map_force_old_marker = ""
		if !profile.has_completed(path):
			profile.complete_level(path)
			ProfileManager.save_current_profile()

	Thunder._current_hud.time_countdown()
