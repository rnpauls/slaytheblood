extends VBoxContainer

@onready var total_label: Label = $TotalLabel
@onready var type_label: Label = $TypeBreakdownLabel
@onready var rarity_label: Label = $RarityBreakdownLabel
@onready var avg_cost_label: Label = $AvgCostLabel
@onready var avg_pitch_label: Label = $AvgPitchLabel


func update_for_pile(pile: CardPile) -> void:
	if not is_node_ready():
		await ready

	if pile == null or pile.cards.is_empty():
		total_label.text = "Total: 0"
		type_label.text = "Types: —"
		rarity_label.text = "Rarity: —"
		avg_cost_label.text = "Avg cost: —"
		avg_pitch_label.text = "Avg pitch: —"
		return

	var total := pile.cards.size()
	var type_counts := {Card.Type.ATTACK: 0, Card.Type.NAA: 0, Card.Type.BLOCK: 0}
	var rarity_counts := {Card.Rarity.COMMON: 0, Card.Rarity.UNCOMMON: 0, Card.Rarity.RARE: 0}
	var sum_cost := 0
	var sum_pitch := 0

	for card in pile.cards:
		type_counts[card.type] += 1
		rarity_counts[card.rarity] += 1
		sum_cost += card.cost
		sum_pitch += card.pitch

	total_label.text = "Total: %d" % total
	type_label.text = "Types:  Attack %d   Action %d   Block %d" % [
		type_counts[Card.Type.ATTACK],
		type_counts[Card.Type.NAA],
		type_counts[Card.Type.BLOCK],
	]
	rarity_label.text = "Rarity: Common %d   Uncommon %d   Rare %d" % [
		rarity_counts[Card.Rarity.COMMON],
		rarity_counts[Card.Rarity.UNCOMMON],
		rarity_counts[Card.Rarity.RARE],
	]
	avg_cost_label.text = "Avg cost:  %.2f" % (float(sum_cost) / total)
	avg_pitch_label.text = "Avg pitch: %.2f" % (float(sum_pitch) / total)
