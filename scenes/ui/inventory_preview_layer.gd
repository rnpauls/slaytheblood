## Owns the big InventoryCard hover preview plus its keyword chain. Listens on
## Events for show/hide requests, instantiates one InventoryCard for the
## hovered weapon/equipment, then stacks one TooltipBox below it per keyword
## referenced in the body. The whole column is positioned next to the source
## rect (left-of-source by default, flips right if no room — the opposite of
## TooltipLayer so card-in-hand tooltips and weapon/equipment previews settle
## on natural opposite sides when both could be on screen).
##
## Inherits the show/hide/settle/position pipeline from PositionedPopupLayer.
## Uses prefer_left_of_source = true (set in scene) and a longer hover_delay
## since the preview is bigger UI and should only commit once the user has
## clearly settled on the source.
extends PositionedPopupLayer

const INVENTORY_CARD_SCENE := preload("res://scenes/inventory_card/inventory_card.tscn")
const TOOLTIP_BOX := preload("res://scenes/ui/tooltip_box.tscn")
const CARD_SIZE := Vector2(200, 300)


func _connect_events() -> void:
	Events.inventory_preview_show_requested.connect(show_preview)
	Events.inventory_preview_hide_requested.connect(hide_now)


## Exactly one of weapon/equipment should be set; the other is null.
## anchor_rect: source rect in canvas coords. Pass Rect2() to anchor to mouse.
func show_preview(weapon: Weapon, equipment: Equipment, anchor_rect: Rect2 = Rect2()) -> void:
	if weapon == null and equipment == null:
		return
	_run_show({"weapon": weapon, "equipment": equipment}, anchor_rect)


func _build_content(payload: Variant) -> void:
	var weapon: Weapon = payload["weapon"]
	var equipment: Equipment = payload["equipment"]

	var card := INVENTORY_CARD_SCENE.instantiate() as InventoryCard
	# The inventory card scene defaults to full-rect anchors (assumes a
	# containing layout slot). Inside a VBoxContainer we want it sized by its
	# custom_minimum_size, so reset the anchors and let the container drive it.
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE, 0)
	card.custom_minimum_size = CARD_SIZE
	add_child(card)
	if weapon:
		card.weapon = weapon
	elif equipment:
		card.equipment = equipment

	var tooltip_txt := weapon.get_tooltip() if weapon else equipment.get_tooltip()
	for entry: TooltipData in KeywordRegistry.build_tooltip_chain(tooltip_txt):
		var box := TOOLTIP_BOX.instantiate() as TooltipBox
		add_child(box)
		box.set_data(entry)
