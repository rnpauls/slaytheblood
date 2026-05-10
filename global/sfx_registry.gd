extends Node

const HOVER_CARD := preload("res://art/music/sound_effects/misc/UIClick_BLEEOOP_Baby_Click.wav")
const HOVER_UI := preload("res://art/music/sound_effects/misc/UIClick_BLEEOOP_Low_Profi_2.wav")
const CLICK_BUTTON := preload("res://art/music/sound_effects/misc/UIClick_BLEEOOP_Baby_Click.wav")
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

# ── Auto-attach: every Button gets CLICK_BUTTON and HOVER_UI by default. ──
# Add a Button to the &"no_sfx" group (in the editor or via add_to_group)
# to opt out — useful for gameplay-context buttons like card click areas.
func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	# The main scene's nodes are already in the tree by the time this autoload's
	# _ready runs, so node_added never fires for them. Sweep once to catch them.
	_wire_subtree(get_tree().root)

func _wire_subtree(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_wire_subtree(child)

func _on_node_added(node: Node) -> void:
	if node is Button and not node.is_in_group(&"no_sfx"):
		if not node.pressed.is_connected(_play_button_click):
			node.pressed.connect(_play_button_click)
		if not node.mouse_entered.is_connected(_play_button_hover):
			node.mouse_entered.connect(_play_button_hover)

func _play_button_click() -> void:
	play(&"CLICK_BUTTON")

func _play_button_hover() -> void:
	play(&"HOVER_UI")
