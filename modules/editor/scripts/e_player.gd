extends Player

func die(tags: Dictionary = {}) -> void:
	global_position.y = 16
	speed.y = 0
