class_name IntentUI
extends Control

## Set by Enemy after instantiation so hover can read its on-hits and action.
var enemy: Enemy = null

@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label
@onready var atk_label: Label = %AtkLabel
@onready var exclamation: TextureRect = %Exclamation

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func update_intent(intent: Intent) -> void:
	if not intent:
		hide()
		return

	icon.texture = intent.icon
	icon.visible = icon.texture != null
	if not intent.current_text.is_empty() and intent.current_text[0].is_valid_int():
		atk_label.text = intent.current_text
		atk_label.show()
		label.hide()
	elif intent.current_text.length() > 0:
		label.text = intent.current_text
		label.show()
		atk_label.hide()
	else:
		label.hide()
		atk_label.hide()

	var has_on_hit := false
	if enemy and enemy.current_action and enemy.current_action.type == Card.Type.ATTACK:
		# [kw=onhit] in tooltip_text catches cards that lazily append OnHits
		# inside apply_effects (Lacerate, Brittle Bones, etc.) and so have an
		# empty on_hits array pre-first-play. parse_keywords reads the same
		# structured markup the tooltip chain already consumes.
		has_on_hit = enemy.current_action.on_hits.size() > 0 \
			or enemy.active_on_hits.size() > 0 \
			or KeywordRegistry.parse_keywords(enemy.current_action.tooltip_text).has(&"onhit")
	exclamation.visible = has_on_hit

	show()

func _on_mouse_entered() -> void:
	if not enemy or not enemy.current_action:
		return
	var body := _build_tooltip_text()
	var entries: Array[TooltipData] = [
		TooltipData.make(enemy.current_action.icon, "", body),
	]
	entries.append_array(KeywordRegistry.build_tooltip_chain(body))
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))
	Events.intent_hovered.emit(enemy)

func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
	if enemy:
		Events.intent_unhovered.emit(enemy)

## Build a tooltip string showing damage and any on-hit effects.
func _build_tooltip_text() -> String:
	if not enemy or not enemy.current_action:
		return ""

	var action := enemy.current_action
	var lines: Array[String] = []

	# Damage line (attacks, and any action carrying zap)
	if action.type == Card.Type.ATTACK or action.zap > 0:
		var phys := action.get_attack_value()
		var arc := action.zap
		if enemy.modifier_handler:
			if phys > 0:
				phys = enemy.modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
			if arc > 0:
				arc = enemy.modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
		var dmg := phys + arc
		if enemy.enemy_ai and enemy.enemy_ai.target and enemy.enemy_ai.target.modifier_handler:
			dmg = enemy.enemy_ai.target.modifier_handler.get_modified_value(dmg, Modifier.Type.DMG_TAKEN)
		lines.append("[b]Deals %d damage[/b]" % dmg)
		if action.go_again:
			lines.append("Go Again")

	# Card's own description (covers per-card on-hits like Lacerate's Bleed).
	if action.tooltip_text != "":
		lines.append("")
		lines.append(action.tooltip_text)

	# Status-applied on-hits (Poison Tip, etc.) carried by the combatant.
	if enemy.active_on_hits.size() > 0:
		lines.append("")
		lines.append("[b]On hit:[/b]")
		for oh: OnHit in enemy.active_on_hits:
			if oh.id != "":
				lines.append("  • %s" % oh.id.capitalize().replace("_", " "))

	return "\n".join(lines)
