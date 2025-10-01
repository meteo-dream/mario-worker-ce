class_name EditorAddableSpecial
extends EditorAddableNode2D

enum PLACE_MODE {
	NORMAL,
	ONE_PER_LEVEL,
	ONE_PER_SECTION
}

var place_mode: PLACE_MODE


func _install_icon() -> void:
	if editor_icon != null: return

func _prepare_gameplay() -> Node:
	return null
