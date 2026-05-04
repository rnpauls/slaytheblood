## Plain payload for one tooltip box. Multiple of these are passed to the
## TooltipLayer to produce a stack (e.g. main card description + one box per
## keyword referenced in that description).
class_name TooltipData
extends Resource

@export var icon: Texture
@export var title: String = ""
@export_multiline var body: String = ""


static func make(p_icon: Texture, p_title: String, p_body: String) -> TooltipData:
	var data := TooltipData.new()
	data.icon = p_icon
	data.title = p_title
	data.body = p_body
	return data
