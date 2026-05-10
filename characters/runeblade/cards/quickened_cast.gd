## Detonate every active Channel immediately instead of waiting for the
## next turn. Iterates the runeblade's status_handler children, finds any
## status whose id starts with "channel_", and calls apply_status — which
## fires the channel's payload AND emits status_applied (so duration ticks
## to 0 and the status auto-removes).
##
## Snapshots the channel list before firing because apply_status causes
## the StatusUI children to be removed mid-iteration.
extends Card


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if owner == null or owner.status_handler == null:
		return
	var channels: Array[Status] = []
	for child in owner.status_handler.get_children():
		var status_ui := child as StatusUI
		if status_ui == null:
			continue
		var s: Status = status_ui.status
		if s and String(s.id).begins_with("channel_"):
			channels.append(s)
	for c in channels:
		c.apply_status(owner)
