extends Resource
class_name LevelProperties

@export var player_position := Vector2(80, 400)
@export_group("Level", "level_")
@export var level_display_name_1 := "MY LEVEL"
@export var level_display_name_2 := ""
@export var level_name := "New Level"
@export var level_description := "The newest best level?"
@export var level_author := "You"
@export var level_author_email: String
@export var level_author_website: String
@export var level_version: int
@export var level_major_version: int

@export var sections: Dictionary[int, SectionProperties]

@export var screen_resolution := Vector2i(640, 480)

func _init() -> void:
	level_version = ProjectSettings.get_setting("application/thunder_settings/version")
	level_major_version = ProjectSettings.get_setting("application/thunder_settings/major_version")
