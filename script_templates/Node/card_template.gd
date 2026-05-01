# meta-name: Card logic
# meta-description: What happens when a card is played.
extends Card

@export var optional_sound: AudioStream

func get_default_tooltip() -> String:
	return tooltip_text

func get_updated_tooltip(_dealer: Node, _target: Node) -> String:
	return tooltip_text

func apply_effects(targets: Array[Node]) -> void:
	print_debug("card played targets: %s" % targets)
