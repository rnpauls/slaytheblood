## Non-interactive card display used inside the enemy's hand.
## Extends CardUI for rendering but has no state machine or player interactivity.
## EnemyAI works only with Card data; this is purely for display purposes.
class_name EnemyCardUI
extends CardUI

## When true the card-back is shown instead of the face. Default true for enemy hand cards.
var show_back: bool = true : set = _set_show_back

func _ready() -> void:
	# Wire hover signals so EnemyHand can respond to mouse-over.
	# NOTE: mouse_entered/mouse_exited are already connected to _on_mouse_entered/_on_mouse_exited
	# via the inherited card_ui.tscn scene file — don't reconnect here or Godot raises
	# "Signal already connected" errors.
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Apply initial back state once the render node exists
	_apply_show_back()

## Convenience helper: set stats, modifiers, and card at once.
func setup(p_card: Card, p_stats: EnemyStats, p_modifiers: ModifierHandler) -> void:
	char_stats = p_stats
	modifier_handler = p_modifiers
	card = p_card
	_apply_show_back()

## Flip from card-back to card-face with a brief horizontal squish tween.
func flip_reveal() -> void:
	if not show_back:
		return
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "scale:x", 0.0, 0.12)
	t.tween_callback(func():
		show_back = false
	)
	t.tween_property(self, "scale:x", scale.y, 0.12)  # restore to current y scale

# ── internals ────────────────────────────────────────────────────────────────

func _set_show_back(value: bool) -> void:
	show_back = value
	_apply_show_back()

func _apply_show_back() -> void:
	if not is_node_ready():
		return
	if card_render:
		card_render.show_back = show_back

func _on_mouse_entered() -> void:
	is_hovered = true
	card_hovered.emit(self)

func _on_mouse_exited() -> void:
	is_hovered = false
	card_unhovered.emit(self)
