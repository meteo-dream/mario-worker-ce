extends EditorAddableSpecial

const SUIT_MARIO_SUPER = preload("uid://cmhi4m24voa1d")

func setup_object() -> Node:
	if Editor.current_level && !get_parent() is Button:
		add_to_group(&"editor_addable_object")
	if Editor.mode == Editor.MODE.EDITOR:
		#_install_icon()
		var _par = get_parent()
		if _par is Button:
			var _icon: Texture2D = SkinsManager.apply_player_skin(SUIT_MARIO_SUPER).get_frame_texture(&"walk", 0)
			if _icon:
				_par.icon = _icon
				_par.add_theme_constant_override(&"icon_max_width", _icon.get_width())
			else:
				_par.icon = editor_icon
			process_mode = Node.PROCESS_MODE_DISABLED
	else:
		return _prepare_gameplay()
	return null

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
	#_texture.position = -Vector2.ONE * 16
	add_child(_texture)
	
	var _area = Area2D.new()
	_area.collision_layer = 1 << 5
	_area.collision_mask = 0
	add_child(_area)
	var _col = CollisionShape2D.new()
	_shape = RectangleShape2D.new()
	_col.shape = _shape
	_shape.size = Vector2.ONE * 32
	_col.position = -offset
	_area.add_child(_col)
	
	_editor_ready = true
