extends Card

func apply_effects(_targets: Array[Node]) -> void:
	var success := await sixloot(owner, 2)
	if success:
		go_again = true
		var bloodrush_status := preload("res://statuses/bloodrushed.tres").duplicate()
		owner.status_handler.add_status(bloodrush_status)
