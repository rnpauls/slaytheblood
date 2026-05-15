## Autoload. Holds all KeywordEntry definitions and provides:
##   - to_tooltip_data(id, value=""): build the tooltip payload for a keyword
##   - parse_keywords(text): list keyword IDs referenced in some text
##   - format_keywords(text): replace [kw=id[:value]]Display[/kw] markup with bold text
##
## Tag syntax:
##   [kw=id]Display[/kw]         — plain reference
##   [kw=id:value]Display[/kw]   — reference with a magnitude/parameter that
##                                 is substituted into {x} in the keyword's
##                                 description (e.g. [kw=empower:3]Empower 3[/kw]
##                                 with description "Next attack gets +{x}atk").
##
## To add a keyword:
##   1) Create a .tres for KeywordEntry under res://keywords/ (id, display_name,
##      icon, description). Use {x} in the description where the magnitude goes.
##   2) Add it to the KEYWORDS dict below.
##
## A static dict is used (rather than a directory scan) to keep load order
## explicit and avoid surprise behavior from filesystem changes.
extends Node

## id (StringName) -> KeywordEntry (preloaded .tres). Populate as you go.
const KEYWORDS: Dictionary = {
	&"muscle": preload("uid://dwwwgbh3j5nri"),
	&"empower" : preload("uid://d11r1vtrliyc3"),
	&"intim" : preload("uid://c2nsq18tn8muy"),
	&"exposed": preload("uid://d0vg1g7lipvjd"),
	&"brittle" : preload("uid://cfqb7i380owtc"),
	&"enraged" : preload("uid://qe37tcwulr8q"),
	&"flow" : preload("uid://woqcqv0i0feo"),
	&"sink" : preload("uid://d30viny6t8iuu"),
	&"rampage" : preload("uid://gfx457xrk4at"),
	&"trash" : preload("uid://btrshkw9xm1c2"),
	&"zap" : preload("uid://czapkw1runeb4"),
	&"runechant" : preload("res://keywords/runechant_kw.tres"),
	&"fleeting" : preload("res://keywords/fleeting_kw.tres"),
	&"reserve" : preload("res://keywords/reserve_kw.tres"),
	&"inert" : preload("res://keywords/inert_kw.tres"),
	&"bleed" : preload("res://keywords/bleed_kw.tres"),
	&"channel" : preload("res://keywords/channel_kw.tres"),
	&"onhit" : preload("res://keywords/onhit_kw.tres"),
	&"poison_tip" : preload("uid://dgkvv0r17bhsv"),
	&"marked" : preload("uid://bxomn825uv5pg"),
	&"ap" : preload("uid://mtgwledarle4"),
	&"ga" : preload("uid://cowouit654fn3"),
	&"exhaust" : preload("uid://g7x2hp5n1m73"),
	&"block" : preload("uid://cybni5xs23bgd"),
	&"crippled" : preload("res://keywords/crippled_kw.tres"),
	&"unblockable" : preload("res://keywords/unblockable_kw.tres"),
	&"bloodied" : preload("res://keywords/bloodied_kw.tres"),
	&"aura" : preload("res://keywords/aura_kw.tres"),
	&"vulnerable" : preload("uid://7gk67jrtikrd"),
}

const _KW_TAG_REGEX := r"\[kw=([\w-]+)(?::([^\]]+))?\](.*?)\[/kw\]"
const _KW_OPEN_REGEX := r"\[kw=([\w-]+)(?::([^\]]+))?\]"

var _kw_tag: RegEx
var _kw_open: RegEx


func _ready() -> void:
	_kw_tag = RegEx.create_from_string(_KW_TAG_REGEX)
	_kw_open = RegEx.create_from_string(_KW_OPEN_REGEX)


func has_keyword(id: StringName) -> bool:
	return KEYWORDS.has(id)


func get_entry(id: StringName) -> KeywordEntry:
	return KEYWORDS.get(id, null)


func to_tooltip_data(id: StringName, value: String = "") -> TooltipData:
	var entry: KeywordEntry = KEYWORDS.get(id, null)
	if entry == null:
		return null
	return entry.to_tooltip_data(value)


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


## Like parse_keywords, but preserves the optional `:value` magnitude per
## occurrence (NOT deduped). Each entry is {"id": StringName, "value": String}.
## Used by build_tooltip_chain to thread magnitudes into TooltipData.
func _parse_keyword_uses(text: String) -> Array[Dictionary]:
	var uses: Array[Dictionary] = []
	if text.is_empty() or _kw_open == null:
		return uses
	for m in _kw_open.search_all(text):
		var id := StringName(m.get_string(1))
		if not KEYWORDS.has(id):
			continue
		uses.append({"id": id, "value": m.get_string(2)})
	return uses


## Replace [kw=id[:value]]Display[/kw] with bold-styled Display so the rendered
## text reads naturally without exposing the id or value. Run BEFORE
## IconRegistry.expand_icons.
func format_keywords(text: String) -> String:
	if text.is_empty() or _kw_tag == null:
		return text
	return _kw_tag.sub(text, "[b]$3[/b]", true)


## Modifier-aware variant of format_keywords: for keywords whose magnitude
## represents a value the player actually deals (currently just `zap`, which
## is folded into the attack damage packet via DMG_DEALT), wrap the rendered
## display in a gold/red color span when the player's modifiers would shift it.
## Falls back to format_keywords when no handler is supplied.
func format_keywords_with_modifiers(text: String, handler: ModifierHandler) -> String:
	if text.is_empty() or _kw_tag == null:
		return text
	if handler == null:
		return format_keywords(text)

	var result := ""
	var cursor := 0
	for m in _kw_tag.search_all(text):
		result += text.substr(cursor, m.get_start() - cursor)
		var id := StringName(m.get_string(1))
		var value_str := m.get_string(2)
		var display := m.get_string(3)
		var replacement := "[b]%s[/b]" % display
		if id == &"zap" and value_str != "":
			var base := value_str.to_int()
			var modified := handler.get_modified_value(base, Modifier.Type.DMG_DEALT)
			if modified > base:
				replacement = "[b][color=#%s]%s[/color][/b]" % [Palette.GOLD_HIGHLIGHT.to_html(false), display]
			elif modified < base:
				replacement = "[b][color=#%s]%s[/color][/b]" % [Palette.BLOOD_CRIMSON.to_html(false), display]
		result += replacement
		cursor = m.get_end()
	result += text.substr(cursor)
	return result


## Walk the keyword graph starting from `text`, returning one TooltipData per
## unique keyword reachable transitively (e.g. card mentions Strong, Strong's
## description mentions Strength → both boxes appear). BFS so closer references
## come first; max_depth bounds runaway content (cycles are also broken by the
## visited set). The first occurrence of a keyword in `text` provides the
## :value magnitude; nested references inside descriptions don't carry one.
func build_tooltip_chain(text: String, max_depth: int = 5) -> Array[TooltipData]:
	var results: Array[TooltipData] = []
	var visited: Dictionary = {}
	var queue: Array[Dictionary] = _parse_keyword_uses(text)
	var depth := 0

	while not queue.is_empty() and depth < max_depth:
		var next_queue: Array[Dictionary] = []
		for use: Dictionary in queue:
			var id: StringName = use["id"]
			if visited.has(id):
				continue
			visited[id] = true
			var entry: KeywordEntry = get_entry(id)
			if entry == null:
				continue
			results.append(entry.to_tooltip_data(use["value"]))
			for sub_id: StringName in parse_keywords(entry.description):
				if not visited.has(sub_id):
					next_queue.append({"id": sub_id, "value": ""})
		queue = next_queue
		depth += 1

	return results
