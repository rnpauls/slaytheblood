class_name Status
extends Resource

signal status_applied(status: Status)
signal status_changed

enum Type {START_OF_TURN, END_OF_TURN, EVENT_BASED}
enum StackType {NONE, INTENSITY, DURATION}

@export_group("Status Data")
@export var id: String
@export var type: Type
@export var stack_type: StackType
@export var can_expire: bool
@export var duration: int : set = set_duration
@export var stacks: int : set = set_stacks

@export_group("Status Visuals")
@export var icon: Texture
@export_multiline var tooltip: String


func initialize_status(_target: Node) -> void:
	pass


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip


func set_duration(new_duration: int) -> void:
	duration = new_duration
	status_changed.emit()


func set_stacks(new_stacks: int) -> void:
	stacks = new_stacks
	status_changed.emit()

func update() -> void:
	pass

## Called by StatusUI._exit_tree. Override to clean up when the status is removed.
## ui is the StatusUI node that owns this status.
func _exit_tree(_ui: Node) -> void:
	pass

# --- Hook virtuals (called by StatusUI delegation) ---
# ui: the StatusUI node registered with Hook — use ui.queue_free() to remove the status,
# or get_status_owner(ui) to find the combatant this status belongs to.

static func get_status_owner(ui: Node) -> Node:
	## Walk up to find the Combatant (StatusHandler is GridContainer child of Combatant).
	var parent := ui.get_parent()
	if parent:
		return parent.get_parent()
	return null

func modify_damage_additive(_dealer: Node, _target: Node, _vp: ValueProp, _ui: Node) -> int:
	return 0

func modify_damage_multiplicative(_dealer: Node, _target: Node, _vp: ValueProp, _ui: Node) -> float:
	return 1.0

func modify_block_additive(_blocker: Node, _vp: ValueProp, _ui: Node) -> int:
	return 0

func modify_block_multiplicative(_blocker: Node, _vp: ValueProp, _ui: Node) -> float:
	return 1.0

func before_card_played(_card: Card, _ctx: Dictionary, _ui: Node) -> void:
	pass

func after_card_played(_card: Card, _ctx: Dictionary, _ui: Node) -> void:
	pass

func after_turn_end(_side: String, _ui: Node) -> void:
	pass

func after_attack_completed(_attacker: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass

func on_hit_dealt(_dealer: Node, _target: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass

func on_hit_received(_dealer: Node, _target: Node, _ctx: Dictionary, _ui: Node) -> void:
	pass
