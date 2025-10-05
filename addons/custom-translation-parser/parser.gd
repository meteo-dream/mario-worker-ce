@tool
extends EditorTranslationParserPlugin

func _parse_file(path):
	var ret: Array[PackedStringArray] = []
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var split_strs = text.split("\n", false)
	var next_context: String
	for s in split_strs:
		if s.begins_with("[") && s.ends_with("]"):
			next_context = s.left(-1).right(-1)
			continue
		ret.append(PackedStringArray([s, next_context]))
		next_context = ""
		#print("Extracted string: " + s)

	return ret

func _get_recognized_extensions():
	return ["ini"]
