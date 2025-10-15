extends Label

@export var action: String = "m_jump"
@onready var _template: String = text

func _ready() -> void:
	update_text()
	SettingsManager.settings_saved.connect(update_text)


func update_text() -> void:
	var _events: Array[InputEvent] = InputMap.action_get_events(action)
	var _event: String = "buttons on keyboard"
	var _temp: String
	var key_strings := PackedStringArray([
		tr("Unknown", "keyboard buttons"), tr("Space", "key")#, tr("Enter"), tr("Tab"), tr("Backspace"),
		#tr("Slash"), tr("BackSlash"), tr("BracketLeft"), tr("BracketRight"), tr("Apostrophe"),
		#tr("Colon"), tr("Semicolon"), tr("Shift"), tr("Comma"), tr("Equal"), tr("Period"), tr("Minus"),
		#tr("QuoteLeft"), tr("Left"), tr("Up"), tr("Down"), tr("Right"),
	])
	var key_strings_raw := PackedStringArray([
		"Unknown", "Space"#, "Enter", "Tab", "Backspace", "Slash", "BackSlash",
		#"BracketLeft", "BracketRight", "Apostrophe",
		#"Colon", "Semicolon", "Shift", "Comma", "Equal", "Period", "Minus",
		#"QuoteLeft", "Left", "Up", "Down", "Right",
	])
	
	for i in _events:
		if i is InputEventKey:
			_temp = tr('%s button', "e.g. Space button") % [i.as_text().get_slice(' (', 0)]
			#if SettingsManager.device_keyboard:
			_event = _temp
			break
		#elif i is InputEventJoypadButton:
		#	_temp = "Joy " + str(i.button_index)
		if _temp: _event = _temp
	
	if key_strings_raw.has(_event):
		_temp = key_strings.get(key_strings_raw.find(_event))
		if _temp: _event = _temp
	
	text = tr(_template) % [_event]
