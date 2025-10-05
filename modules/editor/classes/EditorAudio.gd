extends Node
class_name EditorAudio

const BLOCK_PLACE = preload("uid://bk2fn1h2y7tx5")
const MENU_OPEN = preload("uid://c6571aesyyyky")
const MENU_HOVER = preload("uid://cbfl4ck7cximi")
const MENU_CLOSE = preload("uid://d0yeo4ib83isd")
const MENU_ACCEPT = preload("uid://daeraa544o204")
const KICK = preload("uid://be3uvqev2c1p6")
const PITCH_ARRAY: PackedFloat32Array = [0.9, 1.0, 1.1, 1.25]

static func place_object() -> void:
	Audio.play_1d_sound(BLOCK_PLACE, false, { bus = "Editor" })

static func menu_open() -> void:
	Audio.play_1d_sound(MENU_OPEN, false, { bus = "Editor" })

static func menu_hover() -> void:
	Audio.play_1d_sound(MENU_HOVER, false, { bus = "Editor" })

static func menu_close() -> void:
	Audio.play_1d_sound(MENU_CLOSE, false, { bus = "Editor" })

static func menu_accept() -> void:
	Audio.play_1d_sound(MENU_ACCEPT, false, { bus = "Editor" })

static func kick(pitch: int = 1) -> void:
	var new_pitch: float = get_pitch(pitch)
	Audio.play_1d_sound(KICK, true, { bus = "Editor", pitch = new_pitch })

static func get_pitch(pitch) -> float:
	var pitch_kick: int = clampi(pitch, 0, 7)
	if pitch_kick < PITCH_ARRAY.size():
		return PITCH_ARRAY[pitch_kick]
	return 0.8 + pitch_kick * 0.2
