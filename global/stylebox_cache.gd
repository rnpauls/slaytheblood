## Autoload. Caches per-rarity card border StyleBoxes so we don't duplicate a
## new StyleBoxFlat for every card_visuals.set_card() call (the previous "shitty
## panel mod" pattern).
##
## Usage:
##   art_panel.add_theme_stylebox_override(
##       "panel", StyleBoxCache.get_rarity_border(art_panel, card.rarity))
##
## The first call seeds the cache with a duplicate of the source panel's own
## "panel" stylebox, then mutates border_color per rarity. Subsequent calls
## return the cached instance.
extends Node

var _rarity_cache: Dictionary = {}   # Card.Rarity (int) -> StyleBoxFlat

func get_rarity_border(source_panel: Control, rarity: int) -> StyleBoxFlat:
	if not _rarity_cache.has(rarity):
		var base_sb := source_panel.get_theme_stylebox("panel") as StyleBoxFlat
		var sb := base_sb.duplicate() as StyleBoxFlat
		sb.border_color = Constants.RARITY_COLORS[rarity]
		_rarity_cache[rarity] = sb
	return _rarity_cache[rarity]
