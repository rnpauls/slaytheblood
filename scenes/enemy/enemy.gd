class_name Enemy
extends Area2D

const ARROW_OFFSET := 45
const WHITE_SPRITE_MATERIAL := preload("res://art/themes/white_sprite_material.tres")
const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI as StatsUI
@onready var intent_ui: IntentUI = $IntentUI as IntentUI
@onready var enemy_card_ui: EnemyCardUI = $EnemyCardUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

signal enemy_action_completed
signal attack_completed

var enemy_ai: EnemyAI
# hand stores CardUI nodes (non-interactive); enemy_ai.hand mirrors the underlying Cards
var hand: Array[CardUI]

var current_action: Card: set = set_current_action

var active_on_hits: Array[OnHit]

func set_current_action(value: Card) -> void:
	current_action = value
	update_intent()

func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
	
	update_enemy()

func setup_ai() -> void:
	if enemy_ai:
		enemy_ai.queue_free()
	
	var new_ai: EnemyAI = stats.ai.instantiate()
	add_child(new_ai)
	enemy_ai = new_ai
	enemy_ai.enemy = self
	enemy_ai.modifier_handler = modifier_handler
	enemy_ai.setup()
	# Give the AI a Card array mirrored from our CardUI hand
	enemy_ai.hand = hand.map(func(cui: CardUI) -> Card: return cui.card)
	enemy_card_ui.update_cards(enemy_ai)

func update_stats() -> void:
	stats_ui.update_stats(stats)

## Create a CardUI wrapper for a Card and add it to the hand
func _make_card_ui(card: Card) -> CardUI:
	var cui: CardUI = CARD_UI_SCENE.instantiate()
	cui.is_enemy_card = true
	cui.char_stats = stats
	cui.player_modifiers = modifier_handler
	cui.card = card
	return cui

## Draw a single card and initialise it as a CardUI
func draw_card() -> void:
	var card_drawn: Card = stats.draw_pile.draw_card()
	if card_drawn:
		card_drawn.owner = self
		var cui := _make_card_ui(card_drawn)
		hand.append(cui)
		# Keep the AI's card array in sync
		if enemy_ai:
			enemy_ai.hand = hand.map(func(c: CardUI) -> Card: return c.card)
		Events.enemy_card_drawn.emit(self)

## Helper function for draw_card()
func draw_cards(amount: int) -> void:
	for i in range(amount):
		draw_card()

func declare_next_attack() -> void:
	if not enemy_ai:
		return
	current_action = enemy_ai.play_next_action()
	update_intent()
	enemy_card_ui.update_cards(enemy_ai)
	if current_action == null:
		Events.enemy_turn_completed.emit(self)
	else:
		# action_points are decremented by card.play() via char_stats, so don't double-decrement
		Events.enemy_attack_declared.emit()
		await Events.player_blocks_declared
		do_action()

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
	
	sprite_2d.texture = stats.art
	arrow.position = Vector2.RIGHT * (sprite_2d.get_rect().size.x/2 + ARROW_OFFSET)
	update_stats()

func update_intent() -> void:
	var new_intent = Intent.new()
	if current_action and current_action.type == Card.Type.ATTACK:
		var og_atk = current_action.attack
		var modified_damage := modifier_handler.get_modified_value(og_atk, Modifier.Type.DMG_DEALT)
		modified_damage = enemy_ai.target.modifier_handler.get_modified_value(modified_damage, Modifier.Type.DMG_TAKEN)
		
		if current_action.go_again:
			new_intent.base_text = "%s GA"
		else:
			new_intent.base_text = "%s"
		new_intent.current_text = new_intent.base_text % modified_damage
		new_intent.icon = preload("res://art/tile_0103.png")
	else:
		if enemy_ai and enemy_ai.hand.size() > 0:
			new_intent.base_text = "? X %s"
			new_intent.current_text = new_intent.base_text % get_num_cards_for_turn()
			new_intent.icon = null
		else:
			new_intent.current_text = "EMPTY"
			new_intent.icon = null
	intent_ui.update_intent(new_intent)

func do_action() -> void:
	if not current_action:
		return
	
	# Find the CardUI wrapper for current_action and play it properly.
	# card.play() handles mana/action_points, emits signals, clears target block, and
	# calls apply_effects — fixing the previous bypass of these side-effects.
	var action_cui: CardUI = null
	for cui in hand:
		if cui.card == current_action:
			action_cui = cui
			break
	
	if action_cui:
		# targets is set to the player by the AI
		action_cui.targets = [enemy_ai.target]
		action_cui.play()   # calls card.play() then queue_frees the CardUI
		hand.erase(action_cui)
	else:
		# Fallback: card was already removed from hand (e.g. pitched), play directly
		current_action.card_play_started.emit(current_action)
		if current_action.type == Card.Type.ATTACK:
			enemy_ai.target.stats.block = 0
		current_action.apply_effects([enemy_ai.target], modifier_handler)
		current_action.card_play_finished.emit(current_action)
	
	# Keep AI hand mirror in sync
	if enemy_ai:
		enemy_ai.hand = hand.map(func(c: CardUI) -> Card: return c.card)
	
	enemy_action_completed.emit(self)
	attack_completed.emit()
	enemy_card_ui.update_cards(enemy_ai)

#Defend player attack
func defend_attack(attack: int, go_again: bool, incoming_on_hits: Array[OnHit]) -> void:
	var defense_array := enemy_ai.defend(attack, go_again, incoming_on_hits)
	for def_card in defense_array:
		def_card.apply_block_effects([self], modifier_handler)
	update_intent()
	enemy_card_ui.update_cards(enemy_ai)


func take_damage(damage: int, which_modifier: Modifier.Type) -> int:
	if stats.health <= 0:
		return 0
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	
	var mod_dmg := modifier_handler.get_modified_value(damage, which_modifier)
	var damage_taken: = stats.take_damage(mod_dmg)
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				Events.enemy_died.emit(self)
				queue_free()
	)
	return damage_taken
	
func get_num_cards_for_turn() -> int:
	var player_life = get_tree().get_first_node_in_group("player").stats.health
	var turn_plan: Dictionary = enemy_ai.calculate_max_offense_now(player_life)
	return turn_plan.actions.size()

func cleanup_phase() -> void:
	draw_cards(stats.cards_per_turn - hand.size())
	stats.block = 0
	stats.action_points = 1
	enemy_card_ui.update_cards(enemy_ai)

func destroy_arsenal() -> bool:
	if enemy_ai.arsenal == null:
		return false
	else:
		var arsenal_card: Card = enemy_ai.arsenal
		enemy_ai.arsenal = null
		arsenal_card.queue_free()
		return true

func _on_area_entered(_area):
	arrow.show()


func _on_area_exited(_area):
	arrow.hide()
