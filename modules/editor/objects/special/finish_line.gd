extends EditorAddableSpecial

const FINISH_LINE = preload("uid://dfm7d4qtja67b")

func _prepare_gameplay() -> Node:
	var instance: Node = FINISH_LINE.instantiate()
	if "position" in instance:
		instance.position = position - offset + Vector2(-16, 16)
		instance.use_strict_detection_area = true
		instance.z_index = -1
	add_sibling.call_deferred(instance)
	queue_free()
	return instance

func _prepare_editor(is_new: bool = true) -> void:
	if group_name:
		add_to_group(group_name)
	if place_mode == PLACE_MODE.NORMAL:
		super(is_new)
		return
	if is_new:
		position += offset
	reset_physics_interpolation()
	var _texture = Sprite2D.new()
	_texture.texture = editor_icon
	_texture.offset = editor_icon_offset
	_texture.z_index = -1
	#_texture.position = -Vector2.ONE * 16
	add_child(_texture)
	
	var _area = Area2D.new()
	_area.collision_layer = 1 << 7 << LevelEditor._edit_sel_to_enum(category)
	_area.collision_mask = 0
	add_child(_area)
	var _col = CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	_col.shape = _shape
	_shape.size = Vector2.ONE * 32
	_col.position = -offset
	_area.add_child(_col)
	
	_editor_ready = true
