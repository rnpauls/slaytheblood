## Autoload. Holds all KeywordEntry definitions and provides:
##   - to_tooltip_data(id): build the tooltip payload for a keyword
##   - parse_keywords(text): list keyword IDs referenced in some text
##   - format_keywords(text): replace [kw=id]Display[/kw] markup with bold text
##
## To add a keyword:
##   1) Create a .tres for KeywordEntry under res://keywords/ (id, display_name,
##      icon, description).
##   2) Add it to the KEYWORDS dict below.
##
## A static dict is used (rather than a directory scan) to keep load order
## explicit and avoid surprise behavior from filesystem changes.
extends Node

## id (StringName) -> KeywordEntry (preloaded .tres). Populate as you go.
const KEYWORDS: Dictionary = {
	# &"strength": preload("res://keywords/strength.tres"),
	&"empower" : preload("uid://d11r1vtrliyc3"),
	&"intim" : preload("uid://c2nsq18tn8muy"),
	# &"vulnerable": preload("res://keywords/vulnerable.tres"),
	&"brittle" : preload("uid://cfqb7i380owtc"),
	&"enraged" : preload("uid://qe37tcwulr8q"),
	&"flow" : preload("uid://woqcqv0i0feo"),
	&"sink" : preload("uid://d30viny6t8iuu"),
}

const _KW_TAG_REGEX := r"\[kw=([\w-]+)\](.*?)\[/kw\]"
const _KW_OPEN_REGEX := r"\[kw=([\w-]+)\]"

var _kw_tag: RegEx
var _kw_open: RegEx


func _ready() -> void:
	_kw_tag = RegEx.create_from_string(_KW_TAG_REGEX)
	_kw_open = RegEx.create_from_string(_KW_OPEN_REGEX)


func has_keyword(id: StringName) -> bool:
	return KEYWORDS.has(id)


func get_entry(id: StringName) -> KeywordEntry:
	return KEYWORDS.get(id, null)


func to_tooltip_data(id: StringName) -> TooltipData:
	var entry: KeywordEntry = KEYWORDS.get(id, null)
	if entry == null:
		return null
	return entry.to_tooltip_data()


## Walk `text` for [kw=id]...[/kw] tags and return the unique keyword ids found,
## in order of first appearance. Unknown ids are silently skipped so it's safe
## to author text before all keywords are registered.
func parse_keywords(text: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	if text.is_empty() or _kw_open == null:
		return ids
	for m in _kw_open.search_all(text):
		var id := StringName(m.get_string(1))
		if not ids.has(id) and KEYWORDS.has(id):
			ids.append(id)
	return ids


## Replace [kw=id]Display[/kw] with bold-styled Display so the rendered text
## reads naturally without exposing the id. Run BEFORE IconRegistry.expand_icons.
func format_keywords(text: String) -> String:
	if text.is_empty() or _kw_tag == null:
		return text
	return _kw_tag.sub(text, "[b]$2[/b]", true)


## Walk the keyword graph starting from `text`, returning one TooltipData per
## unique keyword reachable transitively (e.g. card mentions Strong, Strong's
## description mentions Strength → both boxes appear). BFS so closer references
## come first; max_depth bounds runaway content (cycles are also broken by the
## visited set).
func build_tooltip_chain(text: String, max_depth: int = 5) -> Array[TooltipData]:
	var results: Array[TooltipData] = []
	var visited: Dictionary = {}
	var queue: Array[StringName] = parse_keywords(text)
	var depth := 0

	while not queue.is_empty() and depth < max_depth:
		var next_queue: Array[StringName] = []
		for id: StringName in queue:
			if visited.has(id):
				continue
			visited[id] = true
			var entry: KeywordEntry = get_entry(id)
			if entry == null:
				continue
			results.append(entry.to_tooltip_data())
			for sub_id: StringName in parse_keywords(entry.description):
				if not visited.has(sub_id):
					next_queue.append(sub_id)
		queue = next_queue
		depth += 1

	return results
