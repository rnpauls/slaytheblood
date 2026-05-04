## A reusable game term (e.g. "Strength", "Vulnerable", "Innate") that can be
## referenced from card / status text via [kw=id]Display[/kw] BBCode.
## Resolved by the KeywordRegistry autoload into a TooltipData at hover time.
class_name KeywordEntry
extends Resource

## Lowercase identifier used in [kw=...] tags. Match StringName conventions.
@export var id: StringName

## What appears in body text where this keyword is referenced.
@export var display_name: String

## Icon shown in the keyword's tooltip box.
@export var icon: Texture

## Description shown in the keyword's tooltip box. May itself contain
## [kw=...] / [icon=...] tags (formatted, but NOT recursively resolved into
## additional tooltip boxes — single-level resolution only).
@export_multiline var description: String


func to_tooltip_data() -> TooltipData:
	return TooltipData.make(icon, display_name, description)
