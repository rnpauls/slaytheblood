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
	var ca = enemy.current_action if enemy else null
	if ca is Card and (ca as Card).type == Card.Type.ATTACK:
		# [kw=onhit] in tooltip_text catches cards that lazily append OnHits
		# inside apply_effects (Lacerate, Brittle Bones, etc.) and so have an
		# empty on_hits array pre-first-play. parse_keywords reads the same
		# structured markup the tooltip chain already consumes.
		var attack_card: Card = ca as Card
		has_on_hit = attack_card.on_hits.size() > 0 \
			or enemy.active_on_hits.size() > 0 \
			or KeywordRegistry.parse_keywords(attack_card.tooltip_text).has(&"onhit")
	elif ca is Weapon:
		var weapon: Weapon = ca as Weapon
		has_on_hit = weapon.on_hits.size() > 0 \
			or enemy.active_on_hits.size() > 0
	exclamation.visible = has_on_hit

	show()

func _on_mouse_entered() -> void:
	if not enemy or not enemy.current_action:
		return
	var body := _build_tooltip_text()
	var ca_icon: Texture2D = null
	var ca = enemy.current_action
	if ca is Card:
		ca_icon = (ca as Card).icon
	elif ca is Weapon:
		ca_icon = (ca as Weapon).icon
	var entries: Array[TooltipData] = [
		TooltipData.make(ca_icon, "", body),
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

	var action = enemy.current_action
	var lines: Array[String] = []

	# Damage / go_again / per-action description vary per type (Card vs Weapon).
	if action is Card:
		var card: Card = action as Card
		if card.type == Card.Type.ATTACK or card.zap > 0:
			var phys: int = card.get_attack_value()
			var arc: int = card.zap
			if enemy.modifier_handler:
				if phys > 0:
					phys = enemy.modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
				if arc > 0:
					arc = enemy.modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
			var dmg: int = phys + arc
			if enemy.enemy_ai and enemy.enemy_ai.target and enemy.enemy_ai.target.modifier_handler:
				dmg = enemy.enemy_ai.target.modifier_handler.get_modified_value(dmg, Modifier.Type.DMG_TAKEN)
			lines.append("[b]Deals %d damage[/b]" % dmg)
			if card.go_again:
				lines.append("Go Again")
		# Card's own description (covers per-card on-hits like Lacerate's Bleed).
		if card.tooltip_text != "":
			lines.append("")
			lines.append(card.tooltip_text)
	elif action is Weapon:
		var weapon: Weapon = action as Weapon
		var phys: int = weapon.attack
		var arc: int = weapon.zap
		if enemy.modifier_handler:
			if phys > 0:
				phys = enemy.modifier_handler.get_modified_value(phys, Modifier.Type.DMG_DEALT)
			if arc > 0:
				arc = enemy.modifier_handler.get_modified_value(arc, Modifier.Type.ARCANE_DEALT)
		var dmg: int = phys + arc
		if enemy.enemy_ai and enemy.enemy_ai.target and enemy.enemy_ai.target.modifier_handler:
			dmg = enemy.enemy_ai.target.modifier_handler.get_modified_value(dmg, Modifier.Type.DMG_TAKEN)
		lines.append("[b]Deals %d damage[/b]" % dmg)
		if weapon.go_again:
			lines.append("Go Again")
		if weapon.tooltip != "":
			lines.append("")
			lines.append(weapon.tooltip)

	# Status-applied on-hits (Poison Tip, etc.) carried by the combatant.
	if enemy.active_on_hits.size() > 0:
		lines.append("")
		lines.append("[b]On hit:[/b]")
		for oh: OnHit in enemy.active_on_hits:
			if oh.id != "":
				lines.append("  • %s" % oh.id.capitalize().replace("_", " "))

	return "\n".join(lines)
