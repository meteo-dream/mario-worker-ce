extends Player

func _ready() -> void:
	if Thunder._current_player && Thunder._current_player.is_queued_for_deletion():
		Thunder._current_player = self
		super()
		return
	if Editor.mode == Editor.MODE.NONE || !Thunder._current_player || Editor.is_loading:
		super()
		return


func die(tags: Dictionary = {}, override_behavior: Callable = Callable()) -> void:
	if Editor.mode != Editor.MODE.EDITOR:
		super(tags, override_behavior)
		return
	global_position.y = -get_viewport_transform().origin.y
	reset_physics_interpolation()
	speed.y = 0
