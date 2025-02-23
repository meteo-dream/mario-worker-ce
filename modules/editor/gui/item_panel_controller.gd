extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const SCENES_PATH := "res://modules/editor/objects/"

@export var category_name: String = ""


@onready var grid_cont = get_child(0).get_child(0).get_child(0)

func _ready() -> void:
	if category_name.is_empty():
		return
	var scenes: PackedStringArray = DirAccess.get_files_at(SCENES_PATH + category_name)
	for i in scenes:
		print(i)
		var btn = ITEM_BUTTON.instantiate()
		var cached_scene = load(SCENES_PATH + category_name + "/" + i).instantiate()
		btn.icon = cached_scene.editor_icon
		btn.text = cached_scene.name
		cached_scene.set_meta(&"nameid", cached_scene.name)
		grid_cont.add_child(btn)
		btn.add_child(cached_scene)
