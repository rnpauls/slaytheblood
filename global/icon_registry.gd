## Autoload. Resolves [icon=id] BBCode shortcuts into [img] tags so card and
## tooltip text can reference reusable resource icons by name instead of raw
## paths. To add an icon, add an entry to ICONS below.
##
## Example author flow in card text:
##   "Deals [icon=atk] 6 damage. Costs [icon=mana] 1."
## Becomes (with default line_height=14):
##   "Deals [img height=14]res://art/atk.png[/img] 6 damage. Costs [img height=14]res://art/mana.png[/img] 1."
extends Node

## id (StringName) -> resource path (String). Paths must be valid res:// URIs.
const ICONS: Dictionary = {
	 &"atk": "res://art/atk_icon.png",
	# &"def": "res://art/shield_icon.png",
	# &"mana": "res://art/mana_icon.png",
}

const _ICON_REGEX := r"\[icon=([\w-]+)\]"

var _icon_re: RegEx


func _ready() -> void:
	_icon_re = RegEx.create_from_string(_ICON_REGEX)


func get_icon_path(id: StringName) -> String:
	return ICONS.get(id, "")


## Replace [icon=id] with [img height=line_height]res://path[/img]. Unknown ids
## are left as-is so missing icons surface visibly during authoring.
func expand_icons(text: String, line_height: int = 14) -> String:
	if text.is_empty() or _icon_re == null:
		return text
	var result := text
	for m in _icon_re.search_all(text):
		var id := StringName(m.get_string(1))
		var path: String = ICONS.get(id, "")
		if path.is_empty():
			continue
		var replacement := "[img height=%d]%s[/img]" % [line_height, path]
		result = result.replace(m.get_string(0), replacement)
	return result
