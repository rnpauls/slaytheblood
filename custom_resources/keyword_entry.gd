## A reusable game term (e.g. "Strength", "Vulnerable", "Innate") that can be
## referenced from card / status text via [kw=id]Display[/kw] BBCode (or
## [kw=id:value]Display[/kw] for keywords with a magnitude).
## Resolved by the KeywordRegistry autoload into a TooltipData at hover time.
class_name KeywordEntry
extends Resource

## Lowercase identifier used in [kw=...] tags. Match StringName conventions.
@export var id: StringName

## What appears in body text where this keyword is referenced.
@export var display_name: String

## Icon shown in the keyword's tooltip box.
@export var icon: Texture

## Description shown in the keyword's tooltip box. May contain {x} as a
## placeholder for the per-use magnitude (passed in via [kw=id:value]…[/kw]).
## May also contain [kw=...] / [icon=...] tags (formatted, but NOT recursively
## resolved into additional tooltip boxes — single-level resolution only).
@export_multiline var description: String


func to_tooltip_data(value: String = "") -> TooltipData:
	var body: String = description if value.is_empty() else description.replace("{x}", value)
	return TooltipData.make(icon, display_name, body)
