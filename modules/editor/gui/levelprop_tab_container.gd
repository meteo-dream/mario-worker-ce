extends TabContainer

@onready var time_limit: SpinBox = %TimeLimit
@onready var display_name_1: LineEdit = %DisplayName1
@onready var display_name_2: LineEdit = %DisplayName2
@onready var level_name: LineEdit = %LevelName
@onready var level_description: TextEdit = %LevelDescription
@onready var level_author: LineEdit = %LevelAuthor
@onready var author_email: LineEdit = %AuthorEmail
@onready var author_website: LineEdit = %AuthorWebsite
@onready var gradient_top: ColorPickerButton = %GradientTop
@onready var gradient_bottom: ColorPickerButton = %GradientBottom

func _ready() -> void:
	%GradientPresets.get_popup().id_pressed.connect(_on_gradient_preset_choosed)

func update_input_values() -> void:
	time_limit.value = Editor.current_level.time
	level_name.text = Editor.current_level_properties.level_name
	display_name_1.text = Editor.current_level_properties.level_display_name_1
	display_name_2.text = Editor.current_level_properties.level_display_name_2
	level_description.text = Editor.current_level_properties.level_description
	level_author.text = Editor.current_level_properties.level_author
	author_email.text = Editor.current_level_properties.level_author_email
	author_website.text = Editor.current_level_properties.level_author_website
	
	var player_pos: Node = get_tree().get_first_node_in_group(&"editor_player_position")
	if player_pos:
		player_pos.global_position = Editor.current_level_properties.player_position


func update_section_values() -> void:
	var section = Editor.current_level.get_section(Editor.scene.section)
	gradient_top.color = section.get_node("Background/GradientLayer/Gradient").texture.gradient.get_color(0)
	gradient_bottom.color = section.get_node("Background/GradientLayer/Gradient").texture.gradient.get_color(1)
	%GradientPreviewRect.texture.gradient.set_color(0, gradient_top.color)
	%GradientPreviewRect.texture.gradient.set_color(1, gradient_bottom.color)


func _on_gradient_top_color_changed(color: Color) -> void:
	var texture: GradientTexture2D = %GradientPreviewRect.texture
	texture.gradient.set_color(0, color)


func _on_gradient_bottom_color_changed(color: Color) -> void:
	var texture: GradientTexture2D = %GradientPreviewRect.texture
	texture.gradient.set_color(1, color)


func _on_gradient_preset_choosed(id: int) -> void:
	var arr: Array = ["5a3dff", "f3f3f3"]
	match id:
		1: arr = ["3b7ba3", "f2fdfc"]
		2: arr = ["0027cf", "00a7ef"]
		3: arr = ["1b00bb", "d5dcf3"]
		4: arr = ["006fdf", "d2eaf8"]
		5: arr = ["080000", "282828"]
		6: arr = ["2e0000", "8a0000"]
		7: arr = ["ffff80", "ff4b00"]
		8: arr = ["c0c0c0", "f8f8f8"]
		9: arr = ["7d9ec0", "e3f1f4"]
		10: arr = ["00003f", "f7f7ff"]
		11: arr = ["0000ff", "ffffff"]
	
	_on_gradient_top_color_changed(Color(arr[0]))
	gradient_top.color = Color(arr[0])
	_on_gradient_bottom_color_changed(Color(arr[1]))
	gradient_bottom.color = Color(arr[1])
