## Hook — global autoload
##
## Central registry and dispatcher for the AbstractModel hook system.
## Any Node that follows the AbstractModel protocol calls on_model_entered(self)
## in _ready and on_model_exited(self) in _exit_tree to participate.
##
## Dispatch uses duck typing: each method checks has_method before calling,
## so nodes only need to implement the hooks they care about.
##
## Snapshot safety: every dispatch duplicates the registry before iterating,
## so a model entering or exiting during a dispatch doesn't affect the current pass.
##
## Lifecycle: call Hook.clear() when a battle ends (battle.gd) to flush all
## registered models and prevent stale hooks in the next battle.

extends Node

signal model_registered(model: Node)
signal model_unregistered(model: Node)

var _models: Array[Node] = []

# Set during after_card_played / before_card_played dispatches so StatusUI
# nodes registered mid-dispatch can read the current card's play key.
var current_play_key: String = ""


# ---------------------------------------------------------------------------
# Registration — called from _ready / _exit_tree on participant nodes
# ---------------------------------------------------------------------------

func on_model_entered(model: Node) -> void:
	if _models.has(model):
		return
	_models.append(model)
	model_registered.emit(model)


func on_model_exited(model: Node) -> void:
	if _models.erase(model):
		model_unregistered.emit(model)


## Flush all registered models. Call at the end of every battle.
func clear() -> void:
	var snapshot := _models.duplicate()
	_models.clear()
	for m in snapshot:
		model_unregistered.emit(m)


# ---------------------------------------------------------------------------
# Aggregating dispatches — damage / block
# ---------------------------------------------------------------------------

## Returns the final damage value after additive then multiplicative passes.
func get_damage(dealer: Node, target: Node, base: int) -> int:
	var vp := ValueProp.new(base)
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("modify_damage_additive"):
			vp.value += m.modify_damage_additive(dealer, target, vp)
	var mult := 1.0
	for m: Node in snapshot:
		if m.has_method("modify_damage_multiplicative"):
			mult *= m.modify_damage_multiplicative(dealer, target, vp)
	return floori(vp.value * mult)


## Returns the final block value after additive then multiplicative passes.
func get_block(blocker: Node, base: int) -> int:
	var vp := ValueProp.new(base)
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("modify_block_additive"):
			vp.value += m.modify_block_additive(blocker, vp)
	var mult := 1.0
	for m: Node in snapshot:
		if m.has_method("modify_block_multiplicative"):
			mult *= m.modify_block_multiplicative(blocker, vp)
	return floori(vp.value * mult)


# ---------------------------------------------------------------------------
# Side-effect dispatches — lifecycle
# ---------------------------------------------------------------------------

func before_card_played(card: Card, ctx: Dictionary) -> void:
	current_play_key = _make_play_key(card)
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("before_card_played"):
			m.before_card_played(card, ctx)
	current_play_key = ""


func after_card_played(card: Card, ctx: Dictionary) -> void:
	current_play_key = _make_play_key(card)
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("after_card_played"):
			m.after_card_played(card, ctx)
	current_play_key = ""


## side: "player" or "enemy"
func after_turn_end(side: String) -> void:
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("after_turn_end"):
			m.after_turn_end(side)


func after_attack_completed(attacker: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("after_attack_completed"):
			m.after_attack_completed(attacker, ctx)


func on_hit_dealt(dealer: Node, target: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("on_hit_dealt"):
			m.on_hit_dealt(dealer, target, ctx)


func on_hit_received(dealer: Node, target: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: Node in snapshot:
		if m.has_method("on_hit_received"):
			m.on_hit_received(dealer, target, ctx)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_play_key(card: Card) -> String:
	return card.id + "_" + str(card.play_count)
