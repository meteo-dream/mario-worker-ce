extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const SCENES_PATH := "res://modules/editor/objects/"

@export var category_name: String = ""


@onready var grid_cont: FlowContainer = get_child(0).get_child(0).get_child(0)

func _ready() -> void:
	if category_name.is_empty():
		return
	var scenes: PackedStringArray = DirAccess.get_files_at(SCENES_PATH + category_name)
	#load_from_file
	for i in scenes:
		#print(i)
		var btn = ITEM_BUTTON.instantiate()
		var cached_scene = load(SCENES_PATH + category_name + "/" + i.replace(".remap", "")).instantiate()
		grid_cont.add_child.call_deferred(btn)
		btn.add_child.call_deferred(cached_scene)
		btn.tooltip_text = cached_scene.name
		if cached_scene is EditorAddableObject:
			btn.pressed.connect(btn._on_pressed_add_object, CONNECT_DEFERRED)
		elif cached_scene is TileSet:
			btn.pressed.connect(btn._on_pressed_add_tileset, CONNECT_DEFERRED)
		cached_scene.set_meta(&"nameid", cached_scene.name)
		#btn.set_deferred("icon", cached_scene.editor_icon)
