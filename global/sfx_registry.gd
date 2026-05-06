extends Node

const HOVER_CARD := preload("res://art/music/sound_effects/misc/UIClick_BLEEOOP_Baby_Click.wav")
const HOVER_UI := preload("res://art/music/sound_effects/misc/UIClick_BLEEOOP_Low_Profi_2.wav")
const CLICK_BUTTON := preload("res://art/music/sound_effects/400 Sounds Pack/UI/select_1.wav")
const CLICK_MENU := preload("res://art/music/sound_effects/misc/confirm_style_4_001.ogg")
const DRAW_CARD := preload("res://art/music/sound_effects/400 Sounds Pack/Card and Board/card_draw_1.wav")
const CONFIRM := preload("res://art/music/sound_effects/400 Sounds Pack/UI/sci_fi_confirm.wav")
const CANCEL := preload("res://art/music/sound_effects/400 Sounds Pack/UI/sci_fi_cancel.wav")

var _by_name: Dictionary = {
	&"HOVER_CARD": HOVER_CARD,
	&"HOVER_UI": HOVER_UI,
	&"CLICK_BUTTON": CLICK_BUTTON,
	&"CLICK_MENU": CLICK_MENU,
	&"DRAW_CARD": DRAW_CARD,
	&"CONFIRM": CONFIRM,
	&"CANCEL": CANCEL,
}

func play(sfx_name: StringName, pitch: float = 1.0) -> void:
	var stream: AudioStream = _by_name.get(sfx_name, null)
	if stream == null:
		push_warning("SFXRegistry: unknown SFX '%s'" % sfx_name)
		return
	SFXPlayer.play(stream, false, pitch)
