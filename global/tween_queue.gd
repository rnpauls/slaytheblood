## Runs `per_item` over each item in `items` with `interval` seconds between
## each, then calls `on_finished`. If `items` is empty, calls `on_finished`
## immediately. Used by RelicHandler/StatusHandler to animate batched triggers
## with consistent pacing.
class_name TweenQueue
extends RefCounted


static func run(host: Node, items: Array, interval: float, per_item: Callable, on_finished: Callable) -> void:
	if items.is_empty():
		on_finished.call()
		return
	var tween := host.create_tween()
	for item in items:
		tween.tween_callback(per_item.bind(item))
		tween.tween_interval(interval)
	tween.finished.connect(on_finished)
