extends "res://engine/objects/core/music_loader/music_loader.gd"

func _ready() -> void:
	if Editor.mode == 0:
		super()
		return
