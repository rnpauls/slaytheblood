class_name StunnedStatus
extends Status

## Bearer cannot play, pitch, or block while present. Gates live in
## card_base_state.gd (player) and enemy_ai.gd (enemy); the player's action
## phase auto-skips via player_action_state.gd.
##
## Expires at the end of the bearer's own next turn (inverse of intimidate,
## which expires on the opposite side's turn end) so the bearer loses one full
## turn of agency.

## SpriteFrames path for the head-spin visual. Asset is forthcoming (pixellab);
## the overlay no-ops gracefully until it lands so the gameplay ships first.
const STUN_FRAMES_PATH := "res://art/effects/stun_stars.tres"
## Pixels above the sprite top where the overlay anchors. Both Player and Enemy
## sprite_2ds are feet-anchored at local (0,0), so -display_height is the head.
const HEAD_PAD := 10.0

var _target_ref: Node = null
var _bound_apply: Callable
var _overlay: AnimatedSprite2D = null


func initialize_status(target: Node) -> void:
	_target_ref = target
	_bound_apply = apply_status.bind(target)
	if target is Enemy:
		Events.enemy_phase_ended.connect(_bound_apply)
	else:
		Events.player_turn_ended.connect(_bound_apply)
	_spawn_overlay(target)


func apply_status(_target) -> void:
	status_applied.emit(self)


func _exit_tree() -> void:
	if _bound_apply:
		if _target_ref is Enemy:
			if Events.enemy_phase_ended.is_connected(_bound_apply):
				Events.enemy_phase_ended.disconnect(_bound_apply)
		else:
			if Events.player_turn_ended.is_connected(_bound_apply):
				Events.player_turn_ended.disconnect(_bound_apply)
	if is_instance_valid(_overlay):
		_overlay.queue_free()


# Spawn the spin-stars overlay as a child of the combatant (sibling to sprite_2d
# and status_handler, so it inherits the same local transform). Hidden if the
# SpriteFrames asset hasn't landed yet — the status still works without art.
func _spawn_overlay(target: Node) -> void:
	if target == null or not (target is Combatant):
		return
	_overlay = AnimatedSprite2D.new()
	_overlay.name = "StunnedOverlay"
	var head_y := -float(target.stats.display_height) - HEAD_PAD
	_overlay.position = Vector2(0.0, head_y)
	if ResourceLoader.exists(STUN_FRAMES_PATH):
		var frames := load(STUN_FRAMES_PATH) as SpriteFrames
		if frames:
			_overlay.sprite_frames = frames
			if frames.has_animation(&"default"):
				_overlay.play(&"default")
	else:
		_overlay.visible = false
	target.add_child(_overlay)
