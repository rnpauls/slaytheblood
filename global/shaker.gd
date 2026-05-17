extends Node

func shake(thing: Node2D, strength: float, duration: float = 0.2) -> void:
	if not thing:
		return

	var orig_pos := thing.position
	var shake_count := 10
	var tween := create_tween()

	for i in shake_count:
		var shake_offset := Vector2(randf_range(-1.0,1.0), randf_range(-1.0,1.0))
		var target := orig_pos + strength * shake_offset
		if i% 2 == 0:
			target = orig_pos
		tween.tween_property(thing, "position", target, duration / float(shake_count))
		strength *= 0.75

	tween.finished.connect(
		func():
			if thing:
				thing.position = orig_pos
	)


## Shake the active Camera2D via its `offset` so we don't fight any code
## that drives the camera's `position`. Resolves the camera each call via
## get_viewport().get_camera_2d() so we don't hold a stale ref across scene
## changes. No-ops cleanly when there's no active camera (menus, transitions).
func shake_camera(strength: float, duration: float = 0.2) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var cam := tree.root.get_camera_2d()
	if not cam:
		return
	var orig_offset := cam.offset
	var shake_count := 10
	var tween := create_tween()
	for i in shake_count:
		var shake_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var target := orig_offset + strength * shake_offset
		if i % 2 == 0:
			target = orig_offset
		tween.tween_property(cam, "offset", target, duration / float(shake_count))
		strength *= 0.75
	tween.finished.connect(
		func():
			if is_instance_valid(cam):
				cam.offset = orig_offset
	)
