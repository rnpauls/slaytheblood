class_name FloodgateStatus
extends Status

## Arcane scaling for the Runeblade. Contributes its `stacks` as a FLAT value to
## the owner's ARCANE_DEALT modifier, so every zap the player explicitly deals
## (printed zap, weapon zap, do_zap_effect detonators) is buffed while it's up.
## Decays after the next arcane card resolves, or at turn end if unused.

var damage_modifier: Modifier
var _target: Node


func get_tooltip() -> String:
	return tooltip % stacks


func initialize_status(target: Node) -> void:
	_target = target
	damage_modifier = target.modifier_handler.get_modifier(Modifier.Type.ARCANE_DEALT)
	var arc_modifier_value: ModifierValue = ModifierValue.create_new_modifier("floodgate", ModifierValue.Type.FLAT)
	arc_modifier_value.flat_value = stacks
	damage_modifier.add_new_value(arc_modifier_value)
	if target is Player:
		# Deferred so the player_card_played of the card currently resolving (the
		# one that just granted this Floodgate) is skipped — the grant carries to
		# the NEXT arcane card instead of being consumed by its own source.
		_arm_decay.call_deferred()
		Events.player_turn_ended.connect(apply_status.bind(target))


func _arm_decay() -> void:
	if not Events.player_card_played.is_connected(_on_card_played):
		Events.player_card_played.connect(_on_card_played)


## Any arcane card (zap > 0) consumes Floodgate after it finishes resolving.
func _on_card_played(card: Card) -> void:
	if card.zap > 0:
		apply_status(_target)


func update() -> void:
	damage_modifier.set_value_flat_value("floodgate", stacks)


func apply_status(_t) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if damage_modifier:
		damage_modifier.remove_value("floodgate")
