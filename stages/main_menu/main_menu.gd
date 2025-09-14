extends Control


func _ready() -> void:
	reparent.call_deferred(get_tree().root, true)
	SettingsManager.show_mouse()
