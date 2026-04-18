extends TextureRect

@export var hover_scale := 1.65
#@export var hover_y_lift := -90.0   # pixels upward
@export var tween_duration := 0.18

@onready var hover_overlay: CanvasLayer = get_node("/root/Run/HoverOverlay")  # ← full-screen Control above everything

var original_parent: Node
var original_index: int = -1
var original_global_pos: Vector2
var is_hovered := false
#var just_hovered:= false #When reparenting, it will always register mouse leaving
var current_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP   # Important so signals fire
	pivot_offset = size / 2                    # Scale from center (looks much better)


func _on_mouse_entered() -> void:
	if is_hovered: return
	
	# 1. Capture current global position BEFORE reparenting
	original_global_pos = global_position
	
	# 2. Remember where it was in the hand
	original_parent = get_parent()
	original_index = get_index()
	
	# 3. Reparent to overlay
	self.reparent(hover_overlay)
	
	#Set is_hovered after reparent
	is_hovered = true

	# 4. Immediately put it back at the exact same screen position
	global_position = original_global_pos
	
	# 5. Start the nice tween
	if current_tween and current_tween.is_running():
		current_tween.kill()
	
	current_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale), tween_duration)
	#current_tween.parallel().tween_property(self, "global_position:y", original_global_pos.y + hover_y_lift, tween_duration)
	
	z_index = 20   # Bring way to front


func _on_mouse_exited() -> void:
	#if just_hovered:
		#return
	if not is_hovered: return
	
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
	
	current_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_tween.tween_property(self, "scale", Vector2(1, 1), tween_duration)
	#current_tween.parallel().tween_property(self, "global_position:y", original_global_pos.y, tween_duration)
	
	current_tween.tween_callback(_return_to_original_parent)
	is_hovered = false


func _return_to_original_parent() -> void:
	if not is_inside_tree(): return
	
	global_position = original_global_pos  # Final safety
	
	get_parent().remove_child(self)
	original_parent.add_child(self)
	original_parent.move_child(self, original_index)
	
	z_index = 0
	scale = Vector2.ONE*0.6
