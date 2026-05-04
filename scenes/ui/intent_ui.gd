class_name IntentUI
extends HBoxContainer

## Set by Enemy after instantiation so hover can read its on-hits and action.
var enemy: Enemy = null

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

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
	label.text = intent.current_text
	label.visible = intent.current_text.length() > 0
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

	# Damage line (only for attacks)
	if action.type == Card.Type.ATTACK:
		var dmg: int = action.attack
		if enemy.modifier_handler:
			dmg = enemy.modifier_handler.get_modified_value(dmg, Modifier.Type.DMG_DEALT)
		if enemy.enemy_ai and enemy.enemy_ai.target and enemy.enemy_ai.target.modifier_handler:
			dmg = enemy.enemy_ai.target.modifier_handler.get_modified_value(dmg, Modifier.Type.DMG_TAKEN)
		lines.append("[b]Deals %d damage[/b]" % dmg)
		if action.go_again:
			lines.append("Go Again")

	# On-hit effects
	if enemy.active_on_hits.size() > 0:
		lines.append("")
		lines.append("[b]On hit:[/b]")
		for oh: OnHit in enemy.active_on_hits:
			if oh.id != "":
				lines.append("  • %s" % oh.id.capitalize().replace("_", " "))

	return "\n".join(lines)
