## Hook — global autoload
##
## Central registry and dispatcher for AbstractModel lifecycle hooks.
## All combat entities (statuses, relics, card effects) register here;
## combat flow code calls the dispatch methods at named lifecycle points.
##
## Snapshot safety: every dispatch duplicates the registry before iterating,
## so a model registered or unregistered during a dispatch does not affect
## the current iteration.
##
## Lifecycle: call Hook.clear() when a battle ends to flush all registered
## models and prevent stale hooks firing in the next battle.

extends Node

signal model_registered(model: AbstractModel)
signal model_unregistered(model: AbstractModel)

var _models: Array[AbstractModel] = []

# True while we are inside a dispatch loop. Used to tag newly registered
# models with the current play key so they can skip their trigger card.
var _dispatching_play_key: String = ""


# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

func register(model: AbstractModel, owner: Node) -> void:
	model._owner_ref = weakref(owner)
	if _dispatching_play_key != "":
		model._registered_during_play_key = _dispatching_play_key
	_models.append(model)
	model_registered.emit(model)


func unregister(model: AbstractModel) -> void:
	if _models.erase(model):
		model_unregistered.emit(model)


## Remove all registered models. Call at the end of every battle.
func clear() -> void:
	var snapshot := _models.duplicate()
	_models.clear()
	for m in snapshot:
		model_unregistered.emit(m)


# ---------------------------------------------------------------------------
# Aggregating dispatches (damage / block)
# ---------------------------------------------------------------------------

## Returns the final damage value after all additive then multiplicative hooks.
func get_damage(dealer: Node, target: Node, base: int) -> int:
	var vp := ValueProp.new(base)
	var snapshot := _models.duplicate()
	# Additive pass
	for m: AbstractModel in snapshot:
		vp.value += m.modify_damage_additive(dealer, target, vp)
	# Multiplicative pass
	var mult := 1.0
	for m: AbstractModel in snapshot:
		mult *= m.modify_damage_multiplicative(dealer, target, vp)
	return floori(vp.value * mult)


## Returns the final block value after all additive then multiplicative hooks.
func get_block(owner_node: Node, base: int) -> int:
	var vp := ValueProp.new(base)
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		vp.value += m.modify_block_additive(owner_node, vp)
	var mult := 1.0
	for m: AbstractModel in snapshot:
		mult *= m.modify_block_multiplicative(owner_node, vp)
	return floori(vp.value * mult)


# ---------------------------------------------------------------------------
# Side-effect dispatches (lifecycle)
# ---------------------------------------------------------------------------

func before_card_played(card: Card, ctx: Dictionary) -> void:
	var play_key := _make_play_key(card)
	_dispatching_play_key = play_key
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.before_card_played(card, ctx)
	_dispatching_play_key = ""


func after_card_played(card: Card, ctx: Dictionary) -> void:
	var play_key := _make_play_key(card)
	_dispatching_play_key = play_key
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.after_card_played(card, ctx)
	_dispatching_play_key = ""


## side: "player" or "enemy"
func after_turn_end(side: String) -> void:
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.after_turn_end(side)


func after_attack_completed(attacker: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.after_attack_completed(attacker, ctx)


func on_hit_dealt(dealer: Node, target: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.on_hit_dealt(dealer, target, ctx)


func on_hit_received(dealer: Node, target: Node, ctx: Dictionary) -> void:
	var snapshot := _models.duplicate()
	for m: AbstractModel in snapshot:
		if not is_instance_valid(m.owner()):
			continue
		m.on_hit_received(dealer, target, ctx)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_play_key(card: Card) -> String:
	return card.id + "_" + str(card.play_count)
