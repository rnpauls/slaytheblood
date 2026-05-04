## A single tooltip card. Stateless — given a TooltipData, just renders it.
## Multiple TooltipBoxes are stacked by TooltipLayer to form a Slay-the-Spire-
## style column of explanations (main card + one box per keyword).
class_name TooltipBox
extends PanelContainer

@onready var header: HBoxContainer = %Header
@onready var tooltip_icon: TextureRect = %TooltipIcon
@onready var tooltip_title: RichTextLabel = %TooltipTitle
@onready var tooltip_body: RichTextLabel = %TooltipBody


func _ready() -> void:
	# Tooltips are visual only — never block the cursor on the source they describe.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_data(data: TooltipData) -> void:
	if data == null:
		return
	if not is_node_ready():
		await ready

	var has_icon := data.icon != null
	var has_title := not data.title.is_empty()
	header.visible = has_icon or has_title
	tooltip_icon.visible = has_icon
	tooltip_title.visible = has_title

	if has_icon:
		tooltip_icon.texture = data.icon
	if has_title:
		tooltip_title.text = "[b]%s[/b]" % data.title

	# Format BBCode shortcuts before rendering. Keyword tags become bold; icon
	# shortcuts expand into [img] tags.
	var body_text := data.body
	body_text = KeywordRegistry.format_keywords(body_text)
	body_text = IconRegistry.expand_icons(body_text)
	tooltip_body.text = body_text
