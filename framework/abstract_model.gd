## AbstractModel — hook participant interface
##
## This script is NOT a base class. It documents the protocol that any node
## must follow to participate in the Hook system. Copy the _ready/_exit_tree
## registration lines into your class and override whichever hook methods you need.
##
## Participants: CardUI, StatusUI, RelicUI, Combatant (Enemy/Player), and any
## future node that needs to intercept combat lifecycle events.
##
## Hook stores Array[Node] and dispatches via duck typing (has_method / call).
## This file is the single source of truth for method names and signatures.

## ── Registration (add to _ready / _exit_tree in each participant) ─────────
##
##   func _ready() -> void:
##       Hook.on_model_entered(self)
##       ...
##
##   func _exit_tree() -> void:
##       Hook.on_model_exited(self)
##       ...

## ── Damage / block modification ──────────────────────────────────────────
## Return value is composed by Hook across all registered models.
##
## func modify_damage_additive(dealer: Node, target: Node, vp: ValueProp) -> int: return 0
## func modify_damage_multiplicative(dealer: Node, target: Node, vp: ValueProp) -> float: return 1.0
## func modify_block_additive(blocker: Node, vp: ValueProp) -> int: return 0
## func modify_block_multiplicative(blocker: Node, vp: ValueProp) -> float: return 1.0

## ── Lifecycle (side effects, no return value) ─────────────────────────────
##
## func before_card_played(card: Card, ctx: Dictionary) -> void: pass
## func after_card_played(card: Card, ctx: Dictionary) -> void: pass
## func after_turn_end(side: String) -> void: pass
## func after_attack_completed(attacker: Node, ctx: Dictionary) -> void: pass
## func on_hit_dealt(dealer: Node, target: Node, ctx: Dictionary) -> void: pass
## func on_hit_received(dealer: Node, target: Node, ctx: Dictionary) -> void: pass
