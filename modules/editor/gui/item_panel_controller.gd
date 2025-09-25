extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const SCENES_PATH := "res://modules/editor/objects/"

@export var category_name: String = ""


var grid_cont: Container

func _ready() -> void:
	if category_name.is_empty():
		return
	grid_cont = get_child(0).get_child(0).get_child(0)
	var scenes: PackedStringArray = DirAccess.get_files_at(SCENES_PATH + category_name)
	#load_from_file
	for i in scenes:
		if !(i.ends_with(".tscn") || i.ends_with(".remap")):
			continue
		#print(i)
		var btn = ITEM_BUTTON.instantiate()
		var cached_scene = load(SCENES_PATH + category_name + "/" + i.replace(".remap", "")).instantiate()
		assert(cached_scene is EditorAddableNode2D)
		
		grid_cont.add_child.call_deferred(btn)
		btn.add_child.call_deferred(cached_scene)
		btn.tooltip_text = cached_scene.name
		btn.pressed.connect(cached_scene._on_editor_object_selected.bind(category_name), CONNECT_DEFERRED)
		#if cached_scene is EditorAddableNode2D:
		#	btn.pressed.connect(btn._on_pressed_add_object.bind(category_name), CONNECT_DEFERRED)
		#elif cached_scene is TileSet:
		#	btn.pressed.connect(btn._on_pressed_add_tileset, CONNECT_DEFERRED)
		cached_scene.set_meta(&"nameid", cached_scene.name)
		#btn.set_deferred("icon", cached_scene.editor_icon)
