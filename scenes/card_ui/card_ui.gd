class_name CardUI
extends Control

# Lifecycle signals — connect these when you instantiate the card
signal played(card_ui: CardUI)
signal pitched(card_ui: CardUI)
signal sunk(card_ui: CardUI)
signal blocked(card_ui: CardUI)
signal discarded(card_ui: CardUI)

@export var card: Card : set = _set_card
@export var stats: Stats : set = _set_stats
@export var modifiers: ModifierHandler

@onready var card_render: CardRenderContainer = $CardRenderContainer

var targets: Array[Node] = []
var tween: Tween

func _set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	card_render.card = card

func _set_stats(value: Stats) -> void:
	stats = value
	if stats and not stats.stats_changed.is_connected(_on_stats_changed):
		stats.stats_changed.connect(_on_stats_changed)

func play() -> void:
	if not card: return
	card.play(self, targets, stats, modifiers)
	played.emit(self)
	queue_free()

func pitch() -> void:
	if not card: return
	card.pitch_card(stats)
	pitched.emit(self)
	queue_free()

func sink() -> void:
	if not card: return
	card.sink_card(stats)
	sunk.emit(self)
	queue_free()

func block() -> void:
	if not card: return
	card.block_card(targets, modifiers)
	blocked.emit(self)
	queue_free()

func discard() -> void:
	if not card: return
	card.discard_card()
	discarded.emit(self)
	queue_free()

func _on_stats_changed() -> void:
	pass  # PlayerCardUI overrides this

# Shared tween helpers (both player and enemy cards can use these)
func animate_to_position(new_position: Vector2, duration: float) -> void:
	_kill_tween()
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)

func _kill_tween() -> void:
	if tween and tween.is_running():
		tween.kill()
