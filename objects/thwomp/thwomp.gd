extends "res://engine/objects/enemies/thwomp/thwomp.gd"

func _stun() -> void:
	stun.emit()
	var _sfx = CharacterManager.get_sound_replace(stunning_sound, stunning_sound, "stun", false)
	Audio.play_sound(_sfx, self)
	_explosion()
	if Thunder._current_camera is PlayerCamera2D:
		do_shock(Thunder._current_camera, 10, 2)
	
func do_shock(cam: PlayerCamera2D, duration: int, time_scale: float = 1.0):
	if cam._shocking == 0:
		cam.ofs = cam.offset
	cam._shocking += 1
	var step: float = duration
	while step > 0:
		cam.offset.x = randf_range(-step, step) / 2
		step -= 1 / time_scale
		if step <= 0:
			cam.offset = cam.ofs
			cam._shocking -= 1
		await get_tree().create_timer(0.01, false).timeout
