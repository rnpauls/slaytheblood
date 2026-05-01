## Participates in the Hook system: registers on _ready, unregisters on _exit_tree.
## Override hook methods in StatusUI subclasses (modify_damage_additive,
## after_turn_end, etc.) to give individual statuses their combat behavior.
class_name StatusUI
extends Control

@export var status: Status : set = set_status

@onready var icon: TextureRect = $Icon
@onready var duration: Label = $Duration
@onready var stacks: Label = $Stacks

func set_status(new_status: Status) -> void:
	if not is_node_ready():
		await ready
	
	status = new_status
	icon.texture = status.icon
	duration.visible = status.stack_type == Status.StackType.DURATION
	stacks.visible = status.stack_type == Status.StackType.INTENSITY
	custom_minimum_size = icon.size
	
	if duration.visible:
		custom_minimum_size = duration.size + duration.position
	elif stacks.visible:
		custom_minimum_size = stacks.size + stacks.position
	
	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)
	
	_on_status_changed()

func _on_status_changed() -> void:
	if not status:
		return

	if status.can_expire and status.duration <= 0:
		queue_free()
		
	if status.stack_type == Status.StackType.INTENSITY and status.stacks == 0:
		queue_free()

	duration.text = str(status.duration)
	stacks.text = str(status.stacks)

func _ready() -> void:
	Hook.on_model_entered(self)

func _exit_tree() -> void:
	Hook.on_model_exited(self)
	if status:
		status._exit_tree(self)

# --- Hook protocol — delegates to the Status resource ---

func modify_damage_additive(dealer: Node, target: Node, vp: ValueProp) -> int:
	if status:
		return status.modify_damage_additive(dealer, target, vp, self)
	return 0

func modify_damage_multiplicative(dealer: Node, target: Node, vp: ValueProp) -> float:
	if status:
		return status.modify_damage_multiplicative(dealer, target, vp, self)
	return 1.0

func modify_block_additive(blocker: Node, vp: ValueProp) -> int:
	if status:
		return status.modify_block_additive(blocker, vp, self)
	return 0

func modify_block_multiplicative(blocker: Node, vp: ValueProp) -> float:
	if status:
		return status.modify_block_multiplicative(blocker, vp, self)
	return 1.0

func before_card_played(card: Card, ctx: Dictionary) -> void:
	if status:
		status.before_card_played(card, ctx, self)

func after_card_played(card: Card, ctx: Dictionary) -> void:
	if status:
		status.after_card_played(card, ctx, self)

func after_turn_end(side: String) -> void:
	if status:
		status.after_turn_end(side, self)

func after_attack_completed(attacker: Node, ctx: Dictionary) -> void:
	if status:
		status.after_attack_completed(attacker, ctx, self)

func on_hit_dealt(dealer: Node, target: Node, ctx: Dictionary) -> void:
	if status:
		status.on_hit_dealt(dealer, target, ctx, self)

func on_hit_received(dealer: Node, target: Node, ctx: Dictionary) -> void:
	if status:
		status.on_hit_received(dealer, target, ctx, self)
