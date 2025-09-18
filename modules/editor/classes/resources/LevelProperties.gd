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
@export var level_version: int = -90

@export var sections: Array[SectionProperties]
