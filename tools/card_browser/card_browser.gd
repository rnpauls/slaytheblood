extends Control

const CARD_MENU_UI := preload("uid://b2ay04rjh0l4v")

const SCAN_ROOTS := [
	"res://characters/brute",
	"res://characters/ninja",
	"res://characters/runeblade",
	"res://generic_cards",
	"res://enemies"
]

const CHARACTER_KEYS: Array[String] = ["ALL", "BRUTE", "NINJA", "RUNEBLADE", "GENERIC"]
const CHARACTER_LABELS: Array[String] = ["All", "Brute", "Ninja", "Runeblade", "Generic"]

var all_cards: Array[Card] = []
var card_character: Dictionary = {}
var all_piles: Array[CardPile] = []
var selected_pile: CardPile = null
var original_pile_cards: Array[Card] = []
var pile_dirty: bool = false

var _last_confirmed_pile_index: int = -1
var _pending_pile_index: int = -1

@onready var pile_picker: OptionButton = $MarginContainer/VBoxContainer/HeaderBar/PilePicker
@onready var dirty_indicator: Label = $MarginContainer/VBoxContainer/HeaderBar/DirtyIndicator
@onready var revert_button: Button = $MarginContainer/VBoxContainer/HeaderBar/RevertButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/HeaderBar/SaveButton

@onready var pile_cards_grid: GridContainer = $MarginContainer/VBoxContainer/HSplitContainer/LeftPane/PileCardsScroll/PileCardsGrid
@onready var pile_stats_panel = $MarginContainer/VBoxContainer/HSplitContainer/LeftPane/PileStatsPanel

@onready var character_filter: OptionButton = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row1/CharacterFilter
@onready var type_filter: OptionButton = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row1/TypeFilter
@onready var rarity_filter: OptionButton = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row1/RarityFilter
@onready var cost_min: SpinBox = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row2/CostMin
@onready var cost_max: SpinBox = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row2/CostMax
@onready var search_box: LineEdit = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/FiltersBar/Row2/SearchBox

@onready var library_header: Label = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/LibraryHeader
@onready var library_grid: GridContainer = $MarginContainer/VBoxContainer/HSplitContainer/RightPane/LibraryScroll/LibraryGrid


func _ready() -> void:
	_populate_filter_dropdowns()
	_discover_resources()
	_populate_pile_picker()

	pile_picker.item_selected.connect(_on_pile_picked)
	revert_button.pressed.connect(_on_revert_pressed)
	save_button.pressed.connect(_on_save_pressed)
	character_filter.item_selected.connect(_on_filter_changed)
	type_filter.item_selected.connect(_on_filter_changed)
	rarity_filter.item_selected.connect(_on_filter_changed)
	cost_min.value_changed.connect(_on_filter_changed)
	cost_max.value_changed.connect(_on_filter_changed)
	search_box.text_changed.connect(_on_filter_changed)

	if not all_piles.is_empty():
		pile_picker.select(0)
		_last_confirmed_pile_index = 0
		_load_pile(all_piles[0])

	_render_library()


func _populate_filter_dropdowns() -> void:
	character_filter.clear()
	for label in CHARACTER_LABELS:
		character_filter.add_item(label)

	type_filter.clear()
	type_filter.add_item("All Types")
	for key in Card.Type.keys():
		type_filter.add_item(key.capitalize())

	rarity_filter.clear()
	rarity_filter.add_item("All Rarity")
	for key in Card.Rarity.keys():
		rarity_filter.add_item(key.capitalize())


func _discover_resources() -> void:
	all_cards.clear()
	card_character.clear()
	all_piles.clear()

	for root in SCAN_ROOTS:
		_scan_dir(root)

	all_cards.sort_custom(func(a, b): return a.id < b.id)
	all_piles.sort_custom(func(a, b): return a.resource_path < b.resource_path)


func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full := path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir(full)
		elif entry.ends_with(".tres"):
			var res := ResourceLoader.load(full)
			if res is CardPile:
				all_piles.append(res)
			elif res is Card:
				all_cards.append(res)
				card_character[res] = _character_for_path(full)
		entry = dir.get_next()
	dir.list_dir_end()


func _character_for_path(path: String) -> String:
	if path.contains("/characters/brute/"):
		return "BRUTE"
	if path.contains("/characters/ninja/"):
		return "NINJA"
	if path.contains("/characters/runeblade/"):
		return "RUNEBLADE"
	return "GENERIC"


func _populate_pile_picker() -> void:
	pile_picker.clear()
	for pile in all_piles:
		pile_picker.add_item(_humanize_pile_name(pile.resource_path))


func _humanize_pile_name(path: String) -> String:
	return path.get_file().get_basename().capitalize()


func _on_pile_picked(index: int) -> void:
	if index == _last_confirmed_pile_index:
		return
	if not pile_dirty:
		_last_confirmed_pile_index = index
		_load_pile(all_piles[index])
		return

	_pending_pile_index = index
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Discard unsaved changes to '%s'?" % _humanize_pile_name(selected_pile.resource_path)
	dlg.title = "Unsaved changes"
	dlg.confirmed.connect(_on_discard_confirmed)
	dlg.canceled.connect(_on_discard_canceled)
	dlg.close_requested.connect(_on_discard_canceled)
	add_child(dlg)
	dlg.popup_centered()


func _on_discard_confirmed() -> void:
	_last_confirmed_pile_index = _pending_pile_index
	_load_pile(all_piles[_pending_pile_index])


func _on_discard_canceled() -> void:
	pile_picker.select(_last_confirmed_pile_index)


func _load_pile(pile: CardPile) -> void:
	selected_pile = pile
	original_pile_cards = pile.cards.duplicate()
	_set_dirty(false)
	_render_pile()
	pile_stats_panel.update_for_pile(pile)


func _render_pile() -> void:
	for child in pile_cards_grid.get_children():
		child.queue_free()
	if selected_pile == null:
		return
	for i in selected_pile.cards.size():
		var card := selected_pile.cards[i]
		var card_ui := CARD_MENU_UI.instantiate()
		pile_cards_grid.add_child(card_ui)
		card_ui.card = card
		card_ui.tooltip_requested.connect(_on_pile_card_clicked.bind(i))


func _render_library() -> void:
	for child in library_grid.get_children():
		child.queue_free()
	var shown := 0
	for card in all_cards:
		if not _passes_filters(card):
			continue
		var card_ui := CARD_MENU_UI.instantiate()
		library_grid.add_child(card_ui)
		card_ui.card = card
		card_ui.tooltip_requested.connect(_on_library_card_clicked)
		shown += 1
	library_header.text = "Library (%d / %d)" % [shown, all_cards.size()]


func _passes_filters(card: Card) -> bool:
	var char_idx := character_filter.selected
	if char_idx > 0:
		var wanted := CHARACTER_KEYS[char_idx]
		if card_character.get(card, "") != wanted:
			return false

	var type_idx := type_filter.selected
	if type_idx > 0 and card.type != type_idx - 1:
		return false

	var rarity_idx := rarity_filter.selected
	if rarity_idx > 0 and card.rarity != rarity_idx - 1:
		return false

	if card.cost < int(cost_min.value) or card.cost > int(cost_max.value):
		return false

	var query := search_box.text.strip_edges().to_lower()
	if not query.is_empty():
		if not card.id.to_lower().contains(query) and not card.tooltip_text.to_lower().contains(query):
			return false

	return true


func _on_filter_changed(_arg = null) -> void:
	_render_library()


func _on_library_card_clicked(card: Card) -> void:
	if selected_pile == null:
		return
	selected_pile.cards.append(card)
	_set_dirty(true)
	_render_pile()
	pile_stats_panel.update_for_pile(selected_pile)


func _on_pile_card_clicked(_clicked: Card, index: int) -> void:
	if selected_pile == null or index >= selected_pile.cards.size():
		return
	selected_pile.cards.remove_at(index)
	_set_dirty(true)
	_render_pile()
	pile_stats_panel.update_for_pile(selected_pile)


func _set_dirty(value: bool) -> void:
	pile_dirty = value
	dirty_indicator.visible = value
	save_button.disabled = not value
	revert_button.disabled = not value


func _on_save_pressed() -> void:
	if selected_pile == null:
		return
	var err := ResourceSaver.save(selected_pile, selected_pile.resource_path)
	if err == OK:
		original_pile_cards = selected_pile.cards.duplicate()
		_set_dirty(false)
		print_rich("[color=green]Saved %s[/color]" % selected_pile.resource_path)
	else:
		var dlg := AcceptDialog.new()
		dlg.dialog_text = "Save failed: error code %d" % err
		dlg.title = "Save failed"
		add_child(dlg)
		dlg.popup_centered()


func _on_revert_pressed() -> void:
	if selected_pile == null:
		return
	selected_pile.cards = original_pile_cards.duplicate()
	_set_dirty(false)
	_render_pile()
	pile_stats_panel.update_for_pile(selected_pile)
