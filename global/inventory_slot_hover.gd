## Applies the hover tween (glow on/off + scale to HOVER_SCALE/ONE) used by
## WeaponHandler and EquipmentHandler inventory slots. Caller keeps the active
## tween reference so it can be killed externally if the slot tears down mid-
## hover; pass it in as `prev_tween` and store the returned Tween.
class_name InventorySlotHover
extends RefCounted


const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_TIME := 0.1


static func apply(host: Node, button: Control, glow_panel: Control, prev_tween: Tween, value: bool) -> Tween:
	glow_panel.visible = value
	if prev_tween and prev_tween.is_running():
		prev_tween.kill()
	var tween := host.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "scale", HOVER_SCALE if value else Vector2.ONE, HOVER_TWEEN_TIME)
	return tween
