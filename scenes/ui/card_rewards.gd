class_name CardRewards
extends ColorRect

signal reward_selected(reward: Resource)

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")
const INVENTORY_CARD_RENDER_CONTAINER = preload("res://scenes/inventory_card/inventory_card_render_container.tscn")

@export var rewards: Array[Resource] : set = set_rewards

@onready var cards: HBoxContainer = %Cards
@onready var skip_card_reward: Button = %SkipCardReward


func _ready() -> void:
	_clear_rewards()

	skip_card_reward.pressed.connect(
		func():
			reward_selected.emit(null)
			queue_free()
	)


func _clear_rewards() -> void:
	for child: Node in cards.get_children():
		child.queue_free()


func _take_reward(reward: Resource) -> void:
	reward_selected.emit(reward)
	queue_free()


func set_rewards(new_rewards: Array[Resource]) -> void:
	rewards = new_rewards

	if not is_node_ready():
		await ready

	_clear_rewards()
	for reward: Resource in rewards:
		if reward is Card:
			var new_card := CARD_MENU_UI.instantiate() as CardMenuUI
			cards.add_child(new_card)
			new_card.card = reward
			new_card.tooltip_requested.connect(_take_reward)
		elif reward is Weapon or reward is Equipment:
			var new_item := INVENTORY_CARD_RENDER_CONTAINER.instantiate() as InventoryCardRenderContainer
			new_item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			new_item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			new_item.base_scale = 0.8
			cards.add_child(new_item)
			if reward is Weapon:
				new_item.weapon = reward
			else:
				new_item.equipment = reward
			new_item.clickable = true
			new_item.pressed.connect(_take_reward)
