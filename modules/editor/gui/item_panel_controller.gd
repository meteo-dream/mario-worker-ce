extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const ITEM_TILE_BUTTON = preload("uid://bpj7u7irn0jsk")
const ITEM_TERRAIN_BUTTON = preload("uid://dpm1i7x7lh6i1")
const SCENES_PATH := "res://modules/editor/objects/"
const ITEM_FOLDABLE_CONTAINER = preload("uid://dhjqv7n6lq15x")

@export var category_name: String = ""
@export var buttons_size: int = 48
@export var json_mode: bool = false

@onready var container: GridContainer = %VBoxContainer
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
			i.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(i)
		
		_on_grid_container_resized()
		container.resized.connect(_on_grid_container_resized)


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
			btn.add_theme_constant_override(&"icon_max_width", buttons_size - 8)
			btn.tooltip_text = source_name
			
			btn.icon = source.texture
			btn.pressed.connect.call_deferred(
				_on_editor_tileset_selected.bind(source_id, _fold.get_meta(&"editor_tileset", dict))
			, CONNECT_DEFERRED)
			_fold.get_child(0).add_child.call_deferred(btn)
			
		_fold.set_meta(&"editor_tileset", dict)

func _on_editor_tileset_selected(source_id: int, tileset_dict: Dictionary) -> void:
	Editor.scene.selected_object = null
	if !tileset_dict: return
	Editor.scene.selected_tileset = tileset_dict
	
	# Tile Holder to know what tile user selected
	var tile_holder := LevelEditor.TileHolder.new()
	tile_holder.source_id = source_id
	Editor.scene.selected_tile_holder = tile_holder
	
	for i in %ScrollTileContainer.get_child(0).get_children():
		i.queue_free()
	
	var _tile_btn_base: Button = ITEM_TILE_BUTTON.instantiate()
	var tile_btn: Button
	
	var _terrain: int = -1
	var _terrain_set: int = -1
	var tile_source: TileSetAtlasSource = tileset_dict.tileset.get_source(source_id)
	for i in tile_source.get_tiles_count():
		tile_btn = _tile_btn_base.duplicate() if i < tile_source.get_tiles_count() - 1 else _tile_btn_base
		
		var tile_id: Vector2i = tile_source.get_tile_id(i)
		var tile_texture_region = tile_source.get_tile_texture_region(tile_id)
		tile_btn.custom_minimum_size = Vector2(tile_texture_region.size) + (Vector2.ONE * 2)
		tile_btn.set_meta(&"tile_id", tile_id)
		var tile_data: TileData = tile_source.get_tile_data(tile_id, 0)
		if _terrain == -1 && tile_data.terrain > -1:
			_terrain = tile_data.terrain
			_terrain_set = tile_data.terrain_set
		
		tile_btn.pressed.connect(func():
			tile_holder.source_id = source_id
			tile_holder.id = tile_btn.get_meta(&"tile_id", 0)
			tile_holder.terrain = -1
			tile_holder.terrain_set = -1
			select_paint(false)
		)
		tile_btn.draw.connect(func():
			tile_btn.draw_texture_rect_region(
				tile_source.texture, Rect2(Vector2.ONE, tile_texture_region.size), tile_texture_region
			)
			if tile_btn.is_hovered():
				var color := (
					Color(0, 0, 0, 0.2) if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else Color(1, 1, 1, 0.2)
				)
				tile_btn.draw_rect(Rect2(-Vector2.ONE, tile_btn.get_rect().size + Vector2.ONE), color, true)

		)
		#tile_btn.icon = tile_source.get_runtime_tile_texture_region()
		
		%ScrollTileContainer.get_child(0).add_child(tile_btn)
	
	if _terrain > -1:
		tile_holder.terrain = _terrain
		tile_holder.terrain_set = _terrain_set
		
		var terrain_btn: Button = ITEM_TERRAIN_BUTTON.instantiate()
		terrain_btn.pressed.connect(func():
			tile_holder.source_id = source_id
			tile_holder.id = Vector2i(-1, -1)
			tile_holder.terrain = _terrain
			tile_holder.terrain_set = _terrain_set
			select_paint(false)
		)
		
		%ScrollTileContainer.get_child(0).add_child(terrain_btn)
		Thunder.reorder_top(terrain_btn)
	else:
		tile_holder.id = tile_source.get_tile_id(0)
		tile_holder.terrain = -1
		tile_holder.terrain_set = -1
	
	Editor.scene.tileset_selected()
	
	select_paint(true)

func select_paint(from_menu: bool = true) -> void:
	Editor.scene.tool_mode = LevelEditor.TOOL_MODES.PAINT
	Editor.scene.editing_sel = LevelEditor._edit_sel_to_enum(category_name)
	Editor.scene.selected = []
	Editor.scene._on_selected_array_change()
	Editor.scene.object_to_paint_selected(from_menu)


func _on_grid_container_resized() -> void:
	container.columns = 1 + floori(container.size.x / 768)
