class_name EditorAddableItem
extends EditorAddableScene

const CONTAINER_ITEM_PLUS = preload("uid://cxy2emcerill2")

@export var addable_to_container: bool = false

var item_displayer: Sprite2D

func _prepare_editor(is_new: bool = true) -> void:
	if addable_to_container:
		add_to_group(&"editor_addable_container_item")
	super(is_new)


func _prepare_gameplay() -> Node:
	var instance: Node = scene.instantiate()
	if "position" in instance:
		instance.position = position + instance_offset
	add_sibling.call_deferred(instance)
	prints("Game:", instance.name, position)
	queue_free()
	return instance


func _on_editor_object_selected(category_name: String) -> void:
	super(category_name)
	if addable_to_container:
		pass

func _hovering() -> void:
	pass
	
