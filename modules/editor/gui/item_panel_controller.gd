extends PanelContainer

const ITEM_BUTTON = preload("res://modules/editor/gui/item_button.tscn")
const SCENES_PATH := "res://modules/editor/objects/"
const ITEM_FOLDABLE_CONTAINER = preload("uid://dhjqv7n6lq15x")

@export var category_name: String = ""
@export var buttons_size: int = 48

@onready var container: VBoxContainer = %VBoxContainer
var subcategories: Array[Container]

#var grid_cont: Container

func _ready() -> void:
	if category_name.is_empty():
		return
	#grid_cont = get_child(0).get_child(0).get_child(0)
	var scenes: PackedStringArray = DirAccess.get_files_at(SCENES_PATH + category_name)
	
	for i in scenes:
		if !(i.ends_with(".tscn") || i.ends_with(".remap")):
			continue
		#print(i)
		var cached_scene: EditorAddableNode2D = load(
			SCENES_PATH + category_name + "/" + i.replace(".remap", "")
		).instantiate()
		assert(cached_scene is EditorAddableNode2D)
		
		var btn: Button = ITEM_BUTTON.instantiate()
		btn.custom_minimum_size = buttons_size * Vector2.ONE
		# Filtering subcategories
		var filtered_arr: Array[Container] = subcategories.filter(func(cont):
			return cont && cont.title == cached_scene.subcategory
		)
		var _subcat: Container
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
	
	# Sorting subcategories by name
	if len(subcategories) > 0:
		subcategories.sort_custom(func(a, b): return a.title.naturalnocasecmp_to(b.title) < 0)
		for i in subcategories:
			container.add_child(i)
