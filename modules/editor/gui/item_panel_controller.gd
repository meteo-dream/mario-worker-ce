extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const SCENES_PATH := "res://modules/editor/objects/"
const ITEM_FOLDABLE_CONTAINER = preload("uid://dhjqv7n6lq15x")

@export var category_name: String = ""
@export var buttons_size: int = 48
@export var json_mode: bool = false

@onready var container: VBoxContainer = %VBoxContainer
var subcategories: Array[Container]

func _ready() -> void:
	if category_name.is_empty():
		return
	var items: PackedStringArray = DirAccess.get_files_at(SCENES_PATH + category_name)
	
	if !json_mode:
		load_scene_items(items)
	else:
		load_tileset_items(items)
	
	# Sorting subcategories by name
	if len(subcategories) > 0:
		subcategories.sort_custom(func(a, b):
			return a.title.naturalnocasecmp_to(b.title) < 0
		)
		for i in subcategories:
			container.add_child(i)


func load_scene_items(items: PackedStringArray):
	for i in items:
		if !(i.ends_with(".tscn") || i.ends_with(".remap")):
			continue
		
		var cached_scene: EditorAddableNode2D = load(
			SCENES_PATH + category_name + "/" + i.replace(".remap", "")
		).instantiate()
		assert(cached_scene is EditorAddableNode2D)
		if !cached_scene is EditorAddableNode2D:
			push_error(category_name + ": " + i + " is not a valid editor addable node.")
			cached_scene.queue_free()
			continue
		
		var btn: Button = ITEM_BUTTON.instantiate()
		btn.custom_minimum_size = buttons_size * Vector2.ONE
		# Filtering subcategories
		var _subcat: Container
		var filtered_arr: Array[Container] = subcategories.filter(func(cont):
			return cont && cont.title == cached_scene.subcategory
		)
		if len(filtered_arr) == 0:
			# Creating new subcategory if doesn't exist
			var _fold: FoldableContainer = ITEM_FOLDABLE_CONTAINER.instantiate()
			_fold.title = cached_scene.subcategory
			_subcat = _fold
			subcategories.append(_fold)
		else:
			_subcat = filtered_arr.front()
		
		# Adding button to the calculated subcategory
		_subcat.get_child(0).add_child.call_deferred(btn)
		btn.add_child.call_deferred(cached_scene)
		btn.tooltip_text = cached_scene.name
		btn.pressed.connect(cached_scene._on_editor_object_selected.bind(category_name), CONNECT_DEFERRED)
		cached_scene.set_meta(&"nameid", cached_scene.name)


func load_tileset_items(items: PackedStringArray) -> void:
	for i in items:
		if !i.ends_with(".json"):
			continue
		
		var _path := SCENES_PATH + category_name + "/" + i
		var dict = JSON.parse_string(FileAccess.get_file_as_string(_path))
		if !dict || !dict is Dictionary:
			push_error(category_name + ": " + i + " is not a valid JSON.")
			continue
		if !items.has(i.replace(".json", ".tres")):
			push_error(category_name + ": " + i + ": No tileset provided (.tres).")
			continue
		
		var tileset: TileSet = load(_path.replace(".json", ".tres"))
		dict.tileset = tileset
		dict.name_id = i
		dict.sources = []
		
		var _fold: FoldableContainer = ITEM_FOLDABLE_CONTAINER.instantiate()
		_fold.title = dict.get_or_add("name")
		subcategories.append(_fold)
		
		for id in tileset.get_source_count():
			var source_id := tileset.get_source_id(id)
			if !tileset.has_source(source_id):
				push_error("Tileset %s: Source ID %d is invalid." % [i, source_id])
				continue
			var source := tileset.get_source(source_id)
			if !source is TileSetAtlasSource:
				continue
			var source_name: String
			if dict.get("source_names") && dict.source_names is Array && len(dict.source_names) >= id + 1:
				source_name = dict.source_names[id]
			
			dict.sources.append(source_id)
			var btn: Button = ITEM_BUTTON.instantiate()
			btn.custom_minimum_size = buttons_size * Vector2.ONE
			btn.tooltip_text = source_name
			
			btn.icon = source.texture
			btn.pressed.connect(_on_editor_tileset_selected.bind(source_id, _fold), CONNECT_DEFERRED)
			_fold.get_child(0).add_child.call_deferred(btn)
		
		_fold.set_meta(&"editor_tileset", dict)

func _on_editor_tileset_selected(source_id: int, subcat: FoldableContainer) -> void:
	Editor.scene.selected_object = null
	var tileset: Dictionary = subcat.get_meta(&"editor_tileset")
	if !tileset: return
	Editor.scene.selected_tileset = tileset
	Editor.scene.selected_tile_source_id = source_id
	Editor.scene.selected_tile_id = tileset.tileset.get_source(source_id).get_tile_id(0)
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor._edit_sel_to_enum(category_name)
	Editor.scene.selected = []
	Editor.scene._on_selected_array_change()
	Editor.scene.object_to_paint_selected(true)
