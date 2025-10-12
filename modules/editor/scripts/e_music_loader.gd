extends "res://engine/objects/core/music_loader/music_loader.gd"

func _ready() -> void:
	if Editor.mode != Editor.MODE.EDITOR:
		super()
		return
	Audio.stop_music_channel(1, false)
	Audio.stop_music_channel(2, false)
	Audio.stop_music_channel(98, false)
