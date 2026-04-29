## Non-interactive card display used inside the enemy's hand.
## Extends CardUI for rendering but has no state machine or player interactivity.
## EnemyAI works only with Card data; this is purely for display purposes.
class_name EnemyCardUI
extends CardUI


func _ready() -> void:
	# Display-only: no state machine, no event connections
	pass

## Convenience helper: set stats, modifiers, and card at once.
func setup(p_card: Card, p_stats: EnemyStats, p_modifiers: ModifierHandler) -> void:
	# char_stats setter will also wire up stats_changed (for future display updates)
	char_stats = p_stats
	modifier_handler = p_modifiers
	card = p_card
