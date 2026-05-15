class_name Combatant
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/themes/white_sprite_material.tres")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

@export var stats: Stats : set = set_stats
var active_on_hits: Array[OnHit]

## Symmetric hand-operation interface for effects. Concrete subclasses
## (Player, Enemy) instantiate the matching HandFacade subclass during their
## own setup (player_handler.start_battle for the player, enemy.setup_ai
## for the enemy). Effects call e.g. target.hand_facade.discard_random(2).
var hand_facade: HandFacade

## Back-ref to the BattleUI for the current battle. Set by Battle.start_battle
## (player) / EnemyHandler.setup_enemies (each enemy) so call sites that need
## BattleUI (card_ui pile handoff, enemy_resource_ui discard view,
## player_handler reshuffle visual) can read combatant.battle_ui instead of
## doing a get_first_node_in_group("ui_layer") lookup.
var battle_ui: BattleUI

signal attack_completed

func set_stats(value: Stats) -> void:
	stats = _init_stats(value)
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	_on_stats_set()

## Override to transform the incoming stats value before it is assigned.
## e.g. Enemy calls value.create_instance() here.
func _init_stats(value: Stats) -> Stats:
	return value

## Override to react after stats is assigned and the signal is connected.
func _on_stats_set() -> void:
	pass

func update_stats() -> void:
	stats_ui.update_stats(stats)

func take_damage(damage: int, which_modifier: Modifier.Type, damage_kind: Card.DamageKind = Card.DamageKind.PHYSICAL, prevention: int = -1, ignore_block: bool = false) -> int:
	if stats.health <= 0:
		return 0

	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier, damage_kind)
	var damage_taken := stats.take_damage(modified_damage, damage_kind, prevention, ignore_block)

	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_interval(0.17)
	tween.finished.connect(func():
		sprite_2d.material = null
		if stats.health <= 0:
			_on_death()
	)
	return damage_taken

## Override in subclasses to handle death (emit event, queue_free, etc.)
func _on_death() -> void:
	pass

## Tooltip stack shown when hovering this combatant's sprite. Combines the
## status grid's entries with a summary card listing active on-hits.
func get_hover_tooltip_entries() -> Array[TooltipData]:
	var entries: Array[TooltipData] = []
	if status_handler:
		entries.append_array(status_handler.get_tooltip_entries())

	var on_hit_lines: Array[String] = []
	for oh: OnHit in active_on_hits:
		if oh != null and oh.id != "":
			on_hit_lines.append("  • %s" % oh.id.capitalize().replace("_", " "))
	if not on_hit_lines.is_empty():
		entries.append(TooltipData.make(null, "On hit", "\n".join(on_hit_lines)))

	return entries
