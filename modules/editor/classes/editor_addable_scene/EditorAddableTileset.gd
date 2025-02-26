class_name EditorAddableTileset
extends Node2D

@export_file("*.tscn", "*.scn") var scene_path: String

@onready var scene: PackedScene = load(scene_path)

func _ready() -> void:
	if Editor.mode == 1:
		_install_icon()
		#if get_parent() is Button:
		#	get_parent().pressed.connect(_on_pressed)
	

func _install_icon() -> void:
	pass
