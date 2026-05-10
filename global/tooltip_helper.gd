## Wires a Control's hover signals to the global tooltip system. The first
## TooltipData box is built from the title/body/icon you pass; if `body`
## references any [kw=...] keywords, those expand into trailing boxes via
## KeywordRegistry.build_tooltip_chain.
class_name TooltipHelper
extends RefCounted


static func attach(control: Control, title: String, body: String, icon: Texture = null) -> void:
	control.mouse_entered.connect(func() -> void: _show(control, title, body, icon))
	control.mouse_exited.connect(_hide)


static func _show(control: Control, title: String, body: String, icon: Texture) -> void:
	var entries: Array[TooltipData] = [TooltipData.make(icon, title, body)]
	entries.append_array(KeywordRegistry.build_tooltip_chain(body))
	Events.tooltip_show_requested.emit(entries, Rect2(control.global_position, control.size))


static func _hide() -> void:
	Events.tooltip_hide_requested.emit()
