extends Player

func _ready() -> void:
	if Thunder._current_player && Thunder._current_player.is_queued_for_deletion():
		Thunder._current_player = self
		super()
		return
	if Editor.mode == 0 || !Thunder._current_player:
		super()
		return


func die(tags: Dictionary = {}, override_behavior: Callable = Callable()) -> void:
	global_position.y = 0
	reset_physics_interpolation()
	speed.y = 0
