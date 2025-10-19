extends AnimatedSprite2D

func _ready() -> void:
	_timer()

func _timer() -> void:
	await get_tree().create_timer(randf_range(0.5, 3), false).timeout
	
	if randi_range(1, 3) == 1:
		play("grin")
	else:
		play("default")
	_timer()
