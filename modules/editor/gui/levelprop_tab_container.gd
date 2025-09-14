extends TabContainer

@onready var time_limit: SpinBox = %TimeLimit
@onready var display_name_1: LineEdit = %DisplayName1
@onready var display_name_2: LineEdit = %DisplayName2
@onready var level_name: LineEdit = %LevelName
@onready var level_description: TextEdit = %LevelDescription
@onready var level_author: LineEdit = %LevelAuthor
@onready var author_email: LineEdit = %AuthorEmail
@onready var author_website: LineEdit = %AuthorWebsite

func update_input_values() -> void:
	time_limit.value = Editor.current_level.time
	level_name.text = Editor.current_level_properties.level_name
	display_name_1.text = Editor.current_level_properties.level_display_name_1
	display_name_2.text = Editor.current_level_properties.level_display_name_2
	level_description.text = Editor.current_level_properties.level_description
	level_author.text = Editor.current_level_properties.level_author
	author_email.text = Editor.current_level_properties.level_author_email
	author_website.text = Editor.current_level_properties.level_author_website
