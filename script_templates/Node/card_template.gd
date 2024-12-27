# meta-name: Card logic
# meta-description: What happens when a card is played.
extends Card

@export var optional_sound: AudioStream

func apply_effects(targets: Array[Node]) -> void:
	print_debug("card played targets: %s" % targets)
