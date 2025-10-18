extends Window

@onready var orig_copyright_box: String = %CopyrightBox.text
@onready var orig_authors_box: String = %AuthorsBox.text


func _ready() -> void:
	update_locale_text.call_deferred()
	
func update_locale_text() -> void:
	%CopyrightBox.text = orig_copyright_box % tr(&"A Level Editor for Mario Forever.")
	var translation_strings: PackedStringArray = [
		tr_n(&"Lead Developer of MW:CE:", &"Lead Developers of MW:CE:", 1),
		tr(&"Graphical Assistance:"),
		tr(&"Thunder Engine Developers:"),
		tr(&"Supporters:"),
		tr(&"Additional Credits:"),
		tr(&"Softendo/Buziol Games - For the base game"),
		tr(&"TheMarioVariable - For Mario Worker Remake"),
		tr(&"English Translation:", &"Put your language here!"),
		tr(&"Your name", &"Put translation authors here!"),
	]
	
	%AuthorsBox.text = orig_authors_box.format({
		"lead_dev_title": get_title_colored(translation_strings[0]),
		"graphics_title": get_title_colored(translation_strings[1]),
		"thunder_engine_title": get_title_colored(translation_strings[2]),
		"supporters_title": get_title_colored(translation_strings[3]),
		"extra_credits_title": get_title_colored(translation_strings[4]),
		"softendo_credit": translation_strings[5],
		"tmv_credit": translation_strings[6],
		"translators_title": get_translators("\n" + get_title_colored(translation_strings[7])),
		"translators": get_translators("\n" + translation_strings[8] + "\n"),
	})

func get_title_colored(text: String) -> String:
	return "[color=cyan]" + text + "[/color]"

func get_translators(text: String) -> String:
	if TranslationServer.get_locale() == "en":
		return ""
	return text
