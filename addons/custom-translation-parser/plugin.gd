@tool
extends EditorPlugin

var parser_plugin: EditorTranslationParserPlugin = null

func _enter_tree() -> void:
	parser_plugin = preload("parser.gd").new()
	add_translation_parser_plugin(parser_plugin)


func _exit_tree() -> void:
	remove_translation_parser_plugin(parser_plugin)
	parser_plugin = null
