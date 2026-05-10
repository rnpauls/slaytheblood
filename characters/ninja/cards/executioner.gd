## Marked spend. Reads target's Marked stacks, adds them to the swing damage,
## and consumes the Marked status. With Marked 6 + 5 base, that's 11 from
## the card; plus Marked still lives on DMG_TAKEN at hit time, adding +6 more
## before consume — net 17 against a Marked 6 target. Big finisher.
##
## Marked is consumed by setting stacks=0; StatusUI auto-removes when stacks
## reach 0 and status._exit_tree clears the DMG_TAKEN modifier.
extends Card


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty() or targets[0] == null:
		return
	var target_node := targets[0]
	var bonus := 0
	var marked: Status = null
	if target_node.status_handler:
		marked = target_node.status_handler.get_status_by_id("marked")
		if marked:
			bonus = marked.stacks
	do_stock_attack_damage_effect(targets, modifiers, attack + bonus)
	if marked:
		marked.stacks = 0
