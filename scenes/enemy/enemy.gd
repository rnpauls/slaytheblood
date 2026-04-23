class_name Enemy
extends Area2D

const ARROW_OFFSET := 45
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

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

#var enemy_action_picker: EnemyActionPicker
var enemy_ai: EnemyAI
#var current_action: EnemyAction: set = set_current_action
var current_action: Card: set = set_current_action
var hand: Array

var active_on_hits: Array[OnHit]

#func _ready() -> void:
	#await get_tree().create_timer(2).timeout
	#take_damage(10)
	#stats.block += 8

func set_current_action(value: Card) -> void:
	current_action = value
	update_intent()

func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		#stats.stats_changed.connect(do_action) Used to be update_action
	
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
	enemy_ai.hand = hand
	enemy_card_ui.update_cards(enemy_ai)

func update_stats() -> void:
	stats_ui.update_stats(stats)

##Draw a single card and initialize it
func draw_card() -> void:
	#hand.append(stats.draw_pile.draw_card())
	#if not stats:
		#await Events.player_set_up
	var card_drawn: Card = stats.draw_pile.draw_card()
	if card_drawn:
		#hand.add_card(card_drawn)
		hand.append(card_drawn)
		#reshuffle_deck_from_discard()
		Events.enemy_card_drawn.emit(self)
		#card_drawn.card_play_finished.connect(_on_card_play_finished)
		#card_drawn.card_play_started.connect(_on_card_play_started)
		card_drawn.owner = self

##Helper function for draw_card()
func draw_cards(amount: int) -> void:
	for i in range(amount):
		draw_card()

func declare_next_attack() -> void:
	if not enemy_ai:
		return
	#if not current_action:
	current_action = enemy_ai.play_next_action()
	update_intent()
	enemy_card_ui.update_cards(enemy_ai)
	if current_action == null:
		Events.enemy_turn_completed.emit(self)
	else:
		stats.action_points -= 1
			#return
		Events.enemy_attack_declared.emit()
		await Events.player_blocks_declared
		do_action()
		#var new_conditional_action := enemy_action_picker.get_first_conditional_action()
		#if new_conditional_action and current_action != new_conditional_action:
			#current_action = new_conditional_action

func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
	
	sprite_2d.texture = stats.art
	arrow.position = Vector2.RIGHT * (sprite_2d.get_rect().size.x/2 + ARROW_OFFSET)
	#setup_ai()
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
			new_intent.base_text = "?x%s"
			new_intent.current_text = new_intent.base_text % get_num_cards_for_turn()
			new_intent.icon = null
		else:
			new_intent.current_text = "EMPTY"
			new_intent.icon = null
	intent_ui.update_intent(new_intent)

func do_action() -> void:
	#stats.block = 0
	#print_debug("Enemy defense used to be set to zero here")
	if not current_action:
		return
	
	current_action.apply_effects([enemy_ai.target], modifier_handler)
	if current_action.go_again:
		stats.action_points += 1
	
	enemy_action_completed.emit(self)
	attack_completed.emit()
	enemy_card_ui.update_cards(enemy_ai)

#Defend player attack
#attack: base attack
#modifiers: Player modifiers
#go_again: if the attack has go_again
func defend_attack(attack: int, go_again: bool) -> void:
	var defense_array := enemy_ai.defend(attack, go_again)
	#if defense_array.is_empty():
		#return 0
	#else:
	stats.block += defense_array.reduce(func(sum, plus): return sum + plus, 0)
	#return defense_array.reduce(func(sum, plus) : sum + plus, 0)
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
	#tween.tween_callback(stats.take_damage.bind(mod_dmg))
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
	#enemy_ai.end_turn()
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
