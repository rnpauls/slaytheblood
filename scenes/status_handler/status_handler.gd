class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)
## Fires when a status is added or about to be removed. Listeners that depend
## on `has_status(...)` should reconnect/refresh on this signal. The remove
## case is deferred so listeners see the updated child list.
signal statuses_changed

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")

@export var status_owner: Node2D

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

## Build a TooltipData entry per active status. Public so character sprites
## (Enemy / Player) can call this from their own hover handlers too — the
## status grid is positioned outside the sprite hover area, so both can fire
## without the nested mouse-exit conflict that would otherwise break things.
func get_tooltip_entries() -> Array[TooltipData]:
	var entries: Array[TooltipData] = []
	for status: Status in _get_all_statuses():
		entries.append(TooltipData.make(status.icon, status.id.capitalize(), status.get_tooltip()))
	return entries

func apply_statuses_by_type(type: Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return
	var queue: Array[Status] = _get_all_statuses().filter(
		func(s: Status): return s.type == type
	)
	TweenQueue.run(self, queue, STATUS_APPLY_INTERVAL,
		func(s: Status): s.apply_status(status_owner),
		func(): statuses_applied.emit(type))

func add_status(status: Status) -> void:
	var stackable := status.stack_type != Status.StackType.NONE
	
	if not _has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.set_status(status)
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)
		new_status_ui.tree_exiting.connect(_on_status_ui_tree_exiting)
		statuses_changed.emit()
		return
	
	if not status.can_expire and not stackable:
		return
	
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		_get_status(status.id).duration += status.duration
		return
		
	if status.stack_type == Status.StackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks
		_get_status(status.id).duration = status.duration
		_get_status(status.id).update()
		return

func _has_status(id: String) -> bool:
	return has_status(id)


## Public lookup for callers outside StatusHandler (weapons, relics, etc.).
## Mirrors get_status_by_id's public/_private pairing.
func has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true

	return false

func _get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status

	return null

## Public lookup so other systems (e.g. Card.do_runechant_trigger) can find a
## status without reaching into the underscore-private internals.
func get_status_by_id(id: String) -> Status:
	return _get_status(id)

func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
	
	return statuses

func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1

## Deferred so listeners see the status_ui already removed from the tree
## before they re-query `has_status`.
func _on_status_ui_tree_exiting() -> void:
	statuses_changed.emit.call_deferred()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.status_tooltip_requested.emit(_get_all_statuses())

func _on_mouse_entered() -> void:
	var entries := get_tooltip_entries()
	if entries.is_empty():
		return
	Events.tooltip_show_requested.emit(entries, Rect2(global_position, size))

func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()
