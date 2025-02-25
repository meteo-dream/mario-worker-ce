extends Player

func die(tags: Dictionary = {}) -> void:
	global_position.y = 0
	reset_physics_interpolation()
	speed.y = 0
