## Participates in the Hook system: registers on _ready, unregisters on _exit_tree.
## Override hook methods in RelicUI subclasses (after_attack_completed,
## after_turn_end, etc.) to give individual relics their combat behavior.
class_name RelicUI
extends Control

@export var relic: Relic : set = set_relic

@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	Hook.on_model_entered(self)

func _exit_tree() -> void:
	Hook.on_model_exited(self)

# --- Hook protocol — delegates to the Relic resource ---

func modify_damage_additive(dealer: Node, target: Node, vp: ValueProp) -> int:
	return relic.modify_damage_additive(dealer, target, vp, self) if relic else 0

func modify_damage_multiplicative(dealer: Node, target: Node, vp: ValueProp) -> float:
	return relic.modify_damage_multiplicative(dealer, target, vp, self) if relic else 1.0

func modify_block_additive(blocker: Node, vp: ValueProp) -> int:
	return relic.modify_block_additive(blocker, vp, self) if relic else 0

func modify_block_multiplicative(blocker: Node, vp: ValueProp) -> float:
	return relic.modify_block_multiplicative(blocker, vp, self) if relic else 1.0

func before_card_played(card: Card, ctx: Dictionary) -> void:
	if relic: relic.before_card_played(card, ctx, self)

func after_card_played(card: Card, ctx: Dictionary) -> void:
	if relic: relic.after_card_played(card, ctx, self)

func after_turn_end(side: String) -> void:
	if relic: relic.after_turn_end(side, self)

func after_attack_completed(attacker: Node, ctx: Dictionary) -> void:
	if relic: relic.after_attack_completed(attacker, ctx, self)

func on_hit_dealt(dealer: Node, target: Node, ctx: Dictionary) -> void:
	if relic: relic.on_hit_dealt(dealer, target, ctx, self)

func on_hit_received(dealer: Node, target: Node, ctx: Dictionary) -> void:
	if relic: relic.on_hit_received(dealer, target, ctx, self)

func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready
	
	relic = new_relic
	icon.texture = relic.icon

func flash() -> void:
	animation_player.play("flash")

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.relic_tooltip_requested.emit(relic)
